import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/ai/ai_chat_legal_notice.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/screens/ai_chat_screen.dart';
import 'package:focusNexus/services/ai_chat_service.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('AI chat shows disclaimer until user agrees', (tester) async {
    final container = await createTestContainer();
    addTearDown(container.dispose);
    await lightTestBootstrap(container);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(aiChatLegalNotice), findsOneWidget);
    expect(find.text('I understand and agree'), findsOneWidget);
    expect(find.text('Type your message...'), findsNothing);

    await tester.tap(find.text('I understand and agree'));
    await tester.pumpAndSettle();

    expect(find.text('Type your message...'), findsOneWidget);
    expect(find.text(aiChatLegalNotice), findsNothing);
  });

  testWidgets('accepted AI chat layout fits with keyboard', (tester) async {
    final container = await createTestContainer(
      overrides: [
        aiChatDisclaimerAcceptedProvider.overrideWith(
          () => _AcceptedDisclaimer(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await lightTestBootstrap(container);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('send appends mock AI reply via provider', (tester) async {
    final fake = _FakeAiChatService();
    final container = await createTestContainer(
      overrides: [
        aiChatDisclaimerAcceptedProvider.overrideWith(
          () => _AcceptedDisclaimer(),
        ),
        aiChatServiceProvider.overrideWith((ref) => fake),
      ],
    );
    addTearDown(container.dispose);
    await lightTestBootstrap(container);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello AI');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(fake.sentMessages, ['Hello AI']);
    expect(find.text('mock reply'), findsOneWidget);
    expect(find.text('Hello AI'), findsOneWidget);
  });
}

class _AcceptedDisclaimer extends AiChatDisclaimerAccepted {
  @override
  bool build() => true;
}

class _FakeAiChatService implements AiChatService {
  final List<String> sentMessages = [];

  @override
  Future<String> sendMessage(String message) async {
    sentMessages.add(message);
    return 'mock reply';
  }
}
