import 'package:flutter/material.dart';

import '../../../../../core/design_system/theme/theme.dart';

class ConversationInput extends StatefulWidget {
  final bool isActive;
  final ValueChanged<String> onSend;

  const ConversationInput({
    super.key,
    required this.isActive,
    required this.onSend,
  });

  @override
  State<ConversationInput> createState() => _ConversationInputState();
}

class _ConversationInputState extends State<ConversationInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!widget.isActive) {
      return Semantics(
        label: 'Moment completed',
        container: true,
        child: Container(
          padding: const EdgeInsets.all(HushSpacing.lg),
          color: cs.surfaceContainerLowest,
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: HushSpacing.sm),
                Text(
                  'Moment completed. Messages are preserved.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Message input',
      container: true,
      child: Container(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              HushSpacing.md,
              HushSpacing.sm,
              HushSpacing.sm,
              HushSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: HushSpacing.md,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(HushRadius.full),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(HushRadius.full),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerLowest,
                    ),
                  ),
                ),
                const SizedBox(width: HushSpacing.sm),
                Semantics(
                  label: 'Send message',
                  button: true,
                  child: AnimatedContainer(
                    duration: HushMotion.normal,
                    curve: HushMotion.standard,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasText
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.15),
                    ),
                    child: IconButton(
                      onPressed: _hasText ? _send : null,
                      icon: Icon(
                        Icons.send_rounded,
                        color: _hasText
                            ? cs.onPrimary
                            : cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
