import 'package:flutter/material.dart';
import 'package:focusNexus/utils/notification_schedule_utils.dart';

/// Shared themed time picker used by Settings notification controls.
abstract final class SettingsTimePicker {
  SettingsTimePicker._();

  static ThemeData theme({
    required Color primaryColor,
    required Color secondaryColor,
    required TextStyle textStyle,
  }) {
    return ThemeData(
      timePickerTheme: TimePickerThemeData(
        backgroundColor: secondaryColor,
        dialBackgroundColor: secondaryColor,
        dialHandColor: Colors.deepPurple,
        dialTextColor: primaryColor,
        entryModeIconColor: primaryColor,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : secondaryColor,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? secondaryColor
              : primaryColor,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : secondaryColor,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? secondaryColor
              : primaryColor,
        ),
        helpTextStyle: textStyle,
        hourMinuteTextStyle: textStyle,
      ),
    );
  }

  /// Shows a dial time picker; returns normalized `HH:mm` or null if cancelled.
  static Future<String?> pickHHmm(
    BuildContext context, {
    required Color primaryColor,
    required Color secondaryColor,
    required TextStyle textStyle,
    TimeOfDay? initialTime,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) => Theme(
        data: theme(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          textStyle: textStyle,
        ),
        child: child!,
      ),
    );
    if (selected == null) return null;
    final raw =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    return NotificationScheduleUtils.normalizeHHmm(raw);
  }
}
