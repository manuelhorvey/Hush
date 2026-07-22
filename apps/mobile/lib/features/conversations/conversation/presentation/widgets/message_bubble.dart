import 'package:flutter/material.dart';

import '../../../../../core/design_system/theme/theme.dart';
import '../../../../messaging/domain/entities/message.dart';
import '../../../../messaging/domain/entities/message_status.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);
    final bubbleColor = isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final textColor = isMe ? cs.onPrimaryContainer : cs.onSurface;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = Radius.circular(HushRadius.lg);

    return Semantics(
      label: message.accessibilityLabel,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? HushSpacing.xxl : HushSpacing.lg,
          right: isMe ? HushSpacing.lg : HushSpacing.xxl,
          top: 2,
          bottom: 2,
        ),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            // Sender name for received messages
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                  bottom: 2,
                ),
                child: Text(
                  message.senderName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

            // Bubble
            Align(
              alignment: isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: HushSpacing.md,
                  vertical: HushSpacing.sm + 2,
                ),
                constraints: BoxConstraints(
                  maxWidth: _bubbleMaxWidth(context),
                ),
                decoration: BoxDecoration(
                  color: message.status == MessageStatus.failed
                      ? cs.errorContainer
                      : bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    topRight: radius,
                    bottomLeft: isMe ? radius : Radius.circular(4),
                    bottomRight: isMe ? Radius.circular(4) : radius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Content
                    Text(
                      message.status == MessageStatus.failed
                          ? 'Failed to send'
                          : message.content,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color: message.status == MessageStatus.failed
                                ? cs.onErrorContainer
                                : textColor,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 4),

                    // Timestamp + status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.timeString,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _statusIcon(cs, custom),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _bubbleMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 520;
    if (width > 600) return 480;
    if (width > 400) return width * 0.75;
    return width * 0.82;
  }

  Widget _statusIcon(ColorScheme cs, HushCustomColors custom) {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: cs.onSurfaceVariant,
          ),
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_rounded,
          size: 14,
          color: cs.error,
        );
      case MessageStatus.sent:
        return SizedBox(
          width: 14,
          child: Icon(
            Icons.check_rounded,
            size: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        );
      case MessageStatus.delivered:
        return SizedBox(
          width: 14,
          child: Icon(
            Icons.done_all_rounded,
            size: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        );
      case MessageStatus.pending:
        return SizedBox(
          width: 14,
          child: Icon(
            Icons.schedule_rounded,
            size: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        );
    }
  }
}
