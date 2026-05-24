import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('scoreFromLevel', () {
    test('maps high/medium/low and unknown', () {
      expect(CommonUtils.scoreFromLevel('High'), 3);
      expect(CommonUtils.scoreFromLevel('medium'), 1);
      expect(CommonUtils.scoreFromLevel('Low'), 0);
      expect(CommonUtils.scoreFromLevel(''), 0);
    });
  });

  group('scoreFromTime', () {
    test('boundary minutes', () {
      expect(CommonUtils.scoreFromTime(29), 0);
      expect(CommonUtils.scoreFromTime(30), 1);
      expect(CommonUtils.scoreFromTime(89), 1);
      expect(CommonUtils.scoreFromTime(90), 2);
      expect(CommonUtils.scoreFromTime(149), 2);
      expect(CommonUtils.scoreFromTime(150), 3);
      expect(CommonUtils.scoreFromTime(299), 3);
      expect(CommonUtils.scoreFromTime(300), 4);
      expect(CommonUtils.scoreFromTime(599), 4);
      expect(CommonUtils.scoreFromTime(600), 5);
      expect(CommonUtils.scoreFromTime(10000), 5);
    });
  });

  group('scoreFromSteps', () {
    test('boundary step counts', () {
      expect(CommonUtils.scoreFromSteps(3), 0);
      expect(CommonUtils.scoreFromSteps(4), 1);
      expect(CommonUtils.scoreFromSteps(8), 2);
      expect(CommonUtils.scoreFromSteps(15), 3);
      expect(CommonUtils.scoreFromSteps(25), 4);
      expect(CommonUtils.scoreFromSteps(50), 5);
    });
  });

  group('newTimeMinusHours', () {
    test('subtracts hours from TZDateTime', () {
      final base = tz.TZDateTime.utc(2026, 5, 10, 12);
      final result = CommonUtils.newTimeMinusHours(base, 3);
      expect(result, tz.TZDateTime.utc(2026, 5, 10, 9));
    });
  });

  group('tzDateTimeFromHHmm', () {
    test('returns null for invalid input', () async {
      expect(await CommonUtils.tzDateTimeFromHHmm(''), isNull);
      expect(await CommonUtils.tzDateTimeFromHHmm('abc'), isNull);
      expect(await CommonUtils.tzDateTimeFromHHmm('25:00'), isNull);
      expect(await CommonUtils.tzDateTimeFromHHmm('12:60'), isNull);
    });

    test('returns future time today or tomorrow in UTC', () async {
      final loc = tz.getLocation('UTC');
      final result = await CommonUtils.tzDateTimeFromHHmm(
        '23:59',
        location: loc,
      );
      expect(result, isNotNull);
      expect(result!.hour, 23);
      expect(result.minute, 59);
      expect(result.isAfter(tz.TZDateTime.now(loc)), isTrue);
    });
  });
}
