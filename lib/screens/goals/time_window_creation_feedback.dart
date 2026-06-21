import 'package:flutter/material.dart';

/// Brief confirmation after creating time-slot goal(s).
void showTimeSlotGoalsCreatedFeedback(
  ScaffoldMessengerState messenger, {
  required TextStyle textStyle,
  required int count,
}) {
  final label = count == 1
      ? 'Time-slot goal created'
      : '$count time-slot goals created';
  messenger.showSnackBar(
    SnackBar(
      content: Text(label, style: textStyle),
      duration: const Duration(milliseconds: 750),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
    ),
  );
}
