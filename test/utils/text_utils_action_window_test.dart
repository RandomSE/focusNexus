import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/text_utils.dart';

void main() {
  test('start reminder uses window end in message body', () {
    final end = DateTime(2026, 6, 21, 18, 50);
    final start = DateTime(2026, 6, 21, 16, 50);
    final body = TextUtils.buildActionWindowReminderMessage(
      'Walk',
      42,
      'Minimal',
      end,
      isStart: true,
    );
    expect(body, contains('18:50'));
    expect(body, isNot(contains('16:50')));
    expect(body, contains('open now until'));
    expect(start, isNotNull); // documents intent: start is not shown as end
  });
}
