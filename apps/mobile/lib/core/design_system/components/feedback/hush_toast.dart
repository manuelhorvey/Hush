import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';

enum ToastType { success, error, info, warning }

class HushToast {
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (type) {
      ToastType.success => (cs.primaryContainer, cs.onPrimaryContainer, Icons.check_circle_rounded),
      ToastType.error => (cs.errorContainer, cs.onErrorContainer, Icons.error_rounded),
      ToastType.info => (cs.secondaryContainer, cs.onSecondaryContainer, Icons.info_rounded),
      ToastType.warning => (cs.errorContainer, cs.onErrorContainer, Icons.warning_rounded),
    };

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
          child: Semantics(
            label: message,
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(HushSpacing.borderRadiusSm),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(message, style: TextStyle(color: fg, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry!);
    Future.delayed(duration, () => entry?.remove());
  }
}
