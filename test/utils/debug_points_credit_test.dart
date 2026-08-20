import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/debug/debug_points_credit.dart';
import 'package:focusNexus/services/daily_open_reward_service.dart';

void main() {
  group('DebugPointsCredit.validateAmount', () {
    test('rejects empty and non-integers', () {
      expect(DebugPointsCredit.validateAmount(null), isNotNull);
      expect(DebugPointsCredit.validateAmount(''), isNotNull);
      expect(DebugPointsCredit.validateAmount('  '), isNotNull);
      expect(DebugPointsCredit.validateAmount('12.5'), isNotNull);
      expect(DebugPointsCredit.validateAmount('abc'), isNotNull);
    });

    test('rejects zero, negative, and 100 million or more', () {
      expect(DebugPointsCredit.validateAmount('0'), isNotNull);
      expect(DebugPointsCredit.validateAmount('-1'), isNotNull);
      expect(DebugPointsCredit.validateAmount('100000000'), isNotNull);
      expect(DebugPointsCredit.validateAmount('100000001'), isNotNull);
    });

    test('accepts whole numbers below 100 million', () {
      expect(DebugPointsCredit.validateAmount('1'), isNull);
      expect(DebugPointsCredit.validateAmount(' 500 '), isNull);
      expect(DebugPointsCredit.validateAmount('99999999'), isNull);
    });
  });

  group('DebugPointsCredit.isAvailableOnDay', () {
    test('available when never credited', () {
      final now = DateTime(2026, 8, 16, 10);
      expect(
        DebugPointsCredit.isAvailableOnDay(lastCreditDay: null, now: now),
        isTrue,
      );
      expect(
        DebugPointsCredit.isAvailableOnDay(lastCreditDay: '', now: now),
        isTrue,
      );
    });

    test('hidden on the same local calendar day as streak', () {
      final now = DateTime(2026, 8, 16, 23, 59);
      final today = DailyOpenRewardService.formatLocalDay(now);
      expect(
        DebugPointsCredit.isAvailableOnDay(lastCreditDay: today, now: now),
        isFalse,
      );
    });

    test('available again on the next streak day', () {
      final today = DateTime(2026, 8, 16, 9);
      final tomorrow = DateTime(2026, 8, 17, 0, 1);
      final credited = DailyOpenRewardService.formatLocalDay(today);
      expect(
        DebugPointsCredit.isAvailableOnDay(
          lastCreditDay: credited,
          now: tomorrow,
        ),
        isTrue,
      );
    });
  });
}
