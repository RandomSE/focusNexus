import 'package:flutter/material.dart';

import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/utils/color_argb.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/rewards/reward_type_selection.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/utils/user_prefs_codec.dart';

/// In-memory app preferences; UI reads via [appSettingsProvider], storage in [UserPrefsRepository].
class AppSettings {
  AppSettings(this._prefs, this._theme);

  final UserPrefsRepository _prefs;
  final ThemeRepository _theme;

  /// Called after snapshot mutations; wired by [AppSettingsNotifier].
  VoidCallback? onSnapshotChanged;

  /// Called when sound enabled/volume prefs change; wired to [SoundService].
  VoidCallback? onSoundPrefsChanged;

  UserPrefsSnapshot _snapshot = const UserPrefsSnapshot();
  bool _loaded = false;

  bool get isLoaded => _loaded;
  UserPrefsSnapshot get snapshot => _snapshot;

  double get userFontSize => _snapshot.fontSize;
  String get userTheme => _snapshot.theme;
  bool get highContrastMode => _snapshot.highContrastMode;
  bool get useDyslexiaFont => _snapshot.useDyslexiaFont;
  bool get dailyAffirmations => _snapshot.dailyAffirmations;
  bool get motivatorsDisabled => _snapshot.motivatorsDisabled;
  bool get aiEncouragement => _snapshot.aiEncouragement;
  bool get openStreakReminders => _snapshot.openStreakReminders;
  bool get skipToday => _snapshot.skipToday;
  bool get pauseGoals => _snapshot.pauseGoals;
  bool get registrationComplete => _snapshot.registrationComplete;
  bool get onboardingCompleted => _snapshot.onboardingCompleted;
  bool get soundEnabled => _snapshot.soundEnabled;
  double get soundVolume => _snapshot.soundVolume;
  bool get customizationEnabled => _snapshot.customizationEnabled;
  bool get useCustomColorPalette => _snapshot.useCustomColorPalette;
  bool get usesCustomizedColours => ThemeStyles.usesCustomPalette(_snapshot);
  bool get isCustomizationReward =>
      _snapshot.rewardTypes.contains('Customization');
  bool get hasProgressiveVisualsReward =>
      _snapshot.rewardTypes.contains('Progressive visuals');
  List<Color> get allowedColors => _snapshot.allowedColors;
  String get customizedFont => _snapshot.customizedFont;
  List<String> get rewardTypes => List.unmodifiable(_snapshot.rewardTypes);
  String get notificationStyle => _snapshot.notificationStyle;
  String get notificationFrequency => _snapshot.notificationFrequency;
  String get dailyAffirmationsTime => _snapshot.dailyAffirmationsTime;
  String get openStreakRemindersTime => _snapshot.openStreakRemindersTime;

  bool get notificationsEnabled =>
      ThemeStyles.notificationsEnabledForFrequency(notificationFrequency);

  Color get customizedPrimary => _snapshot.customizedPrimary;
  Color get customizedSecondary => _snapshot.customizedSecondary;

  Future<void> load() async {
    await _prefs.ensureAllowedColorsInitialized();
    _snapshot = await _prefs.loadSnapshot();
    await _theme.ensurePersistedTheme(_snapshot);
    final multiRaw = await _prefs.readString(StorageKeys.rewardTypes);
    if (multiRaw == null || multiRaw.trim().isEmpty) {
      await _prefs.writeString(
        StorageKeys.rewardTypes,
        RewardTypeSelection.encode(_snapshot.rewardTypes),
      );
    }
    _loaded = true;
    onSnapshotChanged?.call();
  }

  Future<void> reload() => load();

  Color primaryColor({bool? isDark, bool? highContrast}) {
    return ThemeStyles.resolvePrimaryColor(
      isDark: isDark ?? _snapshot.isDark,
      highContrast: highContrast ?? _snapshot.highContrastMode,
      prefs: _snapshot,
    );
  }

  Color secondaryColor({bool? isDark, bool? highContrast}) {
    return ThemeStyles.resolveSecondaryColor(
      isDark: isDark ?? _snapshot.isDark,
      highContrast: highContrast ?? _snapshot.highContrastMode,
      prefs: _snapshot,
    );
  }

  TextStyle textStyle({double? fontSize, Color? color, bool? dyslexia}) {
    return ThemeStyles.buildTextStyle(
      fontSize: fontSize ?? _snapshot.fontSize,
      primaryColor: color ?? primaryColor(),
      useDyslexiaFont: dyslexia ?? _snapshot.useDyslexiaFont,
    );
  }

  ButtonStyle buttonStyle({Color? primary, Color? secondary}) {
    final resolvedPrimary = primary ?? primaryColor();
    final resolvedSecondary = secondary ?? secondaryColor();
    final accent = ThemeStyles.resolveAccentColor(
      isDark: _snapshot.isDark,
      highContrast: _snapshot.highContrastMode,
      prefs: _snapshot,
    );
    return ThemeStyles.buildButtonStyle(
      resolvedPrimary,
      resolvedSecondary,
      accent,
    );
  }

  Future<void> setUserFontSize(double value) async {
    await _prefs.writeString(StorageKeys.fontSize, value.toString());
    final next = _snapshot.copyWith(fontSize: value);
    _apply(next);
    await _persistThemeFromSnapshot(next);
  }

  Future<void> setUserTheme(String value) async {
    await _prefs.writeString(StorageKeys.theme, value);
    final next = _snapshot.copyWith(theme: value);
    _apply(next);
    await _persistThemeFromSnapshot(next);
  }

  /// Replaces enabled reward types. Returns false and leaves state unchanged
  /// when [values] has no known types (min 1 required).
  Future<bool> setRewardTypes(List<String> values) async {
    final ordered = RewardTypeSelection.orderKnown(values);
    if (ordered.isEmpty) return false;

    final hadCustomization = _snapshot.rewardTypes.contains('Customization');
    final hasCustomization = ordered.contains('Customization');
    if (hadCustomization && !hasCustomization && _snapshot.customizationEnabled) {
      await setCustomizationEnabled(false);
    }

    await _prefs.writeString(
      StorageKeys.rewardTypes,
      RewardTypeSelection.encode(ordered),
    );
    final next = _snapshot.copyWith(rewardTypes: ordered);
    _apply(next);
    await _persistThemeFromSnapshot(next);
    return true;
  }

  Future<void> setCustomizationEnabled(bool value) async {
    await _prefs.writeBool(StorageKeys.customizationEnabled, value);
    final next = _snapshot.copyWith(customizationEnabled: value);
    _apply(next);
    await _persistThemeFromSnapshot(next);
  }

  Future<void> setUseCustomColorPalette(bool value) async {
    await _prefs.writeBool(StorageKeys.useCustomColorPalette, value);
    final next = _snapshot.copyWith(useCustomColorPalette: value);
    _apply(next);
    await _persistThemeFromSnapshot(next);
  }

  Future<void> setCustomizedColors({
    required Color primaryColor,
    required Color secondaryColor,
    bool persistPalette = true,
  }) async {
    await _prefs.writeString(
      StorageKeys.customizedPrimaryColor,
      colorToArgb32(primaryColor).toString(),
    );
    await _prefs.writeString(
      StorageKeys.customizedSecondaryColor,
      colorToArgb32(secondaryColor).toString(),
    );
    var next = _snapshot.copyWith(
      customizedPrimary: primaryColor,
      customizedSecondary: secondaryColor,
    );
    _apply(next);
    await _persistThemeFromSnapshot(next);
  }

  Future<void> setNotificationStyle(String value) async {
    await _prefs.writeString(StorageKeys.notificationStyle, value);
    _apply(_snapshot.copyWith(notificationStyle: value));
  }

  Future<void> setNotificationFrequency(String value) async {
    await _prefs.writeString(StorageKeys.notificationFrequency, value);
    _apply(_snapshot.copyWith(notificationFrequency: value));
  }

  Future<void> setRegistrationComplete(bool value) async {
    await _prefs.writeBool(StorageKeys.registrationComplete, value);
    _apply(_snapshot.copyWith(registrationComplete: value));
  }

  /// Persists notification/reward choices from the setup form and marks registration done.
  Future<void> completeRegistration({
    required String notificationFrequency,
    required String notificationStyle,
    required List<String> rewardTypes,
  }) async {
    await _prefs.writeString(StorageKeys.theme, 'light');
    await setNotificationFrequency(notificationFrequency);
    await setNotificationStyle(notificationStyle);
    await setRewardTypes(rewardTypes);
    await setRegistrationComplete(true);
    await setOnboardingCompleted(false);
  }

  Future<void> setHighContrastMode(bool value) async {
    await _prefs.writeBool(StorageKeys.highContrast, value);
    final next = _snapshot.copyWith(highContrastMode: value);
    _apply(next);
    await _persistThemeFromSnapshot(next);
  }

  Future<void> setUseDyslexiaFont(bool value) async {
    await _prefs.writeBool(StorageKeys.dyslexiaFont, value);
    final next = _snapshot.copyWith(useDyslexiaFont: value);
    _apply(next);
    await _persistThemeFromSnapshot(next);
  }

  Future<void> setAiEncouragement(bool value) async {
    await _prefs.writeBool(StorageKeys.aiEncouragement, value);
    _apply(_snapshot.copyWith(aiEncouragement: value));
  }

  Future<void> setDailyAffirmations(bool value) async {
    await _prefs.writeBool(StorageKeys.dailyAffirmations, value);
    _apply(_snapshot.copyWith(dailyAffirmations: value));
  }

  Future<void> setMotivatorsDisabled(bool value) async {
    await _prefs.writeBool(StorageKeys.motivatorsDisabled, value);
    _apply(_snapshot.copyWith(motivatorsDisabled: value));
  }

  Future<void> setOpenStreakReminders(bool value) async {
    await _prefs.writeBool(StorageKeys.openStreakReminders, value);
    _apply(_snapshot.copyWith(openStreakReminders: value));
  }

  Future<void> setSkipToday(bool value) async {
    await _prefs.writeBool(StorageKeys.skipToday, value);
    _apply(_snapshot.copyWith(skipToday: value));
  }

  Future<void> setPauseGoals(bool value) async {
    await _prefs.writeBool(StorageKeys.pauseGoals, value);
    _apply(_snapshot.copyWith(pauseGoals: value));
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.writeBool(StorageKeys.onboardingCompleted, value);
    _apply(_snapshot.copyWith(onboardingCompleted: value));
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.writeBool(StorageKeys.soundEnabled, value);
    _apply(_snapshot.copyWith(soundEnabled: value));
    onSoundPrefsChanged?.call();
  }

  Future<void> setSoundVolume(int value) async {
    final clamped = value.clamp(0, 100);
    await _prefs.writeString(StorageKeys.soundVolume, clamped.toString());
    _apply(_snapshot.copyWith(soundVolume: clamped.toDouble()));
    onSoundPrefsChanged?.call();
  }

  Future<void> setDailyAffirmationsTime(String value) async {
    await _prefs.writeString(StorageKeys.dailyAffirmationsTime, value);
    _apply(_snapshot.copyWith(dailyAffirmationsTime: value));
  }

  Future<void> setOpenStreakRemindersTime(String value) async {
    await _prefs.writeString(StorageKeys.openStreakRemindersTime, value);
    _apply(_snapshot.copyWith(openStreakRemindersTime: value));
  }

  Future<void> setAllowedColors(Color value) async {
    if (_snapshot.allowedColors.contains(value)) return;
    final next = List<Color>.from(_snapshot.allowedColors)..add(value);
    await _prefs.writeAllowedColors(next);
    _apply(_snapshot.copyWith(allowedColors: next));
  }

  Future<void> setThemeData({
    bool? isDark,
    bool? highContrastMode,
    Color? primaryColor,
    Color? secondaryColor,
    double? userFontSize,
    bool? useDyslexiaFont,
  }) async {
    var next = _snapshot;
    if (highContrastMode != null) {
      next = next.copyWith(highContrastMode: highContrastMode);
    }
    if (userFontSize != null) {
      next = next.copyWith(fontSize: userFontSize);
    }
    if (useDyslexiaFont != null) {
      next = next.copyWith(useDyslexiaFont: useDyslexiaFont);
    }
    if (primaryColor != null) {
      next = next.copyWith(customizedPrimary: primaryColor);
    }
    if (secondaryColor != null) {
      next = next.copyWith(customizedSecondary: secondaryColor);
    }
    if (isDark != null) {
      next = next.copyWith(theme: isDark ? 'dark' : 'light');
    }
    _apply(next);
    await _persistThemeFromSnapshot(
      next,
      primaryOverride: primaryColor,
      secondaryOverride: secondaryColor,
    );
  }

  Future<void> clearAll() async {
    await _prefs.deleteAll();
    await applyDefaultPreferences();
  }

  /// Restores default prefs after [AppRepositories.wipeAllUserData] cleared storage.
  Future<void> applyDefaultPreferences() async {
    _snapshot = const UserPrefsSnapshot();
    await setUserFontSize(14.0);
    await setUserTheme('light');
    await setRewardTypes(['Mini-games']);
    await setNotificationStyle('Minimal');
    await setNotificationFrequency('Medium');
    await setHighContrastMode(false);
    await setUseDyslexiaFont(false);
    await setAiEncouragement(false);
    await setDailyAffirmations(false);
    await setMotivatorsDisabled(false);
    await setOpenStreakReminders(false);
    await setOpenStreakRemindersTime('20:00');
    await setSkipToday(false);
    await setPauseGoals(false);
    await setRegistrationComplete(false);
    await setOnboardingCompleted(false);
    await setSoundEnabled(true);
    await setSoundVolume(100);
    await setCustomizationEnabled(false);
    await setUseCustomColorPalette(false);
    await _prefs.writeAllowedColors([]);
    await _prefs.writeString(StorageKeys.customizedFont, '');
  }

  void _apply(UserPrefsSnapshot next) {
    _snapshot = next;
    onSnapshotChanged?.call();
  }

  Future<void> _persistThemeFromSnapshot(
    UserPrefsSnapshot snap, {
    Color? primaryOverride,
    Color? secondaryOverride,
  }) async {
    final isDark = snap.isDark;
    final highContrast =
        ThemeStyles.usesCustomPalette(snap) ? false : snap.highContrastMode;
    final primary =
        primaryOverride ??
        ThemeStyles.resolvePrimaryColor(
          isDark: isDark,
          highContrast: highContrast,
          prefs: snap,
        );
    final secondary =
        secondaryOverride ??
        ThemeStyles.resolveSecondaryColor(
          isDark: isDark,
          highContrast: highContrast,
          prefs: snap,
        );
    await _theme.persistTheme(
      isDark: isDark,
      primaryColor: primary,
      secondaryColor: secondary,
      fontSize: snap.fontSize,
      useDyslexiaFont: snap.useDyslexiaFont,
    );
  }
}
