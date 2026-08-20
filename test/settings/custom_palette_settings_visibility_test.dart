import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/theme_repository.dart';
import 'package:focusNexus/repositories/user_prefs_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/theme_styles.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  group('Settings custom palette visibility contract', () {
    late InMemoryKeyValueStorage storage;
    late AppSettings settings;

    setUp(() async {
      storage = InMemoryKeyValueStorage();
      final prefs = UserPrefsRepository(storage);
      settings = AppSettings(prefs, ThemeRepository(prefs));
      await settings.load();
    });

    test('usesCustomizedColours false keeps dark/high-contrast path', () {
      expect(settings.usesCustomizedColours, isFalse);
      expect(ThemeStyles.usesCustomPalette(settings.snapshot), isFalse);
    });

    test('usesCustomizedColours true when reward + toggle enabled', () async {
      await settings.setRewardTypes(['Customization']);
      await settings.setCustomizationEnabled(true);
      expect(settings.usesCustomizedColours, isTrue);
      expect(ThemeStyles.usesCustomPalette(settings.snapshot), isTrue);
    });

    test('acceptCurrentEula persists version keys', () async {
      await settings.acceptCurrentEula(
        acceptedAt: DateTime.utc(2026, 8, 10, 12),
      );
      expect(settings.hasAcceptedCurrentEula, isTrue);
      expect(await storage.read(key: StorageKeys.eulaAccepted), 'true');
      expect(
        await storage.read(key: StorageKeys.eulaAcceptedVersion),
        isNotEmpty,
      );
      expect(
        await storage.read(key: StorageKeys.eulaAcceptedAt),
        '2026-08-10T12:00:00.000Z',
      );
    });
  });
}
