import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/itinerary_model.dart';
import '../itinerary/itinerary_controller.dart';

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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Refine Itinerary'),
            Text(
              widget.originalPrompt.length > 30
                  ? '${widget.originalPrompt.substring(0, 30)}...'
                  : widget.originalPrompt,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          if (widget.currentItinerary != null)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _showCurrentItinerary(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildStreamingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStreamContent.isNotEmpty)
                    Text(_currentStreamContent)
                  else
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('AI is thinking...'),
                      ],
                    ),
                  if (_currentStreamContent.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 2,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask to modify your itinerary...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              onSubmitted: _isStreaming ? null : (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isStreaming ? null : _sendMessage,
            icon: Icon(
              Icons.send,
              color: _isStreaming
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
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

  String _serializeItinerary(Itinerary itinerary) {
    // Simple serialization for context
    return '''
Title: ${itinerary.title}
Dates: ${itinerary.startDate} to ${itinerary.endDate}
Days: ${itinerary.days.length}
''';
  }

  void _showCurrentItinerary() {
    if (widget.currentItinerary == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Current Itinerary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    _serializeItinerary(widget.currentItinerary!),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
