import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';

class HushCard extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const HushCard({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  const HushCard.identity({
    super.key,
    required String displayName,
    required Widget verificationWidget,
    this.onTap,
  }) : leading = null,
       title = null,
       subtitle = null,
       trailing = null,
       padding = null,
       margin = null,
       backgroundColor = null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      color: backgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(HushSpacing.lg),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: HushSpacing.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?title,
                    if (subtitle != null) ...[const SizedBox(height: 2), subtitle!],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right, size: 20,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: _semanticsLabel,
      enabled: onTap != null,
      child: card,
    );
  }

  String get _semanticsLabel {
    final t = title is Text ? (title as Text).data : '';
    final s = subtitle is Text ? (subtitle as Text).data : '';
    return [t, s].whereType<String>().join(' - ');
  }
}
