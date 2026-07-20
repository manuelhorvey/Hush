import 'package:flutter/material.dart';

class LifecycleBanner extends StatelessWidget {
  final String status; // 'completed', 'destroyed', or 'active'

  const LifecycleBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (status == 'active') return const SizedBox.shrink();

    final (label, bgColor, textColor) = switch (status) {
      'completed' => (
        'Conversation completed. Messages are preserved until destruction.',
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
      ),
      'destroyed' => (
        'This conversation has been destroyed.',
        cs.errorContainer,
        cs.onErrorContainer,
      ),
      _ => ('', Colors.transparent, Colors.transparent),
    };

    return Semantics(
      label: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: bgColor,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
