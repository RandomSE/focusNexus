import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:focusNexus/models/theme_persisted_snapshot.dart';

export 'package:focusNexus/models/theme_persisted_snapshot.dart';

/// Parses persisted theme JSON into [ThemeData].
ThemeData decodeThemeData(String storedTheme) {
  final map = Map<String, dynamic>.from(jsonDecode(storedTheme) as Map);
  final snapshot = ThemePersistedSnapshot.fromJson(map);
  snapshot.validate();
  return snapshot.toThemeData();
}

String encodeThemeData({
  required bool isDark,
  required Color primaryColor,
  required Color secondaryColor,
  required double userFontSize,
  required bool useDyslexiaFont,
}) {
  final snapshot = ThemePersistedSnapshot(
    isDark: isDark,
    primaryColorArgb: primaryColor.value,
    secondaryColorArgb: secondaryColor.value,
    userFontSize: userFontSize,
    useDyslexiaFont: useDyslexiaFont,
  );
  snapshot.validate();
  return jsonEncode(snapshot.toJson());
}
