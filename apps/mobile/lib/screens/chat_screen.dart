import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUsername;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUsername,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messaging = MessagingService(
    api: ApiClient(baseUrl: 'http://$apiHost:8083'),
  );

  List<MessageInfo> _messages = [];
  String? _token;
  String? _myUserId;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final auth = AuthService(
      api: ApiClient(baseUrl: 'http://$apiHost:8081'),
    );
    final session = await auth.getSession();
    if (session != null && mounted) {
      setState(() {
        _token = session.token;
        _myUserId = session.userId;
      });
      _loadMessages();
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    if (_token == null) return;
    try {
      final messages =
          await _messaging.listMessages(_token!, widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _token == null) return;

    _messageController.clear();

    final ciphertext = base64Encode(utf8.encode(text));

    try {
      await _messaging.sendMessage(_token!, widget.conversationId, ciphertext);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  String _decrypt(String ciphertext) {
    try {
      return utf8.decode(base64Decode(ciphertext));
    } catch (_) {
      return '[encrypted]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUsername),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          final isMe = msg.senderId == _myUserId;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              constraints:
                                  BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(
                                      isMe ? 16 : 4),
                                  bottomRight: Radius.circular(
                                      isMe ? 4 : 16),
                                ),
                              ),
                              child: Text(
                                _decrypt(msg.ciphertext),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
