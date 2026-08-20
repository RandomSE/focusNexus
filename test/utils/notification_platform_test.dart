import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/notification_platform.dart';
import 'package:focusNexus/utils/notification_schedule_utils.dart';

void main() {
  group('NotificationPlatform.affirmationHorizonDays', () {
    test('iOS uses capped horizon below pending notification limit', () {
      final days = NotificationPlatform.affirmationHorizonDays(isIosOverride: true);
      expect(days, NotificationPlatform.iosAffirmationHorizonDays);
      expect(days, lessThan(NotificationPlatform.iosPendingNotificationCap));
      expect(
        NotificationScheduleUtils.affirmationHorizonDaysFor(isIos: true),
        days,
      );
    });

    test('non-iOS keeps full horizon', () {
      expect(
        NotificationPlatform.affirmationHorizonDays(isIosOverride: false),
        NotificationPlatform.defaultAffirmationHorizonDays,
      );
      expect(
        NotificationScheduleUtils.affirmationHorizonDaysFor(isIos: false),
        NotificationScheduleUtils.affirmationHorizonDays,
      );
    });

    test('schedule utils horizon constants alias NotificationPlatform', () {
      expect(
        NotificationScheduleUtils.affirmationHorizonDays,
        NotificationPlatform.defaultAffirmationHorizonDays,
      );
      expect(
        NotificationScheduleUtils.iosAffirmationHorizonDays,
        NotificationPlatform.iosAffirmationHorizonDays,
      );
    });
  });

  group('NotificationPlatform permission gate', () {
    test('iOS does not require exact alarm for enablement', () {
      expect(
        NotificationPlatform.notificationPermissionSufficientWithoutExactAlarm(
          isIosOverride: true,
        ),
        isTrue,
      );
    });

    test('Android notification permission alone is sufficient for enablement', () {
      expect(
        NotificationPlatform.notificationPermissionSufficientWithoutExactAlarm(
          isIosOverride: false,
          isAndroidOverride: true,
        ),
        isTrue,
      );
    });

    test('exact alarm deny copy explains approximate reminders', () {
      expect(
        NotificationPlatform.exactAlarmDeniedUserMessage,
        contains('approximate'),
      );
      expect(
        NotificationPlatform.exactAlarmDeniedUserMessage.toLowerCase(),
        contains('exact alarm'),
      );
    });
  });
}
