import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_codec.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/utils/user_prefs_codec.dart';

/// Loads and persists [ThemeData] / [ThemeBundle]; no widget state.
class ThemeRepository {
  ThemeRepository(this._prefs);

  final UserPrefsRepository _prefs;

  /// Synchronous bundle from in-memory [UserPrefsSnapshot] (for [ListenableBuilder]).
  ThemeBundle bundleFromSnapshot(UserPrefsSnapshot snap) {
    final isDark = snap.isDark;
    final primary = ThemeStyles.resolvePrimaryColor(
      isDark: isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final secondary = ThemeStyles.resolveSecondaryColor(
      isDark: isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final accent = ThemeStyles.resolveAccentColor(
      isDark: isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final themeData = ThemeStyles.buildThemeData(
      isDark: isDark,
      primaryColor: primary,
      secondaryColor: secondary,
      accentColor: accent,
      fontSize: snap.fontSize,
      useDyslexiaFont: snap.useDyslexiaFont,
    );
    return ThemeBundle(
      themeData: themeData,
      primaryColor: primary,
      secondaryColor: secondary,
      accentColor: accent,
      textStyle: ThemeStyles.buildTextStyle(
        fontSize: snap.fontSize,
        primaryColor: primary,
        useDyslexiaFont: snap.useDyslexiaFont,
      ),
      buttonStyle: ThemeStyles.buildButtonStyle(primary, secondary, accent),
    );
  }

  Future<ThemeBundle> loadScreenBundle({
    UserPrefsSnapshot? prefs,
    Duration startupDelay = Duration.zero,
  }) async {
    await CommonUtils.waitForMilliseconds(startupDelay.inMilliseconds);
    final snap = prefs ?? await _prefs.loadSnapshot();

    final isDark = snap.theme == 'dark';
    final primary = ThemeStyles.resolvePrimaryColor(
      isDark: isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final secondary = ThemeStyles.resolveSecondaryColor(
      isDark: isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final accent = ThemeStyles.resolveAccentColor(
      isDark: isDark,
      highContrast: snap.highContrastMode,
      prefs: snap,
    );
    final textStyle = ThemeStyles.buildTextStyle(
      fontSize: snap.fontSize,
      primaryColor: primary,
      useDyslexiaFont: snap.useDyslexiaFont,
    );
    final buttonStyle = ThemeStyles.buildButtonStyle(
      primary,
      secondary,
      accent,
    );

    final stored = await _prefs.readThemeData();
    final themeData =
        stored ??
        ThemeStyles.buildThemeData(
          isDark: isDark,
          primaryColor: primary,
          secondaryColor: secondary,
          accentColor: accent,
          fontSize: snap.fontSize,
          useDyslexiaFont: snap.useDyslexiaFont,
        );

    return ThemeBundle(
      themeData: themeData,
      primaryColor: primary,
      secondaryColor: secondary,
      accentColor: accent,
      textStyle: textStyle,
      buttonStyle: buttonStyle,
    );
  }

  Future<ThemeData> ensurePersistedTheme(UserPrefsSnapshot prefs) async {
    final existing = await _prefs.readThemeData();
    if (existing != null) return existing;

    final isDark = prefs.theme == 'dark';
    final primary = ThemeStyles.resolvePrimaryColor(
      isDark: isDark,
      highContrast: prefs.highContrastMode,
      prefs: prefs,
    );
    final secondary = ThemeStyles.resolveSecondaryColor(
      isDark: isDark,
      highContrast: prefs.highContrastMode,
      prefs: prefs,
    );
    final accent = ThemeStyles.resolveAccentColor(
      isDark: isDark,
      highContrast: prefs.highContrastMode,
      prefs: prefs,
    );
    final theme = ThemeStyles.buildThemeData(
      isDark: isDark,
      primaryColor: primary,
      secondaryColor: secondary,
      accentColor: accent,
      fontSize: prefs.fontSize,
      useDyslexiaFont: prefs.useDyslexiaFont,
    );
    await persistTheme(
      isDark: isDark,
      primaryColor: primary,
      secondaryColor: secondary,
      fontSize: prefs.fontSize,
      useDyslexiaFont: prefs.useDyslexiaFont,
      themeData: theme,
    );
    return theme;
  }

  Future<void> persistTheme({
    required bool isDark,
    required Color primaryColor,
    required Color secondaryColor,
    required double fontSize,
    required bool useDyslexiaFont,
    ThemeData? themeData,
  }) async {
    await _prefs.writeThemeDataJson(
      encodeThemeData(
        isDark: isDark,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        userFontSize: fontSize,
        useDyslexiaFont: useDyslexiaFont,
      ),
    );
  }

  ThemeData decodeStored(String json) => decodeThemeData(json);
}
