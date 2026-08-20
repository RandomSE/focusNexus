import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_window_editor.dart';

/// Dialog to edit a one-off (non-repeating) time-slot goal.
Future<bool> showEditTimeWindowGoalDialog({
  required BuildContext context,
  required WidgetRef ref,
  required GoalSet goal,
}) async {
  final bundle = ref.read(themeBundleProvider);
  final initial = timeWindowGoalEditWindow(goal);
  var endAt = initial.endAt;
  var duration = initial.duration;
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
            title: Text('Edit time slot', style: bundle.textStyle),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        goal.title,
                        style: bundle.textStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TimeWindowWindowEditor(
                        bundle: bundle,
                        endAt: endAt,
                        startAt: startAt,
                        duration: duration,
                        onEndChanged: (v) => setLocalState(() => endAt = v),
                        onStartChanged: (_) {},
                        onDurationChanged: (v) =>
                            setLocalState(() => duration = v),
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
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('Save', style: bundle.textStyle),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved != true || !context.mounted) return false;

  await ref.read(goalsProvider.notifier).updateTimeWindowGoal(
    goalId: goal.goalId,
    windowEndAt: endAt,
    windowDuration: duration,
    now: DateTime.now(),
  );
  return true;
}
