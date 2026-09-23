import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/settings/notification_preference_options.dart';
import 'package:focusNexus/settings/notification_prefs_prompt.dart';
import 'package:focusNexus/utils/common_utils.dart';

class FirstGoalNotificationChoice {
  const FirstGoalNotificationChoice({
    required this.frequency,
    required this.style,
  });

  final String frequency;
  final String style;
}

/// Asks for notification settings before the first goal is stored.
///
/// Returns true when create should continue. Dismissing the dialog returns
/// false and leaves the deferred flag unset so the next attempt can ask again.
Future<bool> ensureFirstGoalNotificationPrefs({
  required BuildContext context,
  required ThemeBundle bundle,
  required AppSettings settings,
  required bool hasAnyGoal,
}) async {
  final raw = await settings.notificationPrefsConfirmedRaw();
  if (!NotificationPrefsPrompt.shouldPromptOnFirstGoal(
    confirmedRaw: raw,
    hasAnyGoal: hasAnyGoal,
  )) {
    return true;
  }
  if (!context.mounted) return false;
  final choice = await showFirstGoalNotificationPrefsDialog(
    context: context,
    bundle: bundle,
    initialFrequency: settings.notificationFrequency,
    initialStyle: settings.notificationStyle,
  );
  if (choice == null) return false;
  await settings.confirmDeferredNotificationPrefs(
    frequency: choice.frequency,
    style: choice.style,
  );
  return true;
}

Future<FirstGoalNotificationChoice?> showFirstGoalNotificationPrefsDialog({
  required BuildContext context,
  required ThemeBundle bundle,
  required String initialFrequency,
  required String initialStyle,
}) {
  var frequency = NotificationPreferenceOptions.frequencies.contains(
        initialFrequency,
      )
      ? initialFrequency
      : NotificationPreferenceOptions.defaultFrequency;
  var style = NotificationPreferenceOptions.styles.contains(initialStyle)
      ? initialStyle
      : NotificationPreferenceOptions.defaultStyle;

  return showDialog<FirstGoalNotificationChoice>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          final showStyle =
              !NotificationPreferenceOptions.isDisabled(frequency);
          return AlertDialog(
            backgroundColor: bundle.secondaryColor,
            title: Text('Notification settings', style: bundle.textStyle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose how FocusNexus should notify you. You can change this later in Settings.',
                    style: bundle.textStyle.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  CommonUtils.buildDropdownButtonFormField(
                    'Notification Frequency',
                    frequency,
                    NotificationPreferenceOptions.frequencies,
                    bundle.textStyle,
                    bundle.secondaryColor,
                    (value) {
                      if (value == null) return;
                      setLocalState(() => frequency = value);
                    },
                  ),
                  if (showStyle)
                    CommonUtils.buildDropdownButtonFormField(
                      'Notification Style',
                      style,
                      NotificationPreferenceOptions.styles,
                      bundle.textStyle,
                      bundle.secondaryColor,
                      (value) {
                        if (value == null) return;
                        setLocalState(() => style = value);
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  FirstGoalNotificationChoice(
                    frequency: initialFrequency,
                    style: initialStyle,
                  ),
                ),
                child: Text('Not now', style: bundle.textStyle),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  FirstGoalNotificationChoice(
                    frequency: frequency,
                    style: style,
                  ),
                ),
                child: Text('Save', style: bundle.textStyle),
              ),
            ],
          );
        },
      );
    },
  );
}
