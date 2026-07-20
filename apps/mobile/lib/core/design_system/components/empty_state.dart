import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';
import '../theme/hush_theme_extensions.dart';

typedef EmptyState = HushEmptyState;

class HushEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HushEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  const HushEmptyState.noConversations({super.key})
    : icon = Icons.chat_bubble_outline_rounded,
      title = 'No moments yet',
      subtitle = 'Start a new private moment',
      actionLabel = 'Start a Moment',
      onAction = null;

  const HushEmptyState.noDevices({super.key})
    : icon = Icons.devices_rounded,
      title = 'No devices',
      subtitle = 'Your identity exists on this device',
      actionLabel = null,
      onAction = null;

  const HushEmptyState.offline({super.key})
    : icon = Icons.wifi_off_rounded,
      title = 'No connection',
      subtitle = 'Connect to the internet to use Hush',
      actionLabel = null,
      onAction = null;

  const HushEmptyState.searchEmpty({super.key})
    : icon = Icons.search_off_rounded,
      title = 'No results found',
      subtitle = 'Try a different search term',
      actionLabel = null,
      onAction = null;

  const HushEmptyState.error({super.key})
    : icon = Icons.error_outline_rounded,
      title = 'Something went wrong',
      subtitle = 'Please try again',
      actionLabel = null,
      onAction = null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$title. ${subtitle ?? ''}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(HushSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: HushSpacing.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: HushSpacing.sm),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: HushSpacing.xl),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
