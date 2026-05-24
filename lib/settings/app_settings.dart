import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/utils/user_prefs_codec.dart';

/// In-memory app preferences; UI reads this, storage lives in [UserPrefsRepository].
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs, this._theme);

  final UserPrefsRepository _prefs;
  final ThemeRepository _theme;

  UserPrefsSnapshot _snapshot = const UserPrefsSnapshot();
  bool _loaded = false;

  bool get isLoaded => _loaded;
  UserPrefsSnapshot get snapshot => _snapshot;

  double get userFontSize => _snapshot.fontSize;
  String get userTheme => _snapshot.theme;
  bool get rememberMe => _snapshot.rememberMe;
  bool get highContrastMode => _snapshot.highContrastMode;
  bool get useDyslexiaFont => _snapshot.useDyslexiaFont;
  bool get dailyAffirmations => _snapshot.dailyAffirmations;
  bool get aiEncouragement => _snapshot.aiEncouragement;
  bool get skipToday => _snapshot.skipToday;
  bool get pauseGoals => _snapshot.pauseGoals;
  bool get loggedIn => _snapshot.loggedIn;
  bool get onboardingCompleted => _snapshot.onboardingCompleted;
  bool get soundEnabled => _snapshot.soundEnabled;
  double get soundVolume => _snapshot.soundVolume;
  bool get customizationEnabled => _snapshot.customizationEnabled;
  List<Color> get allowedColors => _snapshot.allowedColors;
  String get customizedFont => _snapshot.customizedFont;
  String get rewardType => _snapshot.rewardType;
  String get notificationStyle => _snapshot.notificationStyle;
  String get notificationFrequency => _snapshot.notificationFrequency;
  String get dailyAffirmationsTime => _snapshot.dailyAffirmationsTime;

  bool get notificationsEnabled =>
      ThemeStyles.notificationsEnabledForFrequency(notificationFrequency);

  Color get customizedPrimary => _snapshot.customizedPrimary;
  Color get customizedSecondary => _snapshot.customizedSecondary;

  Future<void> load() async {
    await _prefs.ensureAllowedColorsInitialized();
    _snapshot = await _prefs.loadSnapshot();
    await _theme.ensurePersistedTheme(_snapshot);
    _loaded = true;
    notifyListeners();
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
    return ThemeStyles.buildButtonStyle(
      primary ?? primaryColor(),
      secondary ?? secondaryColor(),
    );
  }

  Future<void> setUserFontSize(double value) async {
    await _prefs.writeString(StorageKeys.fontSize, value.toString());
    _apply(_snapshot.copyWith(fontSize: value));
  }

  Future<void> setUserTheme(String value) async {
    await _prefs.writeString(StorageKeys.theme, value);
    _apply(_snapshot.copyWith(theme: value));
  }

  Future<void> setRewardType(String value) async {
    final previous = _snapshot.rewardType;
    if (previous == 'Customization' && value != 'Customization') {
      await setCustomizationEnabled(false);
    } else if (previous != 'Customization' && value == 'Customization') {
      await setCustomizationEnabled(true);
    }
    await _prefs.writeString(StorageKeys.rewardType, value);
    _apply(_snapshot.copyWith(rewardType: value));
  }

  Future<void> setCustomizationEnabled(bool value) async {
    await _prefs.writeBool(StorageKeys.customizationEnabled, value);
    _apply(_snapshot.copyWith(customizationEnabled: value));
  }

  Future<void> setCustomizedColors({
    required Color primaryColor,
    required Color secondaryColor,
  }) async {
    await _prefs.writeString(
      StorageKeys.customizedPrimaryColor,
      primaryColor.value.toString(),
    );
    await _prefs.writeString(
      StorageKeys.customizedSecondaryColor,
      secondaryColor.value.toString(),
    );
    final next = _snapshot.copyWith(
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

  Future<void> setRememberMe(bool value) async {
    await _prefs.writeBool(StorageKeys.rememberMe, value);
    _apply(_snapshot.copyWith(rememberMe: value));
  }

  Future<void> setLoggedIn(bool value) async {
    await _prefs.writeBool(StorageKeys.loggedIn, value);
    _apply(_snapshot.copyWith(loggedIn: value));
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
  }

  Future<void> setSoundVolume(double value) async {
    await _prefs.writeString(StorageKeys.soundVolume, value.toString());
    _apply(_snapshot.copyWith(soundVolume: value));
  }

  Future<void> setDailyAffirmationsTime(String value) async {
    await _prefs.writeString(StorageKeys.dailyAffirmationsTime, value);
    _apply(_snapshot.copyWith(dailyAffirmationsTime: value));
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
    var next = _snapshot.copyWith(
      highContrastMode: highContrastMode,
      fontSize: userFontSize,
      useDyslexiaFont: useDyslexiaFont,
      customizedPrimary: primaryColor,
      customizedSecondary: secondaryColor,
    );
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
    _snapshot = const UserPrefsSnapshot();
    await setUserFontSize(14.0);
    await setUserTheme('light');
    await setRewardType('Mini-games');
    await setNotificationStyle('Minimal');
    await setNotificationFrequency('Medium');
    await setRememberMe(false);
    await setHighContrastMode(false);
    await setUseDyslexiaFont(false);
    await setAiEncouragement(false);
    await setDailyAffirmations(false);
    await setSkipToday(false);
    await setPauseGoals(false);
    await setLoggedIn(false);
    await setOnboardingCompleted(false);
    await setSoundEnabled(false);
    await setSoundVolume(0.0);
    await setCustomizationEnabled(false);
    await _prefs.writeAllowedColors([]);
    await _prefs.writeString(StorageKeys.customizedFont, '');
  }

  void _apply(UserPrefsSnapshot next) {
    _snapshot = next;
    notifyListeners();
  }

  Future<void> _persistThemeFromSnapshot(
    UserPrefsSnapshot snap, {
    Color? primaryOverride,
    Color? secondaryOverride,
  }) async {
    final isDark = snap.isDark;
    final primary = primaryOverride ??
        ThemeStyles.resolvePrimaryColor(
          isDark: isDark,
          highContrast: snap.highContrastMode,
          prefs: snap,
        );
    final secondary = secondaryOverride ??
        ThemeStyles.resolveSecondaryColor(
          isDark: isDark,
          highContrast: snap.highContrastMode,
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
