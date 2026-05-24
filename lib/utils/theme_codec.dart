import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:focusNexus/utils/theme_styles.dart';

/// Parses persisted theme JSON into [ThemeData].
ThemeData decodeThemeData(String storedTheme) {
  final Map<String, dynamic> themeMap =
      Map<String, dynamic>.from(jsonDecode(storedTheme) as Map);

  final bool isDark = themeMap['isDark'] ?? false;
  final primaryColor = Color(themeMap['primaryColor'] as int? ?? 0xFF000000);
  final secondaryColor =
      Color(themeMap['secondaryColor'] as int? ?? 0xFFFFFFFF);
  final double fontSize = (themeMap['userFontSize'] ?? 14).toDouble();
  final bool useDyslexiaFont = themeMap['useDyslexiaFont'] as bool? ?? false;

  return ThemeStyles.buildThemeData(
    isDark: isDark,
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    fontSize: fontSize,
    useDyslexiaFont: useDyslexiaFont,
  );
}

String encodeThemeData({
  required bool isDark,
  required Color primaryColor,
  required Color secondaryColor,
  required double userFontSize,
  required bool useDyslexiaFont,
}) {
  return jsonEncode({
    'isDark': isDark,
    'primaryColor': primaryColor.value,
    'secondaryColor': secondaryColor.value,
    'userFontSize': userFontSize,
    'useDyslexiaFont': useDyslexiaFont,
  });
}
