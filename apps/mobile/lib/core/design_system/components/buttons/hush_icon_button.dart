import 'package:flutter/material.dart';

class HushIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  const HushIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon, size: size),
        onPressed: onPressed,
        tooltip: label,
      ),
    );
  }
}
