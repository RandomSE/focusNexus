// .../utils/common_utils.dart
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class CommonUtils {
  static Future<void> waitForMilliseconds(int milliseconds) async {
    // Mostly use seconds, but this is more dynamic (as there are areas I use < 1 second)
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  static tz.TZDateTime newTimeMinusHours(tz.TZDateTime time, int hours) {
    return time.subtract(Duration(hours: hours));
  }

  static Future<tz.TZDateTime?> tzDateTimeFromHHmm(
    String hhmm, {
    tz.Location? location,
  }) async {
    final loc = location ?? tz.local;
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final now = tz.TZDateTime.now(loc);
    var candidate = tz.TZDateTime(
      loc,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  static int scoreFromLevel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 1;
      default:
        return 0;
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
    return Text(text, style: style);
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

  static void showSnackBar(
    BuildContext context,
    String text,
    TextStyle textStyle,
    int durationMilliseconds,
    int margin,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: textStyle),
        duration: Duration(milliseconds: durationMilliseconds),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(margin.toDouble()),
      ),
    );
  }

  static void showAlertDialog(
      BuildContext context,
      String titleText,
      String bodyText,
      TextStyle textStyle,
      Color backgroundColor,
      ) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(titleText, style: textStyle),
            content: Text(
                bodyText,
                style: textStyle),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('OK', style: textStyle
                  ))
            ],
          ),
    );
  }

  static void showDialogWidget(
      BuildContext context,
      String titleText,
      TextStyle textStyle,
      Color backgroundColor,
      ) {
    showDialog(
      context: context,
      builder: (ctx) =>
          Dialog(
            backgroundColor: backgroundColor,
            child: Text('$titleText Click anywhere to close this pop-up.', style: textStyle),
          ),
    );
  }

  static Widget buildDropdown<T>(
    String label,
    T value,
    List<T> options,
    TextStyle textStyle,
    Color dropdownColor,
    ValueChanged<T?> onChanged,
  ) {
    return DropdownButtonFormField<T>(
      dropdownColor: dropdownColor,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textStyle,
      ),
      items: options
          .map((e) => DropdownMenuItem<T>(
        value: e,
        child: Text(e.toString(), style: textStyle),
      ))
          .toList(),
      style: textStyle,
      onChanged: onChanged,
    );
  }

  static Widget buildTextFormField(
    TextEditingController? controller,
    String? label,
    TextStyle? textStyle,
    Color? fillColor,
    bool filled,
    String? Function(String?)? validator, {
    TextInputType? keyboardType, }
  ) {
    keyboardType ??= TextInputType.text;
    return TextFormField(
      controller: controller,
      style: textStyle,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textStyle,
        filled: filled,
        fillColor: fillColor,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }




}
