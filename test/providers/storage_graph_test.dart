import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/bootstrap/app_bootstrap.dart';
import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  tearDown(() {
    GoalNotifier.resetForTesting();
    AchievementTrackingVariables.resetForTesting();
  });

  group('unified KeyValueStorage graph', () {
    test('single override wires repos, GoalNotifier, and tracking', () async {
      final storage = InMemoryKeyValueStorage(
        initial: {
          StorageKeys.aiEncouragement: 'true',
          StorageKeys.dailyAffirmations: 'false',
        },
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);

      container.read(goalNotifierWiringProvider);
      container.read(achievementTrackingWiringProvider);

      expect(identical(container.read(appRepositoriesProvider).storage, storage), isTrue);

      await GoalNotifier.checkAiEncouragement();
      expect(GoalNotifier.isAiEncouragementEnabled, isTrue);

      await AchievementTrackingVariables().update(totalGoalsCreated: 5);
      expect(storage.snapshot[StorageKeys.achievementTrackingData], isNotNull);
      expect(
        storage.snapshot[StorageKeys.achievementTrackingData]!.contains('"totalGoalsCreated":5'),
        isTrue,
      );
    });

    test('ensureAppReady binds all storage consumers', () async {
      final storage = InMemoryKeyValueStorage();
      final container = await createTestContainer(storage: storage, bootstrap: true);
      addTearDown(container.dispose);

      expect(() => GoalNotifier.storage, returnsNormally);
      expect(() => AchievementTrackingVariables(), returnsNormally);
      expect(storage.snapshot.containsKey(StorageKeys.achievementTrackingData), isTrue);
    });

    test('GoalNotifier.storage throws when storage is unbound', () {
      expect(() => GoalNotifier.storage, throwsStateError);
    });

    test('AchievementTrackingVariables factory throws when storage is unbound', () {
      expect(() => AchievementTrackingVariables(), throwsStateError);
    });
  });

  group('storage construction guardrails', () {
    test('lib/ only imports flutter_secure_storage in impl file', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final offenders = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = entity.path.replaceAll('\\', '/');
        if (normalized.endsWith('flutter_secure_key_value_storage.dart')) continue;

        final content = entity.readAsStringSync();
        if (content.contains("import 'package:flutter_secure_storage/") ||
            content.contains('import "package:flutter_secure_storage/')) {
          offenders.add(normalized);
        }
      }

      expect(offenders, isEmpty, reason: 'Unexpected secure-storage imports: $offenders');
    });

    test('no stray const FlutterSecureKeyValueStorage outside allowlist', () {
      const allowlist = {
        'lib/providers/key_value_storage_provider.dart',
        'lib/services/storage/flutter_secure_key_value_storage.dart',
      };

      final offenders = <String>[];
      final libDir = Directory('lib');
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = entity.path.replaceAll('\\', '/');
        if (allowlist.contains(normalized)) continue;

        final content = entity.readAsStringSync();
        if (content.contains('const FlutterSecureKeyValueStorage(')) {
          offenders.add(normalized);
        }
      }

      expect(offenders, isEmpty, reason: 'Unexpected constructions: $offenders');
    });
  });
}
