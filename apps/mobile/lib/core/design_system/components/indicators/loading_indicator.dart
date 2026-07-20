import 'package:flutter/material.dart';

class HushLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const HushLoadingIndicator({
    super.key,
    this.message,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Semantics(
      label: message ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );

    if (fullScreen) {
      return Center(child: child);
    }
    return child;
  }
}
