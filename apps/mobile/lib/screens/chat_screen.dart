import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import '../services/identity_service.dart';
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
  final _identity = IdentityService(
    api: ApiClient(baseUrl: 'http://$apiHost:8082'),
  );
  final _crypto = CryptoService();

  List<MessageInfo> _messages = [];
  String? _token;
  String? _myUserId;
  bool _loading = true;
  bool _connected = false;
  bool _isActive = true;
  String _status = 'active';
  List<int>? _sharedSecret;
  WebSocket? _ws;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _ws?.close();
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
      await _setupKey();
      await _loadMessages();
      _connectWs(session.token);
    }
  }

  Future<void> _setupKey() async {
    if (_token == null) return;
    try {
      final otherKey =
          await _identity.getExchangeKey(_token!, widget.otherUserId);
      final secret = await _crypto.deriveSharedSecret(otherKey);
      if (mounted) setState(() => _sharedSecret = secret);
    } catch (_) {}
  }

  void _connectWs(String token) {
    final wsUrl = 'ws://$apiHost:8080/ws?token=$token';

    WebSocket.connect(wsUrl).then((ws) {
      _ws = ws;
      if (mounted) setState(() => _connected = true);
      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            final message = MessageInfo(
              id: msg['id'] as String,
              senderId: msg['sender_id'] as String,
              ciphertext: msg['ciphertext'] as String,
              createdAt: msg['created_at'] as String,
            );
            if (mounted) {
              setState(() => _messages.add(message));
              _scrollToBottom();
            }
          } catch (_) {}
        },
        onDone: () {
          if (mounted) {
            setState(() => _connected = false);
            _scheduleReconnect(token);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _connected = false);
            _scheduleReconnect(token);
          }
        },
      );
    }).catchError((_) {
      if (mounted) {
        setState(() => _connected = false);
        _scheduleReconnect(token);
      }
    });
  }

  void _scheduleReconnect(String token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _connectWs(token);
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
    if (text.isEmpty || _token == null || _sharedSecret == null) return;

    _messageController.clear();

    try {
      final ciphertext =
          await _crypto.encryptWithSharedKey(text, _sharedSecret!);
      await _messaging.sendMessage(_token!, widget.conversationId, ciphertext);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  Future<String> _decrypt(String ciphertext) async {
    if (_sharedSecret == null) return '[encrypted]';
    try {
      return await _crypto.decryptWithSharedKey(ciphertext, _sharedSecret!);
    } catch (_) {
      return '[encrypted]';
    }
  }

  Future<void> _completeConversation() async {
    if (_token == null) return;
    try {
      final conv =
          await _messaging.completeConversation(_token!, widget.conversationId);
      if (mounted) {
        setState(() {
          _status = conv.status;
          _isActive = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _destroyConversation() async {
    if (_token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Destroy Conversation?'),
        content: const Text(
            'This will permanently delete all messages. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Destroy'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _messaging.destroyConversation(_token!, widget.conversationId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.otherUsername),
            const SizedBox(width: 8),
            _statusIcon(),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isActive)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _completeConversation,
              tooltip: 'Complete',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'destroy') _destroyConversation();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'destroy',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Destroy'),
                    ],
                  )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              _connected ? Icons.wifi : Icons.wifi_off,
              size: 18,
              color: _connected ? Colors.green : Colors.grey,
            ),
          ),
        ],
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
                          return FutureBuilder<String>(
                            future: _decrypt(msg.ciphertext),
                            builder: (context, snapshot) {
                              final text = snapshot.data ?? '[encrypted]';
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  constraints: BoxConstraints(maxWidth: 280),
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
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(isMe ? 4 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    text,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            },
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
                        hintText: _isActive
                            ? 'Type a message...'
                            : 'Conversation $_status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      enabled: _isActive,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isActive ? _sendMessage : null,
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

  Widget _statusIcon() {
    switch (_status) {
      case 'completed':
        return const Icon(Icons.check_circle, size: 18, color: Colors.grey);
      case 'destroyed':
        return const Icon(Icons.delete, size: 18, color: Colors.red);
      default:
        return const Icon(Icons.circle, size: 12, color: Colors.green);
    }
  }
}
