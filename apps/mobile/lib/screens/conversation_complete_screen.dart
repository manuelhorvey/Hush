import 'package:flutter/material.dart';
import '../core/design_system/theme/hush_theme_extensions.dart';
import '../theme/app_spacing.dart';

class ConversationCompleteScreen extends StatelessWidget {
  final String conversationTitle;

  const ConversationCompleteScreen({
    super.key,
    required this.conversationTitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(conversationTitle),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(HushSpacing.xxl),
          child: Semantics(
            label: 'Moment completed. Messages are sealed.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: custom.successContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 40,
                    color: custom.success,
                  ),
                ),
                const SizedBox(height: HushSpacing.xl),
                Text(
                  'Moment Complete',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: HushSpacing.md),
                Text(
                  'All messages are sealed and this conversation is now read-only. '
                  'Your encrypted data remains on your devices.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: HushSpacing.xxl),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Moments'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
