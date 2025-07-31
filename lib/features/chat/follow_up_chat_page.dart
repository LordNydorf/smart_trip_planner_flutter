import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../models/itinerary_model.dart';
import '../itinerary/itinerary_controller.dart';
import '../auth/auth_controller.dart';
import '../../theme/app_theme.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class FollowUpChatPage extends ConsumerStatefulWidget {
  final String originalPrompt;
  final Itinerary? currentItinerary;

  const FollowUpChatPage({
    super.key,
    required this.originalPrompt,
    this.currentItinerary,
  });

  @override
  ConsumerState<FollowUpChatPage> createState() => _FollowUpChatPageState();
}

class _FollowUpChatPageState extends ConsumerState<FollowUpChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String _currentStreamContent = '';

  // Get the first initial of the user's name for the avatar
  String _getUserInitial() {
    // Get the current authenticated user
    final user = ref.watch(authControllerProvider);

    // If user is null or has no displayName/email, return a fallback
    if (user == null) {
      return "?";
    }

    // Try to get initial from display name
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName![0].toUpperCase();
    }

    // Fallback to email if available
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }

    // Ultimate fallback
    return "?";
  }

  @override
  void initState() {
    super.initState();
    // Add the original prompt as the first message
    _messages.add(
      ChatMessage(
        content: widget.originalPrompt,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    // Add an initial bot response as the second message
    if (widget.currentItinerary != null) {
      // Create a formatted itinerary response
      String formattedItinerary = _formatItineraryForChat(
        widget.currentItinerary!,
      );

      _messages.add(
        ChatMessage(
          content: formattedItinerary,
          isUser: false,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
    } else {
      _messages.add(
        ChatMessage(
          content:
              'I\'ve created an itinerary based on your request. Feel free to ask me to refine it further!',
          isUser: false,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.currentItinerary?.title ?? _extractTripTitleFromPrompt(),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: -0.0005, // letter-spacing: -0.5%
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.accentTeal,
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : _getUserInitial(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length + (_isStreaming ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isStreaming) {
                  return _buildStreamingMessage();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content with avatar inside the white box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User/AI indicator inside the box
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? AppTheme.accentTeal
                            : const Color(0xFFFF9500),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: message.isUser
                            ? Text(
                                _getUserInitial(),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing:
                                      -0.0005, // letter-spacing: -0.5%
                                ),
                              )
                            : const Icon(
                                Icons.smart_toy,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      message.isUser ? 'You' : 'Itinera AI',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        height: 1.5, // line-height: 24px
                        letterSpacing: -0.0005, // letter-spacing: -0.5%
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message content
                if (!message.isUser && _isItineraryContent(message.content))
                  _buildItineraryContent(message.content)
                else
                  Text(
                    message.content,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5, // line-height: 24px (1.5 × 16px)
                      letterSpacing: -0.0005, // letter-spacing: -0.5%
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons - positioned outside the bubble
          const SizedBox(height: 8),
          message.isUser
              ? Row(
                  children: [
                    _buildActionButton(
                      Icons.copy,
                      'Copy',
                      () => _handleActionButton('Copy', message),
                    ),
                  ],
                )
              : _buildActionButtons(),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streaming content with avatar inside
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI indicator inside the box
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9500),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Itinera AI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        height: 1.5, // line-height: 24px
                        letterSpacing: -0.0005, // letter-spacing: -0.5%
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Streaming content
                if (_currentStreamContent.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentStreamContent,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5, // line-height: 24px (1.5 × 16px)
                          letterSpacing: -0.0005, // letter-spacing: -0.5%
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Creating your response...',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5, // line-height: 24px
                          letterSpacing: -0.0005, // letter-spacing: -0.5%
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(
                left: 16,
                top: 16,
                bottom: 16,
                right: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF008B7A), width: 1.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Follow up to refine',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5, // line-height: 24px
                          letterSpacing: -0.0005, // letter-spacing: -0.5%
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        filled: false,
                      ),
                      maxLines: null,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5, // line-height: 24px
                        letterSpacing: -0.0005, // letter-spacing: -0.5%
                      ),
                      onSubmitted: _isStreaming ? null : (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // Voice input functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice input activated')),
                      );
                    },
                    icon: const Icon(
                      Icons.mic,
                      color: Color(0xFF008B7A),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: _isStreaming ? Colors.grey[300] : const Color(0xFF008B7A),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _isStreaming ? null : _sendMessage,
              icon: Icon(
                Icons.send,
                color: _isStreaming ? Colors.grey[500] : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(content: message, isUser: true, timestamp: DateTime.now()),
      );
      _isStreaming = true;
      _currentStreamContent = '';
    });

    _messageController.clear();
    _scrollToBottom();

    // Create a context-aware prompt for refinement
    final refinementPrompt =
        '''
Original request: "${widget.originalPrompt}"

${widget.currentItinerary != null ? 'Current itinerary: ${_serializeItinerary(widget.currentItinerary!)}' : ''}

User's refinement request: "$message"

IMPORTANT: Your response MUST be in natural readable English text format, NOT in JSON. 

Format the itinerary with:
- Clear day headings like "Day 1: Arrival in Bali"
- Use bullet points ONLY for activities, not for general text
- Include paragraph text for descriptions and summaries
- Include useful details like times, locations, and brief descriptions
- DO NOT mention specific dates unless the user has explicitly asked for them

DO NOT return JSON format under any circumstances.
''';

    _streamRefinement(refinementPrompt);
  }

  Future<void> _streamRefinement(String prompt) async {
    try {
      final llmService = ref.read(llmServiceProvider);
      String fullContent = '';
      bool possiblyJson = false;

      await for (final chunk in llmService.generateItineraryStream(prompt)) {
        if (chunk.startsWith('Error:')) {
          setState(() {
            _isStreaming = false;
            _messages.add(
              ChatMessage(
                content: 'Sorry, I encountered an error: $chunk',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
          });
          return;
        }

        // Check if content might be JSON
        if (chunk.contains('{') || chunk.contains('"')) {
          possiblyJson = true;
        }

        fullContent += chunk;

        // Format the content in real-time during streaming if it looks like JSON
        String displayContent = fullContent;
        if (possiblyJson &&
            fullContent.contains('{') &&
            fullContent.contains('"')) {
          try {
            // Try to clean up the content during streaming
            displayContent = _cleanupStreamingContent(fullContent);
          } catch (e) {
            // If cleaning fails, just use the original content
            displayContent = fullContent;
          }
        }

        setState(() {
          _currentStreamContent = displayContent;
        });
        _scrollToBottom();
      }

      // If the content looks like JSON, try to make it more readable
      if (possiblyJson &&
          fullContent.contains('{') &&
          (fullContent.contains('}') || fullContent.contains('":'))) {
        try {
          final formattedContent = _tryFormatJsonAsReadableItinerary(
            fullContent,
          );
          if (formattedContent != null) {
            fullContent = formattedContent;
          } else {
            // If full formatting failed, at least clean it up
            fullContent = _cleanupStreamingContent(fullContent);
          }
        } catch (e) {
          // If formatting fails, at least try basic cleanup
          fullContent = _cleanupStreamingContent(fullContent);
        }
      }

      setState(() {
        _isStreaming = false;
        _messages.add(
          ChatMessage(
            content: fullContent,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      // We'll still try to parse the itinerary in case we need it for other features
      // but we won't replace the message content
      final updatedItinerary = await llmService.parseItineraryFromJson(
        fullContent,
      );

      if (updatedItinerary != null) {
        // Update the itinerary in the controller
        // Note: You might want to add an update method to the controller
        // For now, we'll just show success message
      }
    } catch (e) {
      setState(() {
        _isStreaming = false;
        _messages.add(
          ChatMessage(
            content: 'Sorry, I encountered an error: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isItineraryContent(String content) {
    // Check if content looks like itinerary data
    return content.contains('Day ') ||
        content.contains('Morning:') ||
        content.contains('Evening:') ||
        content.contains('Afternoon:') ||
        content.contains('•') ||
        content.length > 100; // Longer responses are likely itineraries
  }

  Widget _buildItineraryContent(String content) {
    // Parse and display itinerary content nicely
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (String line in lines)
          if (line.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildItineraryLine(line.trim()),
            ),

        // Add "Open in maps" link and travel info
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            // Handle open in maps
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Opening in maps...')));
          },
          child: Row(
            children: [
              const Icon(Icons.place, color: Color(0xFF008B7A), size: 16),
              const SizedBox(width: 4),
              const Text(
                'Open in maps',
                style: TextStyle(
                  color: Color(0xFF008B7A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.currentItinerary != null
              ? _getTravelInfoText()
              : 'Travel information unavailable',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryLine(String line) {
    // Check if line contains bullet point already
    bool hasBullet =
        line.trimLeft().startsWith('•') ||
        line.trimLeft().startsWith('-') ||
        line.trimLeft().startsWith('*');

    // Check if this is a heading or important line
    bool isHeading = line.startsWith('Day ') || line.startsWith('#');
    bool isSubheading = line.contains(':') || (line.endsWith(':'));

    if (isHeading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
        child: Text(
          line.startsWith('#')
              ? line.replaceFirst(RegExp(r'^#+\s*'), '')
              : line,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: 1.5,
            letterSpacing: -0.0005, // letter-spacing: -0.5%
          ),
        ),
      );
    } else if (isSubheading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
        child: Text(
          line,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: 1.5,
            letterSpacing: -0.0005, // letter-spacing: -0.5%
          ),
        ),
      );
    } else if (hasBullet) {
      // Clean up the bullet point
      String cleanText = line.trimLeft();
      if (cleanText.startsWith('•') ||
          cleanText.startsWith('-') ||
          cleanText.startsWith('*')) {
        cleanText = cleanText.substring(1).trimLeft();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '• ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: -0.0005, // letter-spacing: -0.5%
              ),
            ),
            Expanded(
              child: Text(
                cleanText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.0005, // letter-spacing: -0.5%
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Regular text - don't add bullet points to regular text
      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(
          line,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: -0.0005, // letter-spacing: -0.5%
          ),
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          Icons.copy,
          'Copy',
          () => _handleActionButton('Copy'),
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          Icons.bookmark_border,
          'Save Offline',
          () => _handleActionButton('Save Offline'),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Function() onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.0005, // letter-spacing: -0.5%
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleActionButton(String action, [ChatMessage? message]) {
    // If no message was provided, use the last AI message
    final targetMessage =
        message ??
        _messages.lastWhere((msg) => !msg.isUser, orElse: () => _messages.last);

    switch (action) {
      case 'Copy':
        // Copy to clipboard functionality
        Clipboard.setData(ClipboardData(text: targetMessage.content)).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message copied to clipboard')),
            );
          }
        });
        break;
      case 'Save Offline':
        // Save offline functionality
        if (widget.currentItinerary != null) {
          _saveItinerary(widget.currentItinerary!);
        } else {
          // Try to parse itinerary from the message content
          _saveMessageContentOffline(targetMessage.content);
        }
        break;
      case 'Regenerate':
        // Regenerate functionality (button removed but keeping functionality)
        _regenerateResponse();
        break;
    }
  }

  void _saveMessageContentOffline(String content) {
    // Here you could implement functionality to save the message content as a note or draft
    // For now, we'll just show a confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message saved offline')));
  }

  Future<void> _saveItinerary(Itinerary itinerary) async {
    try {
      final box = Hive.box('savedTrips');
      await box.add(itinerary);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerary saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  void _regenerateResponse() {
    // Regenerate the last AI response
    if (_messages.isNotEmpty) {
      final lastUserMessage = _messages.lastWhere(
        (msg) => msg.isUser,
        orElse: () => ChatMessage(
          content: widget.originalPrompt,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );

      setState(() {
        _isStreaming = true;
        _currentStreamContent = '';
      });

      final refinementPrompt =
          '''
Original request: "${widget.originalPrompt}"

${widget.currentItinerary != null ? 'Current itinerary: ${_serializeItinerary(widget.currentItinerary!)}' : ''}

User's refinement request: "${lastUserMessage.content}"

IMPORTANT: Your response MUST be in natural readable English text format, NOT in JSON. 

Format the itinerary with:
- Clear day headings like "Day 1: Arrival in Bali"
- Use bullet points ONLY for activities, not for general text
- Include paragraph text for descriptions and summaries
- Include useful details like times, locations, and brief descriptions
- DO NOT mention specific dates in your response unless the user explicitly asks for date information
- Focus on locations, activities, and general planning without date references

DO NOT return JSON format under any circumstances.
''';

      _streamRefinement(refinementPrompt);
    }
  }

  String _extractTripTitleFromPrompt() {
    final prompt = widget.originalPrompt.toLowerCase();

    // Try to extract a destination from the prompt
    String destination = '';

    // Check for common travel phrases
    final tripPatterns = [
      RegExp(
        r'(?:trip|travel|vacation|holiday|itinerary|plan)\s+(?:to|in|for)\s+([a-zA-Z\s]+)',
      ),
      RegExp(r'(?:visit|go\s+to|explore|traveling\s+to)\s+([a-zA-Z\s]+)'),
      RegExp(r'(?:days?|nights?|weeks?)\s+in\s+([a-zA-Z\s]+)'),
    ];

    for (var pattern in tripPatterns) {
      final match = pattern.firstMatch(prompt);
      if (match != null && match.groupCount >= 1) {
        destination = match.group(1)!.trim();

        // Clean up the destination by removing unnecessary words
        final stopWords = ['please', 'for', 'me', 'a', 'the', 'and', 'with'];
        for (var word in stopWords) {
          destination = destination
              .replaceAll(' $word ', ' ')
              .replaceAll(' $word', '')
              .replaceAll('$word ', '');
        }

        destination = destination.trim();
        break;
      }
    }

    // If we couldn't extract a destination, check for common locations
    if (destination.isEmpty) {
      final commonLocations = [
        'bali',
        'japan',
        'paris',
        'new york',
        'tokyo',
        'thailand',
        'europe',
        'asia',
      ];
      for (var location in commonLocations) {
        if (prompt.contains(location)) {
          destination = location;
          break;
        }
      }
    }

    // Capitalize the destination
    if (destination.isNotEmpty) {
      destination = destination
          .split(' ')
          .map((word) {
            if (word.isNotEmpty) {
              return word[0].toUpperCase() + word.substring(1);
            }
            return word;
          })
          .join(' ');

      // Try to determine the length of stay
      final durationPatterns = [
        RegExp(r'(\d+)\s+(?:days?|nights?)'),
        RegExp(r'a\s+week'),
        RegExp(r'(\d+)\s+weeks?'),
      ];

      String duration = '';
      for (var pattern in durationPatterns) {
        final match = pattern.firstMatch(prompt);
        if (match != null) {
          if (match.groupCount >= 1 && match.group(1) != null) {
            duration = '${match.group(1)} days in';
          } else if (match.pattern.toString().contains('week')) {
            duration = match.group(0)!.contains('a')
                ? 'A week in'
                : '${match.group(0)!.trim()} in';
          }
          break;
        }
      }

      if (duration.isNotEmpty) {
        return '$duration $destination';
      } else {
        return 'Trip to $destination';
      }
    }

    // Fallback if we couldn't extract anything meaningful
    return 'My Trip';
  }

  String _getTravelInfoText() {
    if (widget.currentItinerary == null) {
      return 'Travel information unavailable';
    }

    // Get origin from the original prompt or user location
    String origin = 'Your location';

    // Try to extract origin from the prompt
    final promptLower = widget.originalPrompt.toLowerCase();
    final originKeywords = ['from ', 'in ', 'leaving ', 'departing '];

    for (var keyword in originKeywords) {
      if (promptLower.contains(keyword)) {
        final index = promptLower.indexOf(keyword) + keyword.length;
        final endIndex = promptLower.indexOf(' to ');
        if (endIndex > index) {
          origin = widget.originalPrompt.substring(index, endIndex);
          // Capitalize first letter
          origin = origin[0].toUpperCase() + origin.substring(1);
          break;
        }
      }
    }

    // Get destination from itinerary
    final destination =
        widget.currentItinerary?.title.split(' in ').last ??
        widget.currentItinerary?.title.split(' to ').last ??
        'your destination';

    // Simple duration estimation (could be improved)
    String duration = '~8 hrs';

    return '$origin to $destination | $duration';
  }

  String _formatItineraryForChat(Itinerary itinerary) {
    StringBuffer buffer = StringBuffer();

    // Start with a friendly introduction
    buffer.writeln('Here\'s your itinerary for ${itinerary.title}:');
    buffer.writeln();

    // Add each day's information without specific dates
    for (int i = 0; i < itinerary.days.length; i++) {
      final day = itinerary.days[i];

      // Day heading without date
      buffer.writeln('**Day ${i + 1}: ${day.summary}**');
      buffer.writeln();

      // Activities for the day
      for (var item in day.items) {
        if (item.time.isNotEmpty) {
          buffer.writeln(
            '• ${item.time}: ${item.activity}${item.location.isNotEmpty ? ' at ${item.location}' : ''}',
          );
        } else {
          buffer.writeln(
            '• ${item.activity}${item.location.isNotEmpty ? ' at ${item.location}' : ''}',
          );
        }
      }

      if (i < itinerary.days.length - 1) {
        buffer.writeln();
      }
    }

    buffer.writeln();
    buffer.writeln('Let me know if you\'d like any changes to this itinerary!');

    return buffer.toString();
  }

  String _serializeItinerary(Itinerary itinerary) {
    // More detailed serialization for context without dates
    StringBuffer buffer = StringBuffer();

    buffer.writeln('Title: ${itinerary.title}');

    // Add a brief summary of each day without dates
    for (int i = 0; i < itinerary.days.length; i++) {
      final day = itinerary.days[i];
      buffer.writeln('Day ${i + 1}:');
      buffer.writeln('  Summary: ${day.summary}');

      // Add a few highlights from each day
      if (day.items.isNotEmpty) {
        buffer.writeln('  Highlights:');
        for (int j = 0; j < min(3, day.items.length); j++) {
          buffer.writeln(
            '    • ${day.items[j].activity} at ${day.items[j].location}',
          );
        }
      }
    }

    return buffer.toString();
  }

  // Clean up streaming content to make it more readable in real-time
  String _cleanupStreamingContent(String rawContent) {
    // If it doesn't look like JSON, return as is
    if (!rawContent.contains('{') || !rawContent.contains('"')) {
      return rawContent;
    }

    try {
      // Remove any markdown code block markers
      String cleaned = rawContent
          .replaceAll(RegExp(r'^```json'), '')
          .replaceAll(RegExp(r'```$'), '')
          .trim();

      // Replace JSON formatting with readable text during streaming
      cleaned = cleaned
          // Replace JSON structural elements
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll(',', '')
          // Fix quotes and colons
          .replaceAll('":"', ': ')
          .replaceAll('": "', ': ')
          .replaceAll('","', '\n')
          .replaceAll('", "', '\n')
          .replaceAll('":"', ': ')
          .replaceAll('":', ': ')
          .replaceAll(':"', ': ')
          // Clean up quotes
          .replaceAll('"', '')
          // Fix common patterns
          .replaceAll('title: ', '\n\nTitle: ')
          .replaceAll('description: ', '\nDescription: ')
          .replaceAll('days: ', '\n\nDays:\n')
          .replaceAll('summary: ', 'Summary: ')
          .replaceAll('activities: ', '\nActivities:\n')
          .replaceAll('items: ', '\nItems:\n');

      return cleaned;
    } catch (e) {
      return rawContent;
    }
  }

  // Helper to try to convert JSON responses to readable format
  String? _tryFormatJsonAsReadableItinerary(String jsonText) {
    try {
      // Try to clean up the JSON text first
      final cleanedText = jsonText
          .trim()
          .replaceAll(
            RegExp(r'^```json'),
            '',
          ) // Remove markdown code block start
          .replaceAll(RegExp(r'```$'), '') // Remove markdown code block end
          .trim();

      // Find the outermost JSON object
      final firstBrace = cleanedText.indexOf('{');
      final lastBrace = cleanedText.lastIndexOf('}');

      if (firstBrace == -1 || lastBrace == -1 || firstBrace >= lastBrace) {
        return null;
      }

      final jsonSubstring = cleanedText.substring(firstBrace, lastBrace + 1);

      // Try to parse the JSON
      final Map<String, dynamic> jsonMap = jsonDecode(jsonSubstring);

      if (!jsonMap.containsKey('title') || !jsonMap.containsKey('days')) {
        return null;
      }

      // Format as readable text
      StringBuffer buffer = StringBuffer();

      // Add title
      buffer.writeln("# ${jsonMap['title']}");
      buffer.writeln();

      // Add any description if available
      if (jsonMap.containsKey('description') &&
          jsonMap['description'] is String) {
        buffer.writeln("${jsonMap['description']}");
        buffer.writeln();
      }

      // Skip displaying dates unless specifically requested
      // We're removing this section to avoid showing dates

      // Add days
      final days = jsonMap['days'] as List;
      for (var i = 0; i < days.length; i++) {
        final day = days[i] as Map<String, dynamic>;

        // Add day header
        buffer.writeln("## Day ${i + 1}");

        // Add day summary if available
        if (day.containsKey('summary')) {
          buffer.writeln("${day['summary']}");
          buffer.writeln();
        }

        // Add activities or items
        final activities = day.containsKey('activities')
            ? day['activities'] as List
            : day.containsKey('items')
            ? day['items'] as List
            : [];

        for (var activity in activities) {
          if (activity is Map<String, dynamic>) {
            // Format depends on available fields
            if (activity.containsKey('time') &&
                activity.containsKey('activity')) {
              buffer.writeln("• ${activity['time']}: ${activity['activity']}");

              if (activity.containsKey('location')) {
                buffer.writeln("  Location: ${activity['location']}");
              }
            } else if (activity.containsKey('title')) {
              buffer.writeln("• ${activity['title']}");

              if (activity.containsKey('description')) {
                buffer.writeln("  ${activity['description']}");
              }
            }
            buffer.writeln();
          }
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      return null;
    }
  }
}
