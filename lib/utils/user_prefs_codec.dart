import 'dart:convert';

import 'package:flutter/material.dart';

/// Typed view of user preference fields loaded from storage.
class UserPrefsSnapshot {
  const UserPrefsSnapshot({
    this.theme = 'light',
    this.fontSize = 14.0,
    this.useDyslexiaFont = false,
    this.highContrastMode = false,
    this.dailyAffirmations = false,
    this.aiEncouragement = false,
    this.rememberMe = false,
    this.notificationFrequency = 'Low',
    this.notificationStyle = 'Minimal',
    this.customizationEnabled = false,
    this.allowedColors = const [],
    this.customizedFont = '',
    this.customizedPrimary = Colors.black87,
    this.customizedSecondary = const Color(0xFFF2EFE6),
    this.rewardType = 'Mini-games',
    this.skipToday = false,
    this.pauseGoals = false,
    this.loggedIn = false,
    this.onboardingCompleted = false,
    this.soundEnabled = false,
    this.soundVolume = 0.0,
    this.dailyAffirmationsTime = '06:00',
  });

  final String theme;
  final double fontSize;
  final bool useDyslexiaFont;
  final bool highContrastMode;
  final bool dailyAffirmations;
  final bool aiEncouragement;
  final bool rememberMe;
  final String notificationFrequency;
  final String notificationStyle;
  final bool customizationEnabled;
  final List<Color> allowedColors;
  final String customizedFont;
  final Color customizedPrimary;
  final Color customizedSecondary;
  final String rewardType;
  final bool skipToday;
  final bool pauseGoals;
  final bool loggedIn;
  final bool onboardingCompleted;
  final bool soundEnabled;
  final double soundVolume;
  final String dailyAffirmationsTime;

  bool get isDark => theme == 'dark';

  UserPrefsSnapshot copyWith({
    String? theme,
    double? fontSize,
    bool? useDyslexiaFont,
    bool? highContrastMode,
    bool? dailyAffirmations,
    bool? aiEncouragement,
    bool? rememberMe,
    String? notificationFrequency,
    String? notificationStyle,
    bool? customizationEnabled,
    List<Color>? allowedColors,
    String? customizedFont,
    Color? customizedPrimary,
    Color? customizedSecondary,
    String? rewardType,
    bool? skipToday,
    bool? pauseGoals,
    bool? loggedIn,
    bool? onboardingCompleted,
    bool? soundEnabled,
    double? soundVolume,
    String? dailyAffirmationsTime,
  }) {
    return UserPrefsSnapshot(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      useDyslexiaFont: useDyslexiaFont ?? this.useDyslexiaFont,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      dailyAffirmations: dailyAffirmations ?? this.dailyAffirmations,
      aiEncouragement: aiEncouragement ?? this.aiEncouragement,
      rememberMe: rememberMe ?? this.rememberMe,
      notificationFrequency:
          notificationFrequency ?? this.notificationFrequency,
      notificationStyle: notificationStyle ?? this.notificationStyle,
      customizationEnabled:
          customizationEnabled ?? this.customizationEnabled,
      allowedColors: allowedColors ?? this.allowedColors,
      customizedFont: customizedFont ?? this.customizedFont,
      customizedPrimary: customizedPrimary ?? this.customizedPrimary,
      customizedSecondary: customizedSecondary ?? this.customizedSecondary,
      rewardType: rewardType ?? this.rewardType,
      skipToday: skipToday ?? this.skipToday,
      pauseGoals: pauseGoals ?? this.pauseGoals,
      loggedIn: loggedIn ?? this.loggedIn,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      dailyAffirmationsTime:
          dailyAffirmationsTime ?? this.dailyAffirmationsTime,
    );
  }

  static bool parseBool(String? value) => value == 'true';

  static List<Color> decodeAllowedColors(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((value) => Color(value as int)).toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeAllowedColors(List<Color> colors) {
    return jsonEncode(colors.map((c) => c.value).toList());
  }
}
