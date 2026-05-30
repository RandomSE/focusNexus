import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:focusNexus/utils/color_argb.dart';
import 'package:focusNexus/utils/theme_styles.dart';
part 'theme_persisted_snapshot.freezed.dart';
part 'theme_persisted_snapshot.g.dart';

/// Persisted theme fields (secure storage JSON via [ThemeCodec]).
@freezed
class ThemePersistedSnapshot with _$ThemePersistedSnapshot {
  const ThemePersistedSnapshot._();

  const factory ThemePersistedSnapshot({
    @Default(false) bool isDark,
    @Default(0xFF000000) int primaryColorArgb,
    @Default(0xFFFFFFFF) int secondaryColorArgb,
    @Default(14.0) double userFontSize,
    @Default(false) bool useDyslexiaFont,
  }) = _ThemePersistedSnapshot;

  factory ThemePersistedSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ThemePersistedSnapshotFromJson(json);

  factory ThemePersistedSnapshot.fromThemeData(ThemeData theme) {
    return ThemePersistedSnapshot(
      isDark: theme.brightness == Brightness.dark,
      primaryColorArgb: colorToArgb32(theme.colorScheme.primary),
      secondaryColorArgb: colorToArgb32(theme.colorScheme.surface),
      userFontSize: theme.textTheme.bodyMedium?.fontSize ?? 14.0,
      useDyslexiaFont: theme.textTheme.bodyMedium?.fontFamily == 'OpenDyslexic',
    );
  }
  ThemeData toThemeData() {
    return ThemeStyles.buildThemeData(
      isDark: isDark,
      primaryColor: Color(primaryColorArgb),
      secondaryColor: Color(secondaryColorArgb),
      fontSize: userFontSize,
      useDyslexiaFont: useDyslexiaFont,
    );
  }

  void validate() {
    assert(userFontSize > 0, 'userFontSize must be positive');
  }
}
