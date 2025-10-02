// .../utils/common_utils.dart
import 'package:timezone/timezone.dart' as tz;

class CommonUtils {

  static Future<void> waitForMilliseconds(int milliseconds) async { // Mostly use seconds, but this is more dynamic (as there are areas I use < 1 second)
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  static tz.TZDateTime newTimeMinusHours (tz.TZDateTime time, int hours){
    return time.subtract(Duration(hours: hours));
  }

  static Future<tz.TZDateTime?> tzDateTimeFromHHmm(String hhmm, {tz.Location? location}) async {
    final loc = location ?? tz.local;
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final now = tz.TZDateTime.now(loc);
    var candidate = tz.TZDateTime(loc, now.year, now.month, now.day, hour, minute);

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }


}
