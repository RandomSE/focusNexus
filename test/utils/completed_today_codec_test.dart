import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/completed_today_codec.dart';

void main() {
  group('CompletedTodayCodec', () {
    test('starts at 1 when storage is empty', () {
      expect(
        CompletedTodayCodec.nextCount(stored: null, today: '24 05 2026'),
        1,
      );
    });

    test('increments when same day', () {
      expect(
        CompletedTodayCodec.nextCount(
          stored: '24 05 2026|3',
          today: '24 05 2026',
        ),
        4,
      );
    });

    test('resets to 1 on new day', () {
      expect(
        CompletedTodayCodec.nextCount(
          stored: '23 05 2026|5',
          today: '24 05 2026',
        ),
        1,
      );
    });

    test('encode roundtrips format', () {
      expect(
        CompletedTodayCodec.encode(today: '24 05 2026', count: 2),
        '24 05 2026|2',
      );
    });
  });
}
