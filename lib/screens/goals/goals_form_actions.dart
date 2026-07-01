import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/screens/goals/widgets/clear_active_goals_repeat_dialog.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Create and clear-active flows for the goals screen form (controllers wired by screen).
class GoalsFormActions {
  GoalsFormActions({
    required this.goalsNotifier,
    required this.getUiState,
    required this.anchorDate,
    required this.formKey,
    required this.titleController,
    required this.timeController,
    required this.deadlineController,
    required this.stepsController,
    required this.resetControllers,
  });

  final GoalsNotifier goalsNotifier;
  final GoalsScreenUiState Function() getUiState;
  final DateTime anchorDate;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController timeController;
  final TextEditingController deadlineController;
  final TextEditingController stepsController;
  final VoidCallback resetControllers;

  Future<void> clearGoals({
    required BuildContext context,
    required ThemeBundle bundle,
    required bool Function() isMounted,
  }) async {
    if (goalsNotifier.hasActiveGoalsWithRepeats) {
      final cancelRepeats = await showClearActiveGoalsRepeatDialog(
        context: context,
        bundle: bundle,
      );
      if (!isMounted() || cancelRepeats == null) return;
      await goalsNotifier.clearActiveGoals(cancelRepeatSeries: cancelRepeats);
      return;
    }
    await goalsNotifier.clearActiveGoals();
  }

  Future<void> createGoal({
    required BuildContext context,
    required ThemeBundle bundle,
    required SoundService soundService,
    required void Function() syncGoalsCompletedToday,
    required bool Function() isMounted,
  }) async {
    if (stepsController.text == '') {
      stepsController.text = '1';
    }
    if (!formKey.currentState!.validate()) return;

    final hours = int.tryParse(deadlineController.text.trim()) ?? 0;
    final ui = getUiState();
    final title = titleController.text.trim();
    await goalsNotifier.createGoal(
      title: title,
      category: ui.category,
      complexity: ui.complexity,
      effort: ui.effort,
      motivation: ui.motivation,
      time: timeController.text,
      steps: stepsController.text,
      deadlineHours: hours,
      anchor: anchorDate,
    );
    resetControllers();
    if (!isMounted()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted()) return;
      syncGoalsCompletedToday();
      soundService.playGoalCreated();
      CommonUtils.showSnackBar(
        context,
        'Goal "$title" created!',
        bundle.textStyle,
        2500,
        12,
        backgroundColor: bundle.secondaryColor,
        labelColor: bundle.primaryColor,
      );
    });
  }
}
