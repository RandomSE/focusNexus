import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_message_codec.dart';
import 'package:focusNexus/providers/screen_ui_providers.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  test('AiChatMessages.append strips deprecated assistant-create keys', () async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    container.read(aiChatMessagesProvider.notifier).append({
      'role': 'assistant',
      'content': 'Confirm create',
      kAssistantPendingActionKey: '{"status":"ready"}',
      kAssistantPostActionChipsKey: '["Undo"]',
    });

    final messages = container.read(aiChatMessagesProvider);
    expect(messages, hasLength(1));
    expect(messages.single.containsKey(kAssistantPendingActionKey), isFalse);
    expect(messages.single.containsKey(kAssistantPostActionChipsKey), isFalse);
    expect(messages.single['content'], 'Confirm create');
  });
}
