import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';

/// Security notice widget for displaying security-related messages.
///
/// Examples:
/// - "This device is trusted"
/// - "Review this device"
/// - "Your session is secure"
///
/// Uses Hush trust language throughout.
class SecurityNotice extends StatelessWidget {
  final String message;
  final String? detail;
  final SecurityNoticeType type;
  final IconData? customIcon;

  const SecurityNotice({
    super.key,
    required this.message,
    this.detail,
    this.type = SecurityNoticeType.info,
    this.customIcon,
  });

  factory SecurityNotice.trusted({
    String? detail,
  }) {
    return SecurityNotice(
      message: 'This device is trusted',
      detail: detail,
      type: SecurityNoticeType.success,
      customIcon: Icons.shield_rounded,
    );
  }

  factory SecurityNotice.review({
    String? detail,
  }) {
    return SecurityNotice(
      message: 'Review this device',
      detail: detail,
      type: SecurityNoticeType.warning,
      customIcon: Icons.visibility_outlined,
    );
  }

  factory SecurityNotice.info({
    required String message,
    String? detail,
  }) {
    return SecurityNotice(
      message: message,
      detail: detail,
      type: SecurityNoticeType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (Color bg, Color iconColor, IconData icon) = switch (type) {
      SecurityNoticeType.success => (
        Colors.green.withValues(alpha: 0.08),
        Colors.green,
        customIcon ?? Icons.check_circle_rounded,
      ),
      SecurityNoticeType.warning => (
        cs.errorContainer.withValues(alpha: 0.4),
        cs.error,
        customIcon ?? Icons.warning_amber_rounded,
      ),
      SecurityNoticeType.info => (
        cs.surfaceContainerHighest.withValues(alpha: 0.5),
        cs.primary,
        customIcon ?? Icons.info_outline_rounded,
      ),
    };

    return Semantics(
      label: '$message${detail != null ? ' - $detail' : ''}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: HushSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SecurityNoticeType {
  success,
  warning,
  info,
}
