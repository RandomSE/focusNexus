import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  group('screen UI providers', () {
    late ProviderContainer container;

    setUp(() async {
      container = await createTestContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('aiChatDisclaimerAccepted starts false and accepts', () {
      expect(container.read(aiChatDisclaimerAcceptedProvider), isFalse);
      container.read(aiChatDisclaimerAcceptedProvider.notifier).accept();
      expect(container.read(aiChatDisclaimerAcceptedProvider), isTrue);
    });

    test('achievement detail flags per achievement id', () {
      const id = 'ach-1';
      expect(container.read(achievementDetailDisabledProvider(id)), isFalse);
      expect(container.read(achievementDetailRefreshProvider(id)), isFalse);

      container
          .read(achievementDetailRefreshProvider(id).notifier)
          .markRefresh();
      container
          .read(achievementDetailDisabledProvider(id).notifier)
          .disable();

      expect(container.read(achievementDetailRefreshProvider(id)), isTrue);
      expect(container.read(achievementDetailDisabledProvider(id)), isTrue);
      expect(container.read(achievementDetailRefreshProvider('other')), isFalse);
    });

    test('aiChatMessages append and replace', () {
      container.read(aiChatMessagesProvider.notifier).append({
        'role': 'user',
        'content': 'hi',
      });
      expect(container.read(aiChatMessagesProvider), hasLength(1));

      container.read(aiChatMessagesProvider.notifier).replace([
        {'role': 'ai', 'content': 'hello'},
      ]);
      expect(container.read(aiChatMessagesProvider).single['content'], 'hello');
    });

    test('onboarding and settings flags update', () {
      container.read(onboardingPageIndexProvider.notifier).set(2);
      expect(container.read(onboardingPageIndexProvider), 2);

      container.read(settingsNotificationsAllowedProvider.notifier).set(true);
      expect(container.read(settingsNotificationsAllowedProvider), isTrue);

      container.read(settingsDeletingAccountProvider.notifier).set(true);
      expect(container.read(settingsDeletingAccountProvider), isTrue);
    });
  });
}
