import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_repeat_series.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_repeat_editor.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_window_editor.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Dialog to edit an active repeat series slot and cadence.
Future<bool> showEditRepeatSeriesDialog({
  required BuildContext context,
  required WidgetRef ref,
  required GoalRepeatSeries series,
}) async {
  final bundle = ref.read(themeBundleProvider);
  final activeGoals = ref.read(goalsProvider).activeGoals;
  GoalSet? activeGoal;
  for (final goal in activeGoals) {
    if (goal.repeatSeriesId == series.seriesId) {
      activeGoal = goal;
      break;
    }
  }

  final initial = repeatSeriesEditWindow(series: series, activeGoal: activeGoal);
  var endAt = initial.endAt;
  var duration = initial.duration;
  var repeat = series.repeatRule;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    barrierColor: bundle.secondaryColor,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          final startAt = endAt.subtract(duration);
          return AlertDialog(
            backgroundColor: bundle.secondaryColor,
            title: Text('Edit repeating goal', style: bundle.textStyle),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(series.title, style: bundle.textStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(height: 12),
                      TimeWindowWindowEditor(
                        bundle: bundle,
                        endAt: endAt,
                        startAt: startAt,
                        duration: duration,
                        onEndChanged: (v) =>
                            setLocalState(() => endAt = v),
                        onStartChanged: (v) => setLocalState(
                          () => duration = endAt.difference(v),
                        ),
                        onDurationChanged: (v) =>
                            setLocalState(() => duration = v),
                      ),
                      const SizedBox(height: 12),
                      TimeWindowRepeatEditor(
                        bundle: bundle,
                        rule: repeat,
                        onChanged: (r) => setLocalState(() => repeat = r),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel', style: bundle.textStyle),
              ),
              TextButton(
                onPressed: () async {
                  if (!repeat.enabled) {
                    CommonUtils.showSnackBar(
                      dialogContext,
                      'Repeating must stay enabled while editing a series.',
                      bundle.textStyle,
                      2500,
                      5,
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: Text('Save', style: bundle.textStyle),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved != true || !context.mounted) return false;

  await ref.read(goalsProvider.notifier).updateRepeatSeries(
    seriesId: series.seriesId,
    windowEndAt: endAt,
    windowDuration: duration,
    repeatRule: repeat,
    now: DateTime.now(),
  );
  return true;
}
