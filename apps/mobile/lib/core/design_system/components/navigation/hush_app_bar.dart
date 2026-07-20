import 'package:flutter/material.dart';

class HushAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final bool centerTitle;

  const HushAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBack = false,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title ?? '',
      child: AppBar(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: showBack,
        centerTitle: centerTitle,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
