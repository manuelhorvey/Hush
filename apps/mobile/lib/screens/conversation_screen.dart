import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/design_system/components/messages/message_list.dart';
import '../core/design_system/components/messages/hush_message_bubble.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/crypto_service.dart';
import '../services/identity_service.dart';
import '../services/messaging_service.dart';
import '../core/design_system/components/lifecycle/lifecycle_banner.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final List<ParticipantInfo> participants;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.participants,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<MessageInfo> _messages = [];
  bool _loading = true;
  bool _connected = false;
  bool _isActive = true;
  String _status = 'active';
  List<int>? _groupKey;
  WebSocket? _ws;
  Timer? _reconnectTimer;
  String? _token;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _ws?.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    _token = auth.token;
    _myUserId = auth.userId;
    await _loadGroupKey();
    await _loadMessages();
    if (_token != null) _connectWs(_token!);
  }

  String get _chatTitle {
    final others = widget.participants
        .where((p) => p.userId != _myUserId)
        .map((p) => p.username)
        .toList();
    if (others.length == 1) return others.first;
    return '${others.first} +${others.length - 1}';
  }

  Future<void> _loadGroupKey() async {
    if (_token == null) return;
    try {
      final messaging = context.read<MessagingService>();
      final identity = context.read<IdentityService>();
      final crypto = context.read<CryptoService>();
      final encryptedKey = await messaging.getGroupKey(_token!, widget.conversationId);
      final creatorId = widget.participants
          .where((p) => p.userId != _myUserId)
          .firstOrNull
          ?.userId;
      if (creatorId == null) return;
      final creatorPubKey = await identity.getExchangeKey(_token!, creatorId);
      final groupKey = await crypto.decryptGroupKey(encryptedKey, creatorPubKey);
      if (mounted) setState(() => _groupKey = groupKey);
    } catch (_) {}
  }

  void _connectWs(String token) {
    WebSocket.connect('ws://$apiHost:8080/ws?token=$token').then((ws) {
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
        onDone: () => _onWsDisconnected(token),
        onError: (_) => _onWsDisconnected(token),
      );
    }).catchError((_) {
      _onWsDisconnected(token);
      return null;
    });
  }

  void _onWsDisconnected(String token) {
    if (mounted) {
      setState(() => _connected = false);
      _scheduleReconnect(token);
    }
  }

  void _scheduleReconnect(String token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () => _connectWs(token));
  }

  Future<void> _loadMessages() async {
    if (_token == null) return;
    try {
      final messaging = context.read<MessagingService>();
      final messages = await messaging.listMessages(_token!, widget.conversationId);
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
    if (text.isEmpty || _token == null || _groupKey == null) return;
    _messageController.clear();
    try {
      final crypto = context.read<CryptoService>();
      final messaging = context.read<MessagingService>();
      final ciphertext = await crypto.encryptWithSharedKey(text, _groupKey!);
      await messaging.sendMessage(_token!, widget.conversationId, ciphertext);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  Future<void> _completeConversation() async {
    if (_token == null) return;
    try {
      final messaging = context.read<MessagingService>();
      final conv = await messaging.completeConversation(_token!, widget.conversationId);
      if (mounted) setState(() { _status = conv.status; _isActive = false; });
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
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
      await context.read<MessagingService>().destroyConversation(_token!, widget.conversationId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<String> _decrypt(String ciphertext) async {
    if (_groupKey == null) return '[encrypted]';
    try {
      final crypto = context.read<CryptoService>();
      return await crypto.decryptWithSharedKey(ciphertext, _groupKey!);
    } catch (_) {
      return '[encrypted]';
    }
  }

  void _showParticipants() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Participants'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.participants
              .map((p) => ListTile(
                    leading: CircleAvatar(child: Text(p.username[0].toUpperCase())),
                    title: Text(p.username),
                    subtitle: p.userId == _myUserId ? const Text('You') : null,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConversationAppBar(
        title: _chatTitle,
        status: _status,
        isActive: _isActive,
        isConnected: _connected,
        isVerified: false,
        onComplete: _completeConversation,
        onDestroy: _destroyConversation,
        onShowParticipants: _showParticipants,
      ),
      body: Column(
        children: [
          LifecycleBanner(
            lifecycle: switch (_status) {
              'completed' => ConversationLifecycle.closed,
              'destroyed' => ConversationLifecycle.destroyed,
              _ => ConversationLifecycle.active,
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : MessageList(
                    messages: _messages,
                    myUserId: _myUserId,
                    participants: widget.participants,
                    scrollController: _scrollController,
                    messageBuilder: (msg, isMe, senderName, timestamp) {
                      return FutureBuilder<String>(
                        future: _decrypt(msg.ciphertext),
                        builder: (context, snapshot) {
                          return HushMessageBubble(
                            text: snapshot.data ?? '[encrypted]',
                            isMe: isMe,
                            senderName: isMe ? null : senderName,
                            timestamp: timestamp,
                          );
                        },
                      );
                    },
                  ),
          ),
          MessageInputBar(
            controller: _messageController,
            isActive: _isActive,
            status: _status,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
