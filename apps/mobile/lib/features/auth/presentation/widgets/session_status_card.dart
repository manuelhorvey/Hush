import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../providers/session_provider.dart';

/// Displays the current session status in a card format.
///
/// Shows: session active state, device trust status, session expiry.
/// Uses Hush trust language: "Device trusted" rather than "Session authenticated".
class SessionStatusCard extends ConsumerWidget {
  const SessionStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final session = ref.watch(sessionProvider);
    final isExpiring = ref.watch(sessionExpiringProvider);

    if (session == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(HushSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: HushSpacing.md),
              Text(
                'No active session',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HushSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Row(
              children: [
                _StatusDot(
                  color: session.isValid
                      ? (isExpiring ? cs.tertiary : Colors.green)
                      : cs.error,
                ),
                const SizedBox(width: HushSpacing.sm),
                Text(
                  isExpiring
                      ? 'Session ending soon'
                      : (session.isValid
                          ? 'Device trusted'
                          : 'Session ended'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: HushSpacing.md),
            _detailRow(
              context,
              'Session',
              session.displayId,
            ),
            const SizedBox(height: HushSpacing.xs),
            _detailRow(
              context,
              'Status',
              session.status.name,
            ),
            if (session.isAboutToExpire || session.isExpired) ...[
              const SizedBox(height: HushSpacing.xs),
              _detailRow(
                context,
                'Expires',
                _formatExpiry(session.expiresAt),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inMinutes < 1) return 'Less than a minute';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m remaining';
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m remaining';
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
