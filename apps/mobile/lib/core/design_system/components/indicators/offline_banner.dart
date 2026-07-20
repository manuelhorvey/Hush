import 'package:flutter/material.dart';

class HushOfflineBanner extends StatelessWidget {
  final bool isOffline;

  const HushOfflineBanner({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'You are offline',
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: cs.errorContainer,
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 16, color: cs.onErrorContainer),
            const SizedBox(width: 8),
            Text(
              'No internet connection',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
