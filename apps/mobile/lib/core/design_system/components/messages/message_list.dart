import 'package:flutter/material.dart';
import '../../../../services/messaging_service.dart';

class MessageList extends StatelessWidget {
  final List<MessageInfo> messages;
  final String? myUserId;
  final List<ParticipantInfo> participants;
  final ScrollController scrollController;
  final Widget Function(MessageInfo message, bool isMe, String? senderName, String timestamp)
      messageBuilder;

  const MessageList({
    super.key,
    required this.messages,
    required this.myUserId,
    required this.participants,
    required this.scrollController,
    required this.messageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Semantics(
        label: 'No messages yet',
        child: const Center(child: Text('No messages yet')),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isMe = msg.senderId == myUserId;
        final sender = participants.where((p) => p.userId == msg.senderId).firstOrNull;
        final timestamp = msg.createdAt.length >= 16
            ? msg.createdAt.substring(11, 16)
            : '';
        return messageBuilder(msg, isMe, sender?.username, timestamp);
      },
    );
  }
}

class MessageInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isActive;
  final String status;
  final VoidCallback onSend;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.isActive,
    required this.status,
    required this.onSend,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Message input',
      child: Container(
        color: cs.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: widget.isActive
                        ? 'Type a message...'
                        : 'Conversation ${widget.status}',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  enabled: widget.isActive,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: widget.isActive ? widget.onSend : null,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String status;
  final bool isActive;
  final bool isConnected;
  final bool isVerified;
  final VoidCallback onComplete;
  final VoidCallback onDestroy;
  final VoidCallback onShowParticipants;

  const ConversationAppBar({
    super.key,
    required this.title,
    required this.status,
    required this.isActive,
    required this.isConnected,
    required this.isVerified,
    required this.onComplete,
    required this.onDestroy,
    required this.onShowParticipants,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Conversation: $title',
      child: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            _statusIcon(cs),
          ],
        ),
        actions: [
          if (isActive)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: onComplete,
              tooltip: 'Complete',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'destroy') onDestroy();
              if (value == 'participants') onShowParticipants();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'participants',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Participants'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'destroy',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Destroy'),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              size: 18,
              color: isConnected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(ColorScheme cs) {
    switch (status) {
      case 'completed':
        return Icon(Icons.check_circle, size: 18, color: cs.onSurfaceVariant);
      case 'destroyed':
        return const Icon(Icons.delete, size: 18, color: Colors.red);
      default:
        return Icon(Icons.circle, size: 12, color: cs.primary);
    }
  }
}
