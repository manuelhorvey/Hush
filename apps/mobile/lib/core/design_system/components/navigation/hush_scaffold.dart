import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';
import '../../../responsive/responsive_layout.dart';

class HushScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? fab;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final EdgeInsetsGeometry? bodyPadding;
  final Color? backgroundColor;

  const HushScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.fab,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.bodyPadding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: backgroundColor ?? cs.surface,
      appBar: appBar as PreferredSizeWidget?,
      body: ResponsiveBuilder(
        builder: (context, size) {
          final defaultPadding = size.isDesktop || size.isTablet
              ? const EdgeInsets.fromLTRB(
                  HushSpacing.xxl,
                  HushSpacing.xl,
                  HushSpacing.xxl,
                  HushSpacing.xxl,
                )
              : const EdgeInsets.fromLTRB(
                  HushSpacing.lg,
                  HushSpacing.md,
                  HushSpacing.lg,
                  HushSpacing.xxl,
                );
          return Padding(
            padding: bodyPadding ?? defaultPadding,
            child: body,
          );
        },
      ),
      floatingActionButton: fab,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
    );
  }
}
