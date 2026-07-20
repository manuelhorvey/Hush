import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../models/conversation.dart';
import 'conversation_card.dart';

class ConversationSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Conversation> conversations;
  final bool initiallyExpanded;
  final IconData icon;
  final ValueChanged<Conversation>? onConversationTap;
  final String? selectedConversationId;

  const ConversationSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.conversations,
    this.initiallyExpanded = true,
    this.icon = Icons.chat_bubble_outline_rounded,
    this.onConversationTap,
    this.selectedConversationId,
  });

  @override
  State<ConversationSection> createState() => _ConversationSectionState();
}

class _ConversationSectionState extends State<ConversationSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: HushMotion.normal,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: HushMotion.standard,
    );
    if (_expanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Semantics(
          label: '${widget.title}. ${widget.conversations.length} moments.',
          button: true,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HushSpacing.xs,
                vertical: HushSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: HushSpacing.sm),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: HushSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.conversations.length}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: HushMotion.normal,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Subtitle
        if (widget.conversations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: HushSpacing.xs + 18 + HushSpacing.sm,
              bottom: HushSpacing.sm,
            ),
            child: Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
            ),
          ),

        // Conversation cards (animated expand/collapse)
        SizeTransition(
          sizeFactor: _expandAnimation,
          alignment: Alignment.topCenter,
          child: widget.conversations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(left: HushSpacing.xs + 18 + HushSpacing.sm),
                  child: Text(
                    widget.conversations.isEmpty
                        ? 'No ${widget.title.toLowerCase()} moments'
                        : 'No ${widget.title.toLowerCase()} moments.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.conversations.map(
                    (conversation) => ConversationCard(
                      conversation: conversation,
                      isSelected: conversation.id == widget.selectedConversationId,
                      onTap: () => widget.onConversationTap?.call(conversation),
                    ),
                  ).toList(),
                ),
        ),
      ],
    );
  }
}
