import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';

class UserAvatar extends StatelessWidget {
  final String? displayName;
  final String? photoUrl;
  final double size;
  final bool isVerified;

  const UserAvatar({
    super.key,
    this.displayName,
    this.photoUrl,
    this.size = 40,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = displayName != null && displayName!.isNotEmpty
        ? displayName![0].toUpperCase()
        : '?';
    final fontSize = size * 0.4;

    final avatar = photoUrl != null
        ? CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(photoUrl!),
            onBackgroundImageError: (_, _) {},
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: cs.primaryContainer,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
              ),
            ),
          );

    return Semantics(
      label: displayName ?? 'User avatar',
      child: Stack(
        children: [
          avatar,
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.surface,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: size * 0.2,
                  color: cs.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.primaryContainer;
    final fg = foregroundColor ?? cs.onPrimaryContainer;

    return Semantics(
      label: 'Avatar: $initials',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        ),
        child: Center(
          child: Text(
            initials.length > 2 ? initials.substring(0, 2).toUpperCase() : initials.toUpperCase(),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
