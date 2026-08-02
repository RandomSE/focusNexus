import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';

void main() {
  test('atMinute drops seconds and fractional seconds', () {
    final raw = DateTime(2026, 7, 27, 14, 30, 45, 123, 456);
    expect(
      CompletionTimestamp.atMinute(raw),
      DateTime(2026, 7, 27, 14, 30),
    );
  });

  test('formatLabel matches goal deadline style', () {
    expect(
      CompletionTimestamp.formatLabel(DateTime(2026, 6, 3, 14, 30, 59, 999)),
      '03 June 2026 14:30',
    );
  });

  test('tryParse accepts goal label and ISO with micros', () {
    expect(
      CompletionTimestamp.tryParse('03 June 2026 14:30'),
      DateTime(2026, 6, 3, 14, 30),
    );
    expect(
      CompletionTimestamp.tryParse('2026-06-03T14:30:45.123456'),
      DateTime(2026, 6, 3, 14, 30),
    );
  });
}
