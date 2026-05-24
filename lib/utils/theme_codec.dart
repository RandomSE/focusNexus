import 'dart:convert';

import 'package:flutter/material.dart';

/// Parses persisted theme JSON into [ThemeData].
ThemeData decodeThemeData(String storedTheme) {
  final Map<String, dynamic> themeMap =
      Map<String, dynamic>.from(jsonDecode(storedTheme) as Map);

  final bool isDark = themeMap['isDark'] ?? false;
  final int primaryColorValue = themeMap['primaryColor'] ?? 0xFF000000;
  final int secondaryColorValue = themeMap['secondaryColor'] ?? 0xFFFFFFFF;
  final double fontSize = (themeMap['userFontSize'] ?? 14).toDouble();
  final bool useDyslexiaFont = themeMap['useDyslexiaFont'] ?? false;

  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    primaryColor: Color(primaryColorValue),
    scaffoldBackgroundColor: Color(secondaryColorValue),
    textTheme: ThemeData.light().textTheme.apply(
          fontSizeFactor: fontSize / 14.0,
          fontFamily: useDyslexiaFont ? 'OpenDyslexic' : null,
          bodyColor: Color(primaryColorValue),
          displayColor: Color(primaryColorValue),
        ),
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
