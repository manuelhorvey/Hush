import 'package:flutter/material.dart';
import '../../theme/hush_tokens.dart';
import '../../theme/hush_theme_extensions.dart';

enum MessageStatus { normal, sending, delivered, failed }

class HushMessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? senderName;
  final String timestamp;
  final bool isEncrypted;
  final MessageStatus status;

  const HushMessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.senderName,
    required this.timestamp,
    this.isEncrypted = false,
    this.status = MessageStatus.normal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);
    final bubbleColor = isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final textColor = isMe ? cs.onPrimaryContainer : cs.onSurface;

    return Semantics(
      label: _semanticsLabel,
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
              constraints: BoxConstraints(maxWidth: _bubbleMaxWidth(context)),
              decoration: BoxDecoration(
                color: _status == MessageStatus.failed
                    ? cs.errorContainer
                    : bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(HushRadius.lg),
                  topRight: const Radius.circular(HushRadius.lg),
                  bottomLeft: Radius.circular(isMe ? HushRadius.lg : HushRadius.xs),
                  bottomRight: Radius.circular(isMe ? HushRadius.xs : HushRadius.lg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _status == MessageStatus.failed ? 'Failed to send' : text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _status == MessageStatus.failed
                              ? cs.onErrorContainer
                              : textColor,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _status == MessageStatus.failed ? '' : timestamp,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(width: 4),
                      _statusIndicator(cs, custom),
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

  MessageStatus get _status => status;

  double _bubbleMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 480;
    if (width > 400) return width * 0.72;
    return width * 0.82;
  }

  String get _semanticsLabel {
    if (_status == MessageStatus.failed) return 'Message failed to send';
    if (isMe) return 'You said: $text';
    return '${senderName ?? "Participant"} said: $text';
  }

  Widget _statusIndicator(ColorScheme cs, HushCustomColors custom) {
    if (!isMe) return const SizedBox.shrink();

    switch (_status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: cs.onSurfaceVariant),
        );
      case MessageStatus.delivered:
        return Icon(Icons.check_circle_rounded, size: 14, color: custom.success);
      case MessageStatus.failed:
        return Icon(Icons.error_rounded, size: 14, color: cs.error);
      case MessageStatus.normal:
        return Icon(Icons.check_rounded, size: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5));
    }
  }
}
