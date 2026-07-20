import 'package:flutter/material.dart';
import '../../../../../theme/app_spacing.dart';

class SectionCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SectionCard({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(HushSpacing.lg),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: HushSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) title!,
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: _buildSemanticsLabel(),
      enabled: onTap != null,
      child: card,
    );
  }

  String _buildSemanticsLabel() {
    final parts = <String>[];
    if (title != null && title is Text) {
      final t = title as Text;
      if (t.data != null) parts.add(t.data!);
    }
    if (subtitle != null && subtitle is Text) {
      final s = subtitle as Text;
      if (s.data != null) parts.add(s.data!);
    }
    return parts.join(' - ');
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (actionLabel != null) ...[
            const Spacer(),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> items;

  const SettingsGroup({
    super.key,
    this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          SectionHeader(title: title!),
          const SizedBox(height: 4),
        ],
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}
