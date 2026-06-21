import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

Future<bool?> showClearActiveGoalsRepeatDialog({
  required BuildContext context,
  required ThemeBundle bundle,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: bundle.secondaryColor,
      title: Text('Also cancel repeating schedules?', style: bundle.textStyle),
      content: Text(
        'Some active goals are part of a repeating schedule. '
        'Do you want to stop those repeats as well?',
        style: bundle.textStyle,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('No', style: bundle.textStyle),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Yes', style: bundle.textStyle),
        ),
      ],
    ),
  );
}
