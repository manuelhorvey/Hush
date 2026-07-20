import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';

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
      body: Padding(
        padding: bodyPadding ??
            const EdgeInsets.fromLTRB(
              HushSpacing.lg,
              HushSpacing.md,
              HushSpacing.lg,
              HushSpacing.xxl,
            ),
        child: body,
      ),
      floatingActionButton: fab,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
    );
  }
}
