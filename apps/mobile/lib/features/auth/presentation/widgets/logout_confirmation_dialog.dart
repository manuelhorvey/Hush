import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';

/// Logout confirmation dialog.
///
/// Follows Hush's UX philosophy:
/// - Title: "Sign out of this device?"
/// - Explanation: "You can sign back in later."
/// - Do NOT use: "Delete account"
/// - Actions: Cancel, Sign out
class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  /// Show the logout confirmation dialog.
  static Future<bool?> show(BuildContext context, VoidCallback onConfirm) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => LogoutConfirmationDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Sign out confirmation',
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, size: 22, color: cs.error),
            const SizedBox(width: HushSpacing.sm),
            Expanded(
              child: Text(
                'Sign out of this device?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        content: Text(
          'You can sign back in later.\n'
          'Your conversations remain private on other devices.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
