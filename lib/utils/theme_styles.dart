import 'package:flutter/material.dart';

import 'package:focusNexus/utils/user_prefs_codec.dart';

/// Pure UI styling from preference inputs (no storage).
class ThemeStyles {
  ThemeStyles._();

  static const Color _lightPrimary = Color(0xFF1D2730);
  static const Color _lightSurface = Color(0xFFF3F6F4);
  static const Color _lightAccent = Color(0xFF5B6FF6);
  static const Color _darkPrimary = Color(0xFFE5ECF4);
  static const Color _darkSurface = Color(0xFF141A22);
  static const Color _darkAccent = Color(0xFF8FA1FF);

  /// Custom palette only on the Customization reward screen when enabled there.
  static bool usesCustomPalette(UserPrefsSnapshot prefs) {
    return prefs.rewardType == 'Customization' && prefs.customizationEnabled;
  }

  static Color resolvePrimaryColor({
    required bool isDark,
    required bool highContrast,
    required UserPrefsSnapshot prefs,
  }) {
    if (usesCustomPalette(prefs)) return prefs.customizedPrimary;
    if (highContrast) return isDark ? Colors.cyan : const Color(0xFF004F52);
    return isDark ? _darkPrimary : _lightPrimary;
  }

  static Color resolveSecondaryColor({
    required bool isDark,
    required bool highContrast,
    required UserPrefsSnapshot prefs,
  }) {
    if (usesCustomPalette(prefs)) return prefs.customizedSecondary;
    if (highContrast) return isDark ? Colors.black : const Color(0xFFF2EFE6);
    return isDark ? _darkSurface : _lightSurface;
  }

  static Color resolveAccentColor({
    required bool isDark,
    required bool highContrast,
    required UserPrefsSnapshot prefs,
  }) {
    if (usesCustomPalette(prefs)) {
      return Color.alphaBlend(
        prefs.customizedPrimary.withValues(alpha: 0.16),
        prefs.customizedSecondary,
      );
    }
    if (highContrast) {
      return isDark ? Colors.cyanAccent : const Color(0xFF006C70);
    }
    return isDark ? _darkAccent : _lightAccent;
  }

  static TextStyle buildTextStyle({
    required double fontSize,
    required Color primaryColor,
    required bool useDyslexiaFont,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: primaryColor,
      fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null,
      height: useDyslexiaFont ? 1.42 : 1.32,
      leadingDistribution:
          useDyslexiaFont ? TextLeadingDistribution.even : null,
      letterSpacing: useDyslexiaFont ? 0.16 : 0.08,
    );
  }

  static ButtonStyle buildButtonStyle(
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    return outlinedActionButtonStyle(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      borderColor: accentColor,
    );
  }

  /// Filled surface + visible border so labels stay readable in light and dark mode.
  static ButtonStyle outlinedActionButtonStyle({
    required Color primaryColor,
    required Color secondaryColor,
    required Color borderColor,
    double borderWidth = 2,
    double radius = 12,
    double verticalPadding = 14,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: Color.alphaBlend(
        primaryColor.withValues(alpha: 0.08),
        secondaryColor,
      ),
      foregroundColor: primaryColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
    );
  }

  static TextStyle buttonLabelStyle(TextStyle base, Color labelColor) {
    return base.copyWith(
      color: labelColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
  }

  /// Scales typography without [TextTheme.apply] `fontSizeFactor`, which asserts on
  /// Material 3 styles that have null [TextStyle.fontSize].
  static TextTheme scaledTextTheme({
    required TextTheme base,
    required double fontSize,
    required Color bodyColor,
    required bool useDyslexiaFont,
  }) {
    const referenceSize = 14.0;
    final factor = fontSize / referenceSize;
    final fontFamily = useDyslexiaFont ? 'OpenDyslexic' : null;

    TextStyle? scale(TextStyle? style) {
      if (style == null) return null;
      final baseFontSize = style.fontSize ?? referenceSize;
      return style.copyWith(
        fontSize: baseFontSize * factor,
        color: bodyColor,
        fontFamily: fontFamily,
        height: useDyslexiaFont ? 1.35 : style.height,
        leadingDistribution:
            useDyslexiaFont ? TextLeadingDistribution.even : null,
      );
    }

    return TextTheme(
      displayLarge: scale(base.displayLarge),
      displayMedium: scale(base.displayMedium),
      displaySmall: scale(base.displaySmall),
      headlineLarge: scale(base.headlineLarge),
      headlineMedium: scale(base.headlineMedium),
      headlineSmall: scale(base.headlineSmall),
      titleLarge: scale(base.titleLarge),
      titleMedium: scale(base.titleMedium),
      titleSmall: scale(base.titleSmall),
      bodyLarge: scale(base.bodyLarge),
      bodyMedium: scale(base.bodyMedium),
      bodySmall: scale(base.bodySmall),
      labelLarge: scale(base.labelLarge),
      labelMedium: scale(base.labelMedium),
      labelSmall: scale(base.labelSmall),
    );
  }

  static ThemeData buildThemeData({
    required bool isDark,
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
    required double fontSize,
    required bool useDyslexiaFont,
  }) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    final inputPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: useDyslexiaFont ? fontSize * 0.5 : fontSize * 0.3,
    );

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: secondaryColor,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: primaryColor,
        onSecondary: secondaryColor,
        error: const Color(0xFFB3261E),
        onError: Colors.white,
        surface: secondaryColor,
        onSurface: primaryColor,
      ),
      visualDensity:
          useDyslexiaFont ? VisualDensity.standard : VisualDensity.compact,
      textTheme: scaledTextTheme(
        base: baseTheme.textTheme,
        fontSize: fontSize,
        bodyColor: primaryColor,
        useDyslexiaFont: useDyslexiaFont,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: false,
        alignLabelWithHint: !useDyslexiaFont,
        contentPadding: inputPadding,
        filled: true,
        fillColor: Color.alphaBlend(
          primaryColor.withValues(alpha: isDark ? 0.14 : 0.06),
          secondaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.8),
        ),
        floatingLabelBehavior:
            useDyslexiaFont
                ? FloatingLabelBehavior.never
                : FloatingLabelBehavior.auto,
        constraints: BoxConstraints(
          minHeight:
              useDyslexiaFont ? fontSize * 2.8 + 20 : kMinInteractiveDimension,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryColor,
        elevation: 0,
        foregroundColor: primaryColor,
        centerTitle: true,
        titleTextStyle: scaledTextTheme(
          base: baseTheme.textTheme,
          fontSize: fontSize,
          bodyColor: primaryColor,
          useDyslexiaFont: useDyslexiaFont,
        ).titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Color.alphaBlend(
          primaryColor.withValues(alpha: isDark ? 0.1 : 0.045),
          secondaryColor,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buildButtonStyle(primaryColor, secondaryColor, accentColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          backgroundColor: Color.alphaBlend(
            primaryColor.withValues(alpha: 0.08),
            secondaryColor,
          ),
          side: BorderSide(color: accentColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color.alphaBlend(
          accentColor.withValues(alpha: 0.9),
          secondaryColor,
        ),
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static bool notificationsEnabledForFrequency(String frequency) {
    return frequency.isNotEmpty &&
        frequency != 'No notifications' &&
        (frequency == 'Low' || frequency == 'Medium' || frequency == 'High');
  }
}
