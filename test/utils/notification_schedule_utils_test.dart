import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/notification_schedule_utils.dart';

void main() {
  group('highFrequencyDailyReminderDayOffsets', () {
    test('48 hours schedules only one daily offset', () {
      expect(
        NotificationScheduleUtils.highFrequencyDailyReminderDayOffsets(48),
        [1],
      );
    });

    test('72 hours schedules two daily offsets', () {
      expect(
        NotificationScheduleUtils.highFrequencyDailyReminderDayOffsets(72),
        [1, 2],
      );
    });

    test('24 hours or less returns none', () {
      expect(
        NotificationScheduleUtils.highFrequencyDailyReminderDayOffsets(24),
        isEmpty,
      );
      expect(
        NotificationScheduleUtils.highFrequencyDailyReminderDayOffsets(12),
        isEmpty,
      );
    });
  });

  group('affirmationHorizonDaysFor', () {
    test('iOS horizon is below 64 pending cap', () {
      expect(
        NotificationScheduleUtils.affirmationHorizonDaysFor(isIos: true),
        NotificationScheduleUtils.iosAffirmationHorizonDays,
      );
      expect(
        NotificationScheduleUtils.iosAffirmationHorizonDays,
        lessThan(64),
      );
    });

    test('non-iOS keeps 90-day horizon', () {
      expect(
        NotificationScheduleUtils.affirmationHorizonDaysFor(isIos: false),
        90,
      );
    });
  });
}
