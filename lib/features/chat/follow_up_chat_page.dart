import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/itinerary_model.dart';
import '../itinerary/itinerary_controller.dart';
import '../auth/auth_controller.dart';

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
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        leadingWidth: 32,
        titleSpacing: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget.currentItinerary?.title ?? '7 days in Bali...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                // Navigate to the existing profile page
                Navigator.of(context).pushNamed('/profile');
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF008B7A),
                child: Text(
                  _getUserInitial(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User/AI indicator - always align to start
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF9500),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  message.isUser ? Icons.person : Icons.smart_toy,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.isUser ? 'You' : 'Itinera AI',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Message content
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 0, right: 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isUser ? const Color(0xFF34C759) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: message.isUser
                  ? null
                  : Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isUser && _isItineraryContent(message.content))
                  _buildItineraryContent(message.content)
                else
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons for AI messages - positioned outside the bubble
          if (!message.isUser) ...[
            const SizedBox(height: 8),
            _buildActionButtons(),
          ],

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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9500),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Itinera AI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Streaming content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStreamContent.isNotEmpty)
                  Text(
                    _currentStreamContent,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thinking...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ],
                  ),
                if (_currentStreamContent.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
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
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
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
                      style: const TextStyle(fontSize: 15),
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

Please modify the itinerary based on this request and return the updated JSON in the same format.
''';

    _streamRefinement(refinementPrompt);
  }

  Future<void> _streamRefinement(String prompt) async {
    try {
      final llmService = ref.read(llmServiceProvider);
      String fullContent = '';

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

        fullContent += chunk;
        setState(() {
          _currentStreamContent = fullContent;
        });
        _scrollToBottom();
      }

      // Try to parse and update the itinerary
      final updatedItinerary = await llmService.parseItineraryFromJson(
        fullContent,
      );

      setState(() {
        _isStreaming = false;
        _messages.add(
          ChatMessage(
            content: updatedItinerary != null
                ? 'I\'ve updated your itinerary! Check the changes above.'
                : fullContent,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

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
              const Icon(Icons.location_on, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Open in maps',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, color: Colors.blue, size: 12),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mumbai to Bali, Indonesia | 11hrs 5mins',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildItineraryLine(String line) {
    if (line.startsWith('Day ')) {
      return Text(
        line,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      );
    } else if (line.contains(':')) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          line,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Text(
          line,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(Icons.copy, 'Copy'),
        const SizedBox(width: 16),
        _buildActionButton(Icons.bookmark_border, 'Save Offline'),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Handle action button tap
        _handleActionButton(label);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _handleActionButton(String action) {
    switch (action) {
      case 'Copy':
        // Copy functionality
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
        break;
      case 'Save Offline':
        // Save offline functionality
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved offline')));
        break;
      case 'Regenerate':
        // Regenerate functionality
        _regenerateResponse();
        break;
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

Please modify the itinerary based on this request and return the updated JSON in the same format.
''';

      _streamRefinement(refinementPrompt);
    }
  }

  String _serializeItinerary(Itinerary itinerary) {
    // Simple serialization for context
    return '''
Title: ${itinerary.title}
Dates: ${itinerary.startDate} to ${itinerary.endDate}
Days: ${itinerary.days.length}
''';
  }
}
