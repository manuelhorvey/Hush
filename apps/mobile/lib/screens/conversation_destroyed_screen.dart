import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class ConversationDestroyedScreen extends StatelessWidget {
  final String conversationTitle;

  const ConversationDestroyedScreen({
    super.key,
    required this.conversationTitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(conversationTitle),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(HushSpacing.xxl),
          child: Semantics(
            label: 'Moment gone. All messages permanently deleted.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    size: 40,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: HushSpacing.xl),
                Text(
                  'Moment Gone',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: HushSpacing.md),
                Text(
                  'All messages have been permanently deleted from your devices. '
                  'This action cannot be undone.',
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
