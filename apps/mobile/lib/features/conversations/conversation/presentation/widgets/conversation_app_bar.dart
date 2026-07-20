import 'package:flutter/material.dart';

import '../../../../../core/design_system/theme/theme.dart';

class ConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String displayName;
  final String? avatarLetter;
  final bool isVerified;
  final bool isActive;
  final String lifecycleStatus;
  final DateTime? completedAt;
  final VoidCallback onViewProfile;
  final VoidCallback onVerifyIdentity;
  final VoidCallback onComplete;
  final VoidCallback onSecurityDetails;
  final VoidCallback onDestroy;
  final VoidCallback onReport;

  const ConversationAppBar({
    super.key,
    required this.displayName,
    this.avatarLetter,
    required this.isVerified,
    required this.isActive,
    required this.lifecycleStatus,
    this.completedAt,
    required this.onViewProfile,
    required this.onVerifyIdentity,
    required this.onComplete,
    required this.onSecurityDetails,
    required this.onDestroy,
    required this.onReport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  String get _subtitle {
    switch (lifecycleStatus) {
      case 'completed':
        final closing = _closingLabel;
        if (closing != null) return closing;
        return 'Moment Complete';
      case 'destroyed':
        return 'Gone';
      default:
        if (isVerified) return 'Private \u2022 Trusted';
        return 'Private \u2022 Verify Identity';
    }
  }

  String? get _closingLabel {
    if (completedAt == null) return null;
    final deadline = completedAt!.add(const Duration(hours: 24));
    final now = DateTime.now();
    final remaining = deadline.difference(now);

    if (remaining.isNegative) return null;

    // Compare calendar dates, not hours
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final today = DateTime(now.year, now.month, now.day);

    if (deadlineDay != today) {
      return 'Closing Tomorrow';
    }

    // Closing later today
    if (remaining.inHours < 1) {
      final minutes = remaining.inMinutes;
      if (minutes <= 1) return 'Closing in 1m';
      return 'Closing in ${minutes}m';
    }
    return 'Closing in ${remaining.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letter = avatarLetter ??
        (displayName.isNotEmpty ? displayName[0].toUpperCase() : '?');
    final subtitleColor = switch (lifecycleStatus) {
      'completed' => cs.tertiary,
      'destroyed' => cs.onSurfaceVariant.withValues(alpha: 0.5),
      _ => cs.onSurfaceVariant.withValues(alpha: 0.6),
    };

    return Semantics(
      label: 'Moment with $displayName',
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  // Back
                  Semantics(
                    label: 'Back',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Avatar
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: HushSpacing.sm),

                  // Name + dynamic subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Overflow menu only
                  Semantics(
                    label: 'Moment options',
                    button: true,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            onViewProfile();
                          case 'verify':
                            onVerifyIdentity();
                          case 'complete':
                            onComplete();
                          case 'security':
                            onSecurityDetails();
                          case 'report':
                            onReport();
                          case 'destroy':
                            onDestroy();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: _MenuItem(
                            icon: Icons.person_rounded,
                            label: 'View Profile',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'verify',
                          child: _MenuItem(
                            icon: Icons.verified_rounded,
                            label: 'Verify Identity',
                          ),
                        ),
                        if (isActive) ...[
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'complete',
                            child: _MenuItem(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Complete Moment',
                            ),
                          ),
                        ],
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'security',
                          child: _MenuItem(
                            icon: Icons.shield_outlined,
                            label: 'Security Details',
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'report',
                          child: _MenuItem(
                            icon: Icons.flag_rounded,
                            label: 'Report',
                            iconColor: cs.error,
                            textColor: cs.error,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'destroy',
                          child: _MenuItem(
                            icon: Icons.delete_forever_rounded,
                            label: 'Let Go',
                            iconColor: cs.error,
                            textColor: cs.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(label, style: textColor != null ? TextStyle(color: textColor) : null),
      ],
    );
  }
}
