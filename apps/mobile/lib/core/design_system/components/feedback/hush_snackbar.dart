import 'package:flutter/material.dart';

enum SnackbarType { success, error, info, warning }

class HushSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (type) {
      SnackbarType.success => (cs.primaryContainer, cs.onPrimaryContainer),
      SnackbarType.error => (cs.errorContainer, cs.onErrorContainer),
      SnackbarType.info => (cs.surfaceContainerHighest, cs.onSurface),
      SnackbarType.warning => (cs.errorContainer, cs.onErrorContainer),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _icon(type),
              size: 18,
              color: fg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                label: message,
                child: Text(
                  message,
                  style: TextStyle(color: fg),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static IconData _icon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_rounded;
      case SnackbarType.error:
        return Icons.error_rounded;
      case SnackbarType.info:
        return Icons.info_rounded;
      case SnackbarType.warning:
        return Icons.warning_rounded;
    }
  }
}
