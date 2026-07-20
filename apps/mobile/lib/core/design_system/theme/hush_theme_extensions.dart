import 'package:flutter/material.dart';

class HushCustomColors extends ThemeExtension<HushCustomColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color surfaceDim;
  final Color surfaceBright;

  const HushCustomColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.surfaceDim,
    required this.surfaceBright,
  });

  static const light = HushCustomColors(
    success: Color(0xFF059669),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFD1FAE5),
    warning: Color(0xFFD97706),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFEF3C7),
    surfaceDim: Color(0xFFE2E8F0),
    surfaceBright: Color(0xFFFFFFFF),
  );

  static const dark = HushCustomColors(
    success: Color(0xFF34D399),
    onSuccess: Color(0xFF003630),
    successContainer: Color(0xFF064E3B),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF451A03),
    warningContainer: Color(0xFF78350F),
    surfaceDim: Color(0xFF0F172A),
    surfaceBright: Color(0xFF1E293B),
  );

  static HushCustomColors of(BuildContext context) {
    return Theme.of(context).extension<HushCustomColors>() ?? light;
  }

  @override
  ThemeExtension<HushCustomColors> copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? surfaceDim,
    Color? surfaceBright,
  }) {
    return HushCustomColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceBright: surfaceBright ?? this.surfaceBright,
    );
  }

  @override
  ThemeExtension<HushCustomColors> lerp(
    covariant ThemeExtension<HushCustomColors>? other,
    double t,
  ) {
    if (other is! HushCustomColors) return this;
    return HushCustomColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
    );
  }
}
