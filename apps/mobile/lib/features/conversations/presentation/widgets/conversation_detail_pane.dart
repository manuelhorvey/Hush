import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../models/conversation.dart';

class ConversationDetailPane extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onDeselect;

  const ConversationDetailPane({
    super.key,
    required this.conversation,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);
    final isOpen = conversation.lifecycle.isOpen;

    return Semantics(
      label: 'Moment details: ${conversation.displayName}',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HushSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Semantics(
                label: 'Deselect conversation',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: onDeselect,
                ),
              ),
            ),

            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isOpen
                    ? (conversation.isVerified
                        ? custom.success.withValues(alpha: 0.12)
                        : cs.primaryContainer)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  conversation.firstOtherParticipantName?.isNotEmpty == true
                      ? conversation.firstOtherParticipantName![0].toUpperCase()
                      : '?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOpen
                            ? (conversation.isVerified
                                ? custom.success
                                : cs.onPrimaryContainer)
                            : cs.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            const SizedBox(height: HushSpacing.lg),

            // Name
            Text(
              conversation.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),

            // Security status
            Row(
              children: [
                Icon(
                  conversation.isVerified
                      ? Icons.verified_rounded
                      : Icons.lock_rounded,
                  size: 16,
                  color: conversation.isVerified
                      ? custom.success
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: HushSpacing.xs),
                Text(
                  conversation.isVerified ? 'Verified' : 'Private',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: conversation.isVerified
                            ? custom.success
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: HushSpacing.md),

            // Lifecycle status
            _DetailRow(
              icon: Icons.circle_rounded,
              iconColor: isOpen ? custom.success : cs.onSurfaceVariant,
              label: conversation.lifecycle.description,
            ),
            const SizedBox(height: HushSpacing.sm),

            // Started
            _DetailRow(
              icon: Icons.schedule_rounded,
              iconColor: cs.onSurfaceVariant,
              label: 'Started ${conversation.relativeTime}',
            ),
            if (conversation.completedAt != null) ...[
              const SizedBox(height: HushSpacing.sm),
              _DetailRow(
                icon: Icons.check_circle_outline_rounded,
                iconColor: cs.onSurfaceVariant,
                label: 'Completed ${conversation.completedRelativeTime}',
              ),
            ],
            const SizedBox(height: HushSpacing.xl),

            // Action buttons
            const Divider(),
            const SizedBox(height: HushSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push('/conversation/${conversation.id}',
                        extra: conversation.displayName),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                    isOpen ? 'Open Conversation' : 'View Conversation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor.withValues(alpha: 0.7)),
        const SizedBox(width: HushSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
