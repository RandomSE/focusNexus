import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/streak_logic.dart';

void main() {
  group('getWeekIdentifier', () {
    test('returns Monday of the week containing date', () {
      // 2026-05-10 is Sunday
      expect(
        StreakLogic.getWeekIdentifier(DateTime(2026, 5, 10)),
        '2026-05-04',
      );
      expect(
        StreakLogic.getWeekIdentifier(DateTime(2026, 5, 5)),
        '2026-05-04',
      );
    });
  });

  group('isPreviousWeek', () {
    test('true when stored week is exactly one week before current', () {
      expect(
        StreakLogic.isPreviousWeek('2026-04-27', '2026-05-04'),
        isTrue,
      );
    });

    test('false for empty, invalid, or non-consecutive weeks', () {
      expect(StreakLogic.isPreviousWeek('', '2026-05-04'), isFalse);
      expect(StreakLogic.isPreviousWeek('2026-05-04', ''), isFalse);
      expect(StreakLogic.isPreviousWeek('not-a-date', '2026-05-04'), isFalse);
      expect(StreakLogic.isPreviousWeek('2026-04-20', '2026-05-04'), isFalse);
    });
  });

  group('monthIdentifier', () {
    test('formats yyyy-MM', () {
      expect(StreakLogic.monthIdentifier(DateTime(2026, 5, 24)), '2026-05');
    });
  });
}
