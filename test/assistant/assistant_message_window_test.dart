import 'package:flutter_test/flutter_test.dart';

import 'package:focusNexus/assistant/assistant_message_window.dart';

void main() {
  group('visibleAssistantMessages', () {
    final messages = List.generate(
      12,
      (i) => {'role': 'user', 'content': 'msg $i'},
    );

    test('returns all messages when showAll is true', () {
      expect(
        visibleAssistantMessages(messages: messages, showAll: true).length,
        12,
      );
    });

    test('returns trailing window when history is long', () {
      final visible = visibleAssistantMessages(
        messages: messages,
        showAll: false,
      );
      expect(visible.length, kAssistantVisibleMessageCount);
      expect(visible.first['content'], 'msg 4');
      expect(visible.last['content'], 'msg 11');
    });

    test('hidden count matches collapsed tail', () {
      expect(
        hiddenAssistantMessageCount(messages: messages, showAll: false),
        4,
      );
      expect(
        hiddenAssistantMessageCount(messages: messages, showAll: true),
        0,
      );
    });
  });
}
