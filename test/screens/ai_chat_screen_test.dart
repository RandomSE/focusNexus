import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/ai/assistant_intro_notice.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';
import 'package:focusNexus/assistant/widgets/assistant_chat_composer.dart';
import 'package:focusNexus/assistant/widgets/assistant_side_nav.dart';
import 'package:focusNexus/screens/ai_chat_screen.dart';
import 'package:focusNexus/assistant/assistant_chat_reply.dart';
import 'package:focusNexus/services/ai_chat_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

Future<void> _scrollToAssistantTarget(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 16; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      return;
    }
    final scrollable = find
        .descendant(
          of: find.byKey(const Key('assistant-main-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollToAskSection(WidgetTester tester) async {
  await _scrollToAssistantTarget(
    tester,
    find.byKey(kAssistantQuestionFieldKey),
  );
}

Finder get _assistantQuestionTextField => find.descendant(
      of: find.byKey(kAssistantQuestionFieldKey),
      matching: find.byType(TextField),
    );

void main() {
  testWidgets('Assistant shows intro until user continues', (tester) async {
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

    expect(find.text(assistantIntroNotice), findsOneWidget);
    expect(find.text('Continue to Assistant'), findsOneWidget);
    expect(find.text(kAssistantQuestionFieldLabel), findsNothing);
    expect(find.byKey(kAssistantSideNavAskKey), findsNothing);
    expect(find.byKey(kAssistantSideNavFaqKey), findsNothing);

    await tester.tap(find.text('Continue to Assistant'));
    await tester.pumpAndSettle();

    expect(find.text(assistantIntroNotice), findsNothing);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.byKey(kAssistantSideNavFaqKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(kAssistantSideNavAskKey), findsOneWidget);

    await _scrollToAskSection(tester);
    expect(find.text('Ask a question'), findsOneWidget);
    expect(find.text(kAssistantQuestionFieldLabel), findsOneWidget);
  });

  testWidgets('ask question side nav reveals ask section', (tester) async {
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
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: Key('assistant-test-viewport'),
              width: 400,
              height: 480,
              child: AiChatScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewportBottom =
        tester.getBottomLeft(find.byKey(const Key('assistant-test-viewport'))).dy;

    await tester.tap(find.byKey(kAssistantSideNavAskKey));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.getTopLeft(find.text('Suggested questions')).dy,
      lessThan(viewportBottom),
    );
  });

  testWidgets('layout avoids overflow at dyslexia font 24', (tester) async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.dyslexiaFont: 'true',
        StorageKeys.fontSize: '24',
      },
    );
    final container = await createTestContainer(
      storage: storage,
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
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 371,
              height: 640,
              child: AiChatScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.byKey(kAssistantSideNavAskKey), findsOneWidget);
  });

  testWidgets('FAQ entry tap sends question when section expanded', (tester) async {
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

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('What is FocusNexus?'));
    await tester.pumpAndSettle();

    expect(fake.sentMessages, contains('What is FocusNexus?'));
  });

  testWidgets('long chat history collapses with expand control', (tester) async {
    final container = await createTestContainer(
      overrides: [
        aiChatDisclaimerAcceptedProvider.overrideWith(
          () => _AcceptedDisclaimer(),
        ),
        aiChatMessagesProvider.overrideWith(() => _LongChatHistory()),
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

    await _scrollToAssistantTarget(
      tester,
      find.textContaining('Show 4 earlier'),
    );

    expect(find.textContaining('Show 4 earlier'), findsOneWidget);

    await tester.tap(find.textContaining('Show 4 earlier'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Show'), findsNothing);
  });

  testWidgets('accepted Assistant layout fits with keyboard', (tester) async {
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

    await _scrollToAskSection(tester);
    await tester.showKeyboard(_assistantQuestionTextField);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('send appends mock assistant reply via provider', (tester) async {
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

    await _scrollToAskSection(tester);
    await tester.enterText(_assistantQuestionTextField, 'Hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(fake.sentMessages, ['Hello']);
    expect(find.text('mock reply'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    await tester.ensureVisible(find.text('mock reply'));
    await tester.pumpAndSettle();
  });

  testWidgets('side nav buttons navigate between FAQ and ask areas', (
    tester,
  ) async {
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
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: Key('assistant-test-viewport'),
              width: 400,
              height: 480,
              child: AiChatScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(kAssistantSideNavAskKey));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    final viewportBottom =
        tester.getBottomLeft(find.byKey(const Key('assistant-test-viewport'))).dy;
    expect(
      tester.getTopLeft(find.byKey(kAssistantQuestionFieldKey)).dy,
      lessThan(viewportBottom),
    );

    await tester.tap(find.byKey(kAssistantSideNavFaqKey));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(kAssistantSideNavAskKey), findsOneWidget);
  });

  testWidgets('reply stays visible after sending from ask section', (
    tester,
  ) async {
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
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: Key('assistant-test-viewport'),
              width: 400,
              height: 520,
              child: AiChatScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(kAssistantSideNavAskKey));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(_assistantQuestionTextField);
    await tester.enterText(_assistantQuestionTextField, 'Hello');
    await tester.ensureVisible(find.byIcon(Icons.send));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));

    final viewportBottom =
        tester.getBottomLeft(find.byKey(const Key('assistant-test-viewport'))).dy;
    final reply = find.text('mock reply');
    expect(reply, findsOneWidget);
    expect(tester.getTopLeft(reply).dy, lessThan(viewportBottom));
  });

  testWidgets('quick reply chip sends a question', (tester) async {
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

    await _scrollToAskSection(tester);
    await tester.tap(find.text('What is a time-slot goal?'));
    await tester.pumpAndSettle();

    expect(fake.sentMessages, contains('What is a time-slot goal?'));
  });

  testWidgets('enter key sends question from ask field', (tester) async {
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

    await _scrollToAskSection(tester);
    await tester.enterText(_assistantQuestionTextField, 'Hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(fake.sentMessages, ['Hello']);
  });
}

class _LongChatHistory extends AiChatMessages {
  @override
  List<Map<String, String>> build() {
    return List.generate(
      12,
      (i) => {'role': 'user', 'content': 'msg $i'},
    );
  }
}

class _AcceptedDisclaimer extends AiChatDisclaimerAccepted {
  @override
  bool build() => true;
}

class _FakeAiChatService implements AiChatService {
  _FakeAiChatService();

  final List<String> sentMessages = [];

  @override
  Future<AssistantChatReply> sendMessage(String message) async {
    sentMessages.add(message);
    return const AssistantChatReply(text: 'mock reply');
  }
}
