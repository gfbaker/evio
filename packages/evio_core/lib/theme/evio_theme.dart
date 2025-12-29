import 'package:flutter/material.dart';
import 'tokens/colors.dart';
import 'tokens/typography.dart';
import 'tokens/spacing.dart';
import 'tokens/radius.dart';

// Builder de ThemeData para Evio Club
abstract class EvioTheme {
  // Tema oscuro (default para evio_fan)
  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    background: EvioDarkColors.background,
    surface: EvioDarkColors.surface,
    primary: EvioDarkColors.primary,
    primaryForeground: EvioDarkColors.primaryForeground,
    secondary: EvioDarkColors.secondary,
    secondaryForeground: EvioDarkColors.secondaryForeground,
    muted: EvioDarkColors.muted,
    mutedForeground: EvioDarkColors.mutedForeground,
    accent: EvioDarkColors.accent,
    accentForeground: EvioDarkColors.accentForeground,
    foreground: EvioDarkColors.foreground,
    border: EvioDarkColors.border,
    input: EvioDarkColors.inputBackground,
    card: EvioDarkColors.card,
    cardForeground: EvioDarkColors.cardForeground,
    destructive: EvioDarkColors.destructive,
    destructiveForeground: EvioDarkColors.destructiveForeground,
    success: EvioDarkColors.success,
    warning: EvioDarkColors.warning,
    error: EvioDarkColors.error,
  );

  // Tema claro (default para evio_admin)
  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    background: EvioLightColors.background,
    surface: EvioLightColors.surface,
    primary: EvioLightColors.primary,
    primaryForeground: EvioLightColors.primaryForeground,
    secondary: EvioLightColors.secondary,
    secondaryForeground: EvioLightColors.secondaryForeground,
    muted: EvioLightColors.muted,
    mutedForeground: EvioLightColors.mutedForeground,
    accent: EvioLightColors.accent,
    accentForeground: EvioLightColors.accentForeground,
    foreground: EvioLightColors.foreground,
    border: EvioLightColors.border,
    input: EvioLightColors.inputBackground,
    card: EvioLightColors.card,
    cardForeground: EvioLightColors.cardForeground,
    destructive: EvioLightColors.destructive,
    destructiveForeground: EvioLightColors.destructiveForeground,
    success: EvioLightColors.success,
    warning: EvioLightColors.warning,
    error: EvioLightColors.error,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color primaryForeground,
    required Color secondary,
    required Color secondaryForeground,
    required Color muted,
    required Color mutedForeground,
    required Color accent,
    required Color accentForeground,
    required Color foreground,
    required Color border,
    required Color input,
    required Color card,
    required Color cardForeground,
    required Color destructive,
    required Color destructiveForeground,
    required Color success,
    required Color warning,
    required Color error,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: EvioTypography.fontFamily,

      // Colors
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        error: error,
        onError: destructiveForeground,
        surface: surface,
        onSurface: foreground,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: EvioTypography.titleMedium.copyWith(color: foreground),
      ),

      // Card
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: EvioRadius.cardRadius,
          side: BorderSide(
            color: border,
            width: 0.5,
          ), // Cambiar width de 1 a 0.5
        ),
        margin: EdgeInsets.zero,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        contentPadding: EdgeInsets.symmetric(
          horizontal: EvioSpacing.md,
          vertical: EvioSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: EvioRadius.inputRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: EvioRadius.inputRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: EvioRadius.inputRadius,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: EvioRadius.inputRadius,
          borderSide: BorderSide(color: error),
        ),
        hintStyle: EvioTypography.bodyMedium.copyWith(color: mutedForeground),
        labelStyle: EvioTypography.bodyMedium.copyWith(color: mutedForeground),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.lg,
            vertical: EvioSpacing.sm,
          ),
          minimumSize: Size(0, EvioSpacing.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: EvioRadius.buttonRadius),
          textStyle: EvioTypography.button,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.lg,
            vertical: EvioSpacing.sm,
          ),
          minimumSize: Size(0, EvioSpacing.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: EvioRadius.buttonRadius),
          side: BorderSide(color: border),
          textStyle: EvioTypography.button,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.md,
            vertical: EvioSpacing.sm,
          ),
          minimumSize: Size(0, EvioSpacing.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: EvioRadius.buttonRadius),
          textStyle: EvioTypography.button,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      // Icon
      iconTheme: IconThemeData(color: foreground, size: EvioSpacing.iconSize),

      // Text
      textTheme: TextTheme(
        displayLarge: EvioTypography.displayLarge.copyWith(color: foreground),
        displayMedium: EvioTypography.displayMedium.copyWith(color: foreground),
        titleLarge: EvioTypography.titleLarge.copyWith(color: foreground),
        titleMedium: EvioTypography.titleMedium.copyWith(color: foreground),
        titleSmall: EvioTypography.titleSmall.copyWith(color: foreground),
        bodyLarge: EvioTypography.bodyLarge.copyWith(color: foreground),
        bodyMedium: EvioTypography.bodyMedium.copyWith(color: foreground),
        bodySmall: EvioTypography.bodySmall.copyWith(color: foreground),
        labelLarge: EvioTypography.labelLarge.copyWith(color: foreground),
        labelMedium: EvioTypography.labelMedium.copyWith(color: foreground),
        labelSmall: EvioTypography.labelSmall.copyWith(color: foreground),
      ),
    );
  }
}
