import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_message_codec.dart';

void main() {
  group('sanitizeAssistantMessage', () {
    test('passes through messages without deprecated keys', () {
      const message = {
        'role': 'assistant',
        'content': 'Hello',
        kAssistantRelatedQuestionsKey: '["Q"]',
      };

      expect(sanitizeAssistantMessage(message), equals(message));
    });

    test('strips pendingAction and postActionChips', () {
      final cleaned = sanitizeAssistantMessage({
        'role': 'assistant',
        'content': 'Create goal',
        kAssistantPendingActionKey: '{"draft":{}}',
        kAssistantPostActionChipsKey: '["Undo"]',
      });

      expect(cleaned.containsKey(kAssistantPendingActionKey), isFalse);
      expect(cleaned.containsKey(kAssistantPostActionChipsKey), isFalse);
      expect(cleaned['content'], 'Create goal');
    });

    test('sanitizeAssistantMessages maps entire history', () {
      final cleaned = sanitizeAssistantMessages([
        {'role': 'user', 'content': 'create goal'},
        {
          'role': 'assistant',
          'content': 'Review',
          kAssistantPendingActionKey: '{}',
        },
      ]);

      expect(cleaned, hasLength(2));
      expect(cleaned[1].containsKey(kAssistantPendingActionKey), isFalse);
    });
  });
}
