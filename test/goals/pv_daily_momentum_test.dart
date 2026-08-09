import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/pv_daily_momentum.dart';

void main() {
  group('PvDailyMomentum.qualifies', () {
    test('below threshold does not qualify', () {
      expect(PvDailyMomentum.qualifies(49), isFalse);
    });

    test('at threshold qualifies', () {
      expect(PvDailyMomentum.qualifies(50), isTrue);
    });

    test('above threshold qualifies', () {
      expect(PvDailyMomentum.qualifies(500), isTrue);
    });
  });

  group('PvDailyMomentum.grantForQualifyingCount', () {
    test('grants 1000 PV exactly at 10, 20, 30', () {
      expect(PvDailyMomentum.grantForQualifyingCount(10), 1000);
      expect(PvDailyMomentum.grantForQualifyingCount(20), 1000);
      expect(PvDailyMomentum.grantForQualifyingCount(30), 1000);
    });

    test('grants nothing off-threshold, including past 30', () {
      expect(PvDailyMomentum.grantForQualifyingCount(1), 0);
      expect(PvDailyMomentum.grantForQualifyingCount(9), 0);
      expect(PvDailyMomentum.grantForQualifyingCount(11), 0);
      expect(PvDailyMomentum.grantForQualifyingCount(19), 0);
      expect(PvDailyMomentum.grantForQualifyingCount(21), 0);
      expect(PvDailyMomentum.grantForQualifyingCount(29), 0);
      expect(PvDailyMomentum.grantForQualifyingCount(31), 0);
      expect(PvDailyMomentum.grantForQualifyingCount(40), 0);
    });

    test('sum of all three thresholds is the documented daily max', () {
      final sum = PvDailyMomentum.grantThresholds
          .map(PvDailyMomentum.grantForQualifyingCount)
          .fold(0, (a, b) => a + b);
      expect(sum, PvDailyMomentum.maxDailyGrant);
      expect(sum, 3000);
    });
  });

  group('PvDailyMomentum.nextQualifyingCount', () {
    test('first qualifying completion of a fresh day starts at 1', () {
      final record = PvDailyMomentum.nextQualifyingCount(
        stored: null,
        today: '09 08 2026',
      );
      expect(record.dateKey, '09 08 2026');
      expect(record.count, 1);
    });

    test('same-day qualifying completions increment the stored count', () {
      final first = PvDailyMomentum.nextQualifyingCount(
        stored: null,
        today: '09 08 2026',
      );
      final second = PvDailyMomentum.nextQualifyingCount(
        stored: first.toStorage(),
        today: '09 08 2026',
      );
      expect(second.count, 2);
    });

    test('a new day resets the qualifying count to 1', () {
      final yesterday = PvDailyMomentum.nextQualifyingCount(
        stored: null,
        today: '08 08 2026',
      )..copyWith(count: 9);
      final stored = yesterday.copyWith(count: 9).toStorage();

      final today = PvDailyMomentum.nextQualifyingCount(
        stored: stored,
        today: '09 08 2026',
      );

      expect(today.dateKey, '09 08 2026');
      expect(today.count, 1);
    });

    test('reaching the 10th qualifying completion in a day grants PV', () {
      var stored = PvDailyMomentum.nextQualifyingCount(
        stored: null,
        today: '09 08 2026',
      ).toStorage();
      for (var i = 2; i <= 9; i++) {
        stored = PvDailyMomentum.nextQualifyingCount(
          stored: stored,
          today: '09 08 2026',
        ).toStorage();
      }
      final tenth = PvDailyMomentum.nextQualifyingCount(
        stored: stored,
        today: '09 08 2026',
      );

      expect(tenth.count, 10);
      expect(PvDailyMomentum.grantForQualifyingCount(tenth.count), 1000);
    });
  });
}
