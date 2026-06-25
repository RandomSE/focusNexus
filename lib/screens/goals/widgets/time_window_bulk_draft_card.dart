import 'package:flutter/material.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_repeat_editor.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_window_editor.dart';

/// Per-template window + repeat editors in the bulk-create wizard.
class TimeWindowBulkDraftCard extends StatelessWidget {
  const TimeWindowBulkDraftCard({
    super.key,
    required this.bundle,
    required this.title,
    required this.endAt,
    required this.duration,
    required this.repeat,
    required this.onEndChanged,
    required this.onStartChanged,
    required this.onDurationChanged,
    required this.onRepeatChanged,
    this.showWindow = true,
    this.showRepeat = true,
  });

  final ThemeBundle bundle;
  final String title;
  final DateTime endAt;
  final Duration duration;
  final RepeatRule repeat;
  final ValueChanged<DateTime> onEndChanged;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<Duration> onDurationChanged;
  final ValueChanged<RepeatRule> onRepeatChanged;
  final bool showWindow;
  final bool showRepeat;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bundle.secondaryColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: bundle.textStyle.copyWith(fontWeight: FontWeight.w600)),
            if (showWindow) ...[
              const SizedBox(height: 8),
              TimeWindowWindowEditor(
                bundle: bundle,
                endAt: endAt,
                startAt: endAt.subtract(duration),
                duration: duration,
                onEndChanged: onEndChanged,
                onStartChanged: onStartChanged,
                onDurationChanged: onDurationChanged,
              ),
            ],
            if (showRepeat) ...[
              const SizedBox(height: 8),
              TimeWindowRepeatEditor(
                bundle: bundle,
                rule: repeat,
                onChanged: onRepeatChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
