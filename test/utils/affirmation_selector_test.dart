import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/affirmation_selector.dart';
import 'package:focusNexus/utils/notification_schedule_utils.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });
  group('AffirmationSelector', () {
    test('same calendar day returns the same message', () {
      final morning = AffirmationSelector.forDate(DateTime(2026, 5, 26, 6));
      final evening = AffirmationSelector.forDate(DateTime(2026, 5, 26, 20));
      expect(morning, evening);
    });

    test('consecutive days return different messages', () {
      var foundDistinctPair = false;
      for (var offset = 0; offset < 365; offset++) {
        final start = DateTime(2026, 1, 1).add(Duration(days: offset));
        final next = start.add(const Duration(days: 1));
        if (AffirmationSelector.forDate(start) != AffirmationSelector.forDate(next)) {
          foundDistinctPair = true;
          break;
        }
      }
      expect(foundDistinctPair, isTrue);
    });

    test('notification style can change rendered message', () {
      var foundDifference = false;
      for (var offset = 0; offset < 14; offset++) {
        final day = DateTime(2026, 6, 1).add(Duration(days: offset));
        final minimal = AffirmationSelector.forDate(
          day,
          notificationStyle: 'Minimal',
        );
        final vibrant = AffirmationSelector.forDate(
          day,
          notificationStyle: 'Vibrant',
        );
        if (minimal != vibrant) {
          foundDifference = true;
          break;
        }
      }
      expect(foundDifference, isTrue);
    });

    test('previewRange returns requested length', () {
      final preview = AffirmationSelector.previewRange(
        DateTime(2026, 5, 1),
        7,
      );
      expect(preview, hasLength(7));
      expect(preview.every((m) => m.isNotEmpty), isTrue);
    });
  });

  group('NotificationScheduleUtils', () {
    test('normalizeHHmm handles am/pm and bare hour', () {
      expect(NotificationScheduleUtils.normalizeHHmm('6:30 pm'), '18:30');
      expect(NotificationScheduleUtils.normalizeHHmm('6:30am'), '06:30');
      expect(NotificationScheduleUtils.normalizeHHmm(''), '06:00');
    });

    test('shouldRefreshAffirmationSchedule when runway is low', () {
      final now = DateTime(2026, 5, 26);
      expect(
        NotificationScheduleUtils.shouldRefreshAffirmationSchedule(
          scheduledUntil: DateTime(2026, 6, 1),
          now: now,
          leadDays: 14,
        ),
        isTrue,
      );
      expect(
        NotificationScheduleUtils.shouldRefreshAffirmationSchedule(
          scheduledUntil: DateTime(2026, 8, 1),
          now: now,
          leadDays: 14,
        ),
        isFalse,
      );
    });

    test('dailyTriggersFrom builds consecutive days', () {
      final first = tz.TZDateTime.utc(2026, 5, 26, 6);
      final triggers = NotificationScheduleUtils.dailyTriggersFrom(
        firstTrigger: first,
        days: 3,
      );
      expect(triggers, hasLength(3));
      expect(triggers[1].day, 27);
      expect(triggers[2].day, 28);
    });
  });
}
