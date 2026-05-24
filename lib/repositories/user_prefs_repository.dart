import 'package:flutter/material.dart';

import 'package:focusNexus/repositories/achievement_counters_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/theme_codec.dart';
import 'package:focusNexus/utils/user_prefs_codec.dart';

/// Theme, accessibility, notification, and customization preferences.
class UserPrefsRepository {
  UserPrefsRepository(this._storage);

  final KeyValueStorage _storage;

  Future<String?> readString(String key) => _storage.read(key: key);

  Future<void> writeString(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<bool> readBool(String key) async {
    final raw = await _storage.read(key: key);
    return UserPrefsSnapshot.parseBool(raw);
  }

  Future<void> writeBool(String key, bool value) =>
      writeString(key, value ? 'true' : 'false');

  Future<void> deleteAll() => _storage.deleteAll();

  Future<UserPrefsSnapshot> loadSnapshot() async {
    final allowedRaw = await _storage.read(key: StorageKeys.allowedColors);
    final primaryRaw =
        await _storage.read(key: StorageKeys.customizedPrimaryColor);
    final secondaryRaw =
        await _storage.read(key: StorageKeys.customizedSecondaryColor);
    final soundVolumeRaw = await _storage.read(key: StorageKeys.soundVolume);

    return UserPrefsSnapshot(
      theme: await _storage.read(key: StorageKeys.theme) ?? 'light',
      fontSize: double.tryParse(
            await _storage.read(key: StorageKeys.fontSize) ?? '14',
          ) ??
          14.0,
      useDyslexiaFont: await readBool(StorageKeys.dyslexiaFont),
      highContrastMode: await readBool(StorageKeys.highContrast),
      dailyAffirmations: await readBool(StorageKeys.dailyAffirmations),
      aiEncouragement: await readBool(StorageKeys.aiEncouragement),
      notificationFrequency:
          await _storage.read(key: StorageKeys.notificationFrequency) ?? 'Low',
      notificationStyle:
          await _storage.read(key: StorageKeys.notificationStyle) ?? 'Minimal',
      customizationEnabled: await readBool(StorageKeys.customizationEnabled),
      useCustomColorPalette: await readBool(StorageKeys.useCustomColorPalette),
      allowedColors: UserPrefsSnapshot.decodeAllowedColors(allowedRaw),
      customizedFont:
          await _storage.read(key: StorageKeys.customizedFont) ?? '',
      customizedPrimary: primaryRaw != null
          ? Color(int.parse(primaryRaw))
          : Colors.black87,
      customizedSecondary: secondaryRaw != null
          ? Color(int.parse(secondaryRaw))
          : const Color(0xFFF2EFE6),
      rewardType:
          await _storage.read(key: StorageKeys.rewardType) ?? 'Mini-games',
      skipToday: await readBool(StorageKeys.skipToday),
      pauseGoals: _parseTriStateBool(
        await _storage.read(key: StorageKeys.pauseGoals),
      ),
      registrationComplete:
          await readBool(StorageKeys.registrationComplete) ||
              await readBool(StorageKeys.loggedIn),
      onboardingCompleted: await readBool(StorageKeys.onboardingCompleted),
      soundEnabled: await readBool(StorageKeys.soundEnabled),
      soundVolume: double.tryParse(soundVolumeRaw ?? '0') ?? 0.0,
      dailyAffirmationsTime:
          await _storage.read(key: StorageKeys.dailyAffirmationsTime) ??
              '06:00',
    );
  }

  Future<ThemeData?> readThemeData() async {
    final raw = await _storage.read(key: StorageKeys.themeData);
    if (raw == null || raw.isEmpty) return null;
    return decodeThemeData(raw);
  }

  Future<void> writeThemeDataJson(String encoded) async {
    await _storage.write(key: StorageKeys.themeData, value: encoded);
  }

  Future<List<Color>> readAllowedColors() async {
    final raw = await _storage.read(key: StorageKeys.allowedColors);
    return UserPrefsSnapshot.decodeAllowedColors(raw);
  }

  Future<void> writeAllowedColors(List<Color> colors) async {
    await _storage.write(
      key: StorageKeys.allowedColors,
      value: UserPrefsSnapshot.encodeAllowedColors(colors),
    );
  }

  Future<void> ensureAllowedColorsInitialized() async {
    final colors = await readAllowedColors();
    if (colors.isEmpty) {
      await writeAllowedColors([]);
    }
  }

  static bool _parseTriStateBool(String? raw) =>
      raw != null && raw.toLowerCase() == 'true';
}
