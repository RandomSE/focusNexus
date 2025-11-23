// .../utils/common_utils.dart
import 'package:flutter/material.dart';
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

  static int scoreFromLevel(String level) {
    switch (level.toLowerCase()) {
      case 'high': return 3;
      case 'medium': return 1;
      default: return 0;
    }
  }

  static int scoreFromTime(int minutes) {
    if (minutes >= 600) return 5;
    if (minutes >= 300) return 4;
    if (minutes >= 150) return 3;
    if (minutes >= 90) return 2;
    if (minutes >= 30) return 1;
    return 0;
  }

  static int scoreFromSteps(int steps) {
    if (steps >= 50) return 5;
    if (steps >= 25) return 4;
    if (steps >= 15) return 3;
    if (steps >= 8) return 2;
    if (steps > 3) return 1;
    return 0;
  }

  static Text buildText(String text, TextStyle style) {
    return Text(
      text,
      style: style,
    );
  }

  static ElevatedButton buildElevatedButton(
      String text,
      Color primaryColor,
      Color secondaryColor,
      double paddingPixels,
      double radius,
      VoidCallback? onPressed, //  nullable, for conditional buttons.
      ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        padding: EdgeInsets.symmetric(vertical: paddingPixels),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: Text(text),
    );
  }



}
