import 'package:flutter/material.dart';
import '../../theme/hush_tokens.dart';

class HushMessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? senderName;
  final String timestamp;
  final bool isEncrypted;
  final bool showStatus;

  const HushMessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.senderName,
    required this.timestamp,
    this.isEncrypted = false,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bubbleColor = isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final textColor = isMe ? cs.onPrimaryContainer : cs.onSurface;

    return Semantics(
      label: isMe
          ? 'You said: $text'
          : '${senderName ?? "Participant"} said: $text',
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                senderName!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                    ),
              ),
            ),
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(RadiusTokens.lg),
                  topRight: const Radius.circular(RadiusTokens.lg),
                  bottomLeft: Radius.circular(isMe ? RadiusTokens.lg : RadiusTokens.xs),
                  bottomRight: Radius.circular(isMe ? RadiusTokens.xs : RadiusTokens.lg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timestamp,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                      ),
                      if (showStatus && isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ],
                    ],
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

class HushSecurityBubble extends StatelessWidget {
  final String text;
  final bool isEncrypted;

  const HushSecurityBubble({
    super.key,
    required this.text,
    this.isEncrypted = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Encrypted message',
      child: Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEncrypted ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
