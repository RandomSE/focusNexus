import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_prefs_snapshot.freezed.dart';

/// In-memory snapshot of user preferences loaded from per-key secure storage.
///
/// Not stored as a single JSON blob; [UserPrefsRepository] reads/writes fields
/// individually. Immutability and [copyWith] come from Freezed.
@freezed
class UserPrefsSnapshot with _$UserPrefsSnapshot {
  const UserPrefsSnapshot._();

  const factory UserPrefsSnapshot({
    @Default('light') String theme,
    @Default(14.0) double fontSize,
    @Default(false) bool useDyslexiaFont,
    @Default(false) bool highContrastMode,
    @Default(false) bool dailyAffirmations,
    @Default(false) bool aiEncouragement,
    @Default('Low') String notificationFrequency,
    @Default('Minimal') String notificationStyle,
    @Default(false) bool customizationEnabled,
    @Default(false) bool useCustomColorPalette,
    @Default(<Color>[]) List<Color> allowedColors,
    @Default('') String customizedFont,
    @Default(Colors.black87) Color customizedPrimary,
    @Default(Color(0xFFF2EFE6)) Color customizedSecondary,
    @Default('Mini-games') String rewardType,
    @Default(false) bool skipToday,
    @Default(false) bool pauseGoals,
    @Default(false) bool registrationComplete,
    @Default(false) bool onboardingCompleted,
    @Default(false) bool soundEnabled,
    @Default(0.0) double soundVolume,
    @Default('06:00') String dailyAffirmationsTime,
  }) = _UserPrefsSnapshot;

  /// Validates invariants (debug builds only). Call after constructing with
  /// non-default values if needed.
  void validate() {
    assert(fontSize > 0, 'fontSize must be positive');
    assert(
      soundVolume >= 0.0 && soundVolume <= 100.0,
      'soundVolume must be between 0 and 100',
    );
  }

  bool get isDark => theme == 'dark';

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
