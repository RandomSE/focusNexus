import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/key_value_storage_provider.dart';
import 'package:focusNexus/services/ai_chat_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/notifier.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  tearDown(() {
    GoalNotifier.resetForTesting();
  });

  group('app services providers', () {
    test('goalNotifierWiring binds scoped storage', () async {
      final storage = InMemoryKeyValueStorage(
        initial: {StorageKeys.aiEncouragement: 'true'},
      );
      final container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);

      container.read(goalNotifierWiringProvider);
      await GoalNotifier.checkAiEncouragement();

      expect(GoalNotifier.isAiEncouragementEnabled, isTrue);
    });

    test('achievementService constructs from repositories scope', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      container.read(appServicesWiredProvider);

      expect(container.read(achievementServiceProvider), isNotNull);
      expect(container.read(soundServiceProvider), isNotNull);
    });

    test('appServicesWired constructs achievement, sound, and wiring', () {
      final container = ProviderContainer(
        overrides: [
          keyValueStorageProvider.overrideWithValue(
            InMemoryKeyValueStorage(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(appServicesWiredProvider);

      expect(container.read(achievementServiceProvider), isNotNull);
      expect(container.read(soundServiceProvider), isNotNull);
    });

    test('aiChatService defaults to Groq implementation', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      expect(
        container.read(aiChatServiceProvider),
        isA<GroqAiChatService>(),
      );
    });
  });
}
