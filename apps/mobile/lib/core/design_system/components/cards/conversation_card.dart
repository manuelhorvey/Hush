import 'package:flutter/material.dart';
import '../../../../../theme/app_spacing.dart';
import '../indicators/status_badge.dart';

class ConversationCard extends StatelessWidget {
  final String title;
  final bool isActive;
  final String status;
  final String date;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.title,
    required this.isActive,
    required this.status,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: HushSpacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(HushSpacing.lg),
            child: Row(
              children: [
                Semantics(
                  label: isActive ? 'Active conversation' : 'Closed conversation',
                  child: Container(
                    width: HushSpacing.avatarSize,
                    height: HushSpacing.avatarSize,
                    decoration: BoxDecoration(
                      color: isActive
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.chat_bubble_rounded
                          : Icons.check_circle_outline_rounded,
                      size: HushSpacing.iconSize,
                      color: isActive ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: HushSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            date,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(width: HushSpacing.sm),
                          StatusBadge(label: status),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
