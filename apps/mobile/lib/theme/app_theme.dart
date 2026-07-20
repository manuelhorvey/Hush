import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import '../core/design_system/theme/hush_theme_extensions.dart';

class HushTheme {
  HushTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: HushColors.primary,
          onPrimary: HushColors.onPrimary,
          primaryContainer: HushColors.primaryContainer,
          onPrimaryContainer: HushColors.onPrimaryContainer,
          secondary: HushColors.secondary,
          onSecondary: HushColors.onSecondary,
          secondaryContainer: HushColors.secondaryContainer,
          onSecondaryContainer: HushColors.onSecondaryContainer,
          surface: HushColors.surface,
          onSurface: HushColors.onSurface,
          surfaceContainerHighest: HushColors.surfaceContainer,
          onSurfaceVariant: HushColors.onSurfaceVariant,
          error: HushColors.error,
          onError: HushColors.onError,
          errorContainer: HushColors.errorContainer,
          outline: HushColors.outline,
          outlineVariant: HushColors.outlineVariant,
        ),
        scaffoldBackgroundColor: HushColors.background,
        textTheme: HushTypography.textTheme,
        dividerTheme: DividerThemeData(
          color: HushColors.outlineVariant,
          thickness: 1,
          space: 1,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: HushColors.surface,
          foregroundColor: HushColors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: HushTypography.textTheme.titleLarge?.copyWith(
            color: HushColors.onSurface,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: HushColors.surface,
          indicatorColor: HushColors.primaryContainer,
        ),
        cardTheme: CardThemeData(
          color: HushColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
            side: BorderSide(color: HushColors.outlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: HushColors.primary,
            foregroundColor: HushColors.onPrimary,
            minimumSize: const Size.fromHeight(HushSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(HushSpacing.borderRadiusMd),
            ),
            textStyle: HushTypography.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: HushColors.primary,
            minimumSize: const Size.fromHeight(HushSpacing.buttonHeight),
            side: BorderSide(color: HushColors.outline),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(HushSpacing.borderRadiusMd),
            ),
            textStyle: HushTypography.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: HushColors.primary,
            textStyle: HushTypography.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: HushColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: HushSpacing.inputHorizontal,
            vertical: HushSpacing.inputVertical,
          ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide: BorderSide(color: HushColors.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide: BorderSide(color: HushColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide:
                BorderSide(color: HushColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide: BorderSide(color: HushColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide:
                BorderSide(color: HushColors.error, width: 2),
          ),
          labelStyle: HushTypography.textTheme.bodyMedium?.copyWith(
            color: HushColors.onSurfaceVariant,
          ),
          hintStyle: HushTypography.textTheme.bodyMedium?.copyWith(
            color: HushColors.onSurfaceVariant,
          ),
          errorStyle: HushTypography.textTheme.bodySmall?.copyWith(
            color: HushColors.error,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: HushColors.primary,
          foregroundColor: HushColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusLg),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: HushColors.surfaceContainer,
          labelStyle: HushTypography.textTheme.labelMedium,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusSm),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: HushColors.onSurface,
          contentTextStyle: HushTypography.textTheme.bodyMedium?.copyWith(
            color: HushColors.surface,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusSm),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: HushColors.background,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusLg),
          ),
        ),
        extensions: const [HushCustomColors.light],
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: HushColors.darkPrimary,
          onPrimary: HushColors.darkOnPrimary,
          primaryContainer: HushColors.darkPrimaryContainer,
          onPrimaryContainer: HushColors.darkOnPrimaryContainer,
          secondary: HushColors.darkSecondary,
          onSecondary: HushColors.darkOnSecondary,
          secondaryContainer: HushColors.darkSecondaryContainer,
          onSecondaryContainer: HushColors.darkOnSecondaryContainer,
          surface: HushColors.darkSurface,
          onSurface: HushColors.darkOnSurface,
          surfaceContainerHighest: HushColors.darkSurfaceContainer,
          onSurfaceVariant: HushColors.darkOnSurfaceVariant,
          error: HushColors.darkError,
          onError: HushColors.darkOnError,
          errorContainer: HushColors.darkErrorContainer,
          outline: HushColors.darkOutline,
          outlineVariant: HushColors.darkOutlineVariant,
        ),
        scaffoldBackgroundColor: HushColors.darkBackground,
        textTheme: HushTypography.textTheme.apply(
          bodyColor: HushColors.darkOnSurface,
          displayColor: HushColors.darkOnSurface,
        ),
        dividerTheme: DividerThemeData(
          color: HushColors.darkOutlineVariant,
          thickness: 1,
          space: 1,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: HushColors.darkSurface,
          foregroundColor: HushColors.darkOnSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: HushTypography.textTheme.titleLarge?.copyWith(
            color: HushColors.darkOnSurface,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: HushColors.darkSurface,
          indicatorColor: HushColors.darkPrimaryContainer,
        ),
        cardTheme: CardThemeData(
          color: HushColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
            side: BorderSide(color: HushColors.darkOutlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: HushColors.darkPrimary,
            foregroundColor: HushColors.darkOnPrimary,
            minimumSize: const Size.fromHeight(HushSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(HushSpacing.borderRadiusMd),
            ),
            textStyle: HushTypography.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: HushColors.darkPrimary,
            minimumSize: const Size.fromHeight(HushSpacing.buttonHeight),
            side: BorderSide(color: HushColors.darkOutline),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(HushSpacing.borderRadiusMd),
            ),
            textStyle: HushTypography.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: HushColors.darkPrimary,
            textStyle: HushTypography.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: HushColors.darkSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: HushSpacing.inputHorizontal,
            vertical: HushSpacing.inputVertical,
          ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide: BorderSide(color: HushColors.darkOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide: BorderSide(color: HushColors.darkOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide:
                BorderSide(color: HushColors.darkPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide: BorderSide(color: HushColors.darkError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusMd),
            borderSide:
                BorderSide(color: HushColors.darkError, width: 2),
          ),
          labelStyle: HushTypography.textTheme.bodyMedium?.copyWith(
            color: HushColors.darkOnSurfaceVariant,
          ),
          hintStyle: HushTypography.textTheme.bodyMedium?.copyWith(
            color: HushColors.darkOnSurfaceVariant,
          ),
          errorStyle: HushTypography.textTheme.bodySmall?.copyWith(
            color: HushColors.darkError,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: HushColors.darkPrimary,
          foregroundColor: HushColors.darkOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusLg),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: HushColors.darkSurfaceContainer,
          labelStyle: HushTypography.textTheme.labelMedium,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusSm),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: HushColors.darkOnSurface,
          contentTextStyle: HushTypography.textTheme.bodyMedium?.copyWith(
            color: HushColors.darkBackground,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusSm),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: HushColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(HushSpacing.borderRadiusLg),
          ),
        ),
        extensions: const [HushCustomColors.dark],
      );
}
