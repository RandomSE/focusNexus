import 'package:flutter/material.dart';

import 'package:focusNexus/utils/user_prefs_codec.dart';

/// Pure UI styling from preference inputs (no storage).
class ThemeStyles {
  ThemeStyles._();

  static Color resolvePrimaryColor({
    required bool isDark,
    required bool highContrast,
    required UserPrefsSnapshot prefs,
  }) {
    if (prefs.customizationEnabled) return prefs.customizedPrimary;
    if (highContrast) return isDark ? Colors.cyan : const Color(0xFF004F52);
    return isDark ? Colors.white70 : Colors.black87;
  }

  static Color resolveSecondaryColor({
    required bool isDark,
    required bool highContrast,
    required UserPrefsSnapshot prefs,
  }) {
    if (prefs.customizationEnabled) return prefs.customizedSecondary;
    if (highContrast) return isDark ? Colors.black : const Color(0xFFF2EFE6);
    return isDark ? Colors.black : const Color(0xFFF2EFE6);
  }

  static TextStyle buildTextStyle({
    required double fontSize,
    required Color primaryColor,
    required bool useDyslexiaFont,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: primaryColor,
      fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null,
    );
  }

  static ButtonStyle buildButtonStyle(Color primaryColor, Color secondaryColor) {
    return ElevatedButton.styleFrom(backgroundColor: secondaryColor);
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
    required double fontSize,
    required bool useDyslexiaFont,
  }) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: secondaryColor,
      textTheme: scaledTextTheme(
        base: baseTheme.textTheme,
        fontSize: fontSize,
        bodyColor: primaryColor,
        useDyslexiaFont: useDyslexiaFont,
      ),
    );
  }

  static bool notificationsEnabledForFrequency(String frequency) {
    return frequency.isNotEmpty &&
        frequency != 'No notifications' &&
        (frequency == 'Low' ||
            frequency == 'Medium' ||
            frequency == 'High');
  }
}
