import 'package:flutter/material.dart';

import 'package:focusNexus/goals/builtin_goal_templates.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/goals/template_group_cleanup.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/screens/goals/widgets/goals_multi_template_manager_dialog.dart';
import 'package:focusNexus/screens/goals/widgets/goals_template_manager_dialog.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Template CRUD, bulk create, and multi-template group sync for the goals screen.
class GoalsTemplateController {
  GoalsTemplateController({
    required this.repos,
    required this.uiNotifier,
    required this.goalsNotifier,
    required this.templateDetails,
    required this.categories,
    required this.levels,
    required this.anchorDate,
    required this.templateNameController,
    required this.templateTimeController,
    required this.templateStepsController,
    required this.templateDeadlineController,
    required this.titleController,
    required this.timeController,
    required this.deadlineController,
    required this.stepsController,
    required this.getUiState,
    required this.isMounted,
  });

  final AppRepositories repos;
  final GoalsScreenUiNotifier uiNotifier;
  final GoalsNotifier goalsNotifier;
  final Map<String, Map<String, dynamic>> templateDetails;
  final List<String> categories;
  final List<String> levels;
  final DateTime anchorDate;
  final TextEditingController templateNameController;
  final TextEditingController templateTimeController;
  final TextEditingController templateStepsController;
  final TextEditingController templateDeadlineController;
  final TextEditingController titleController;
  final TextEditingController timeController;
  final TextEditingController deadlineController;
  final TextEditingController stepsController;
  final GoalsScreenUiState Function() getUiState;
  final bool Function() isMounted;

  Future<void> loadTemplates() async {
    final templates = await repos.templates.readUserTemplates();
    uiNotifier.update(
      (state) => state.copyWith(
        userTemplates: Map<String, Map<String, dynamic>>.from(templates),
      ),
    );
  }

  Future<void> loadTemplateGroups() async {
    final groups = await repos.templates.readTemplateGroups();
    uiNotifier.update(
      (state) => state.copyWith(
        templateGroups: Map<String, List<String>>.from(groups),
      ),
    );
  }

  Future<void> saveTemplates([
    Map<String, Map<String, dynamic>>? templates,
  ]) async {
    await repos.templates.writeUserTemplates(templates ?? getUiState().userTemplates);
  }

  Future<void> preSaveTemplate({
    required GlobalKey<FormState> templateFormKey,
    required BuildContext context,
    required ThemeBundle bundle,
  }) async {
    if (!templateFormKey.currentState!.validate()) return;
    if (templateStepsController.text.trim() == '') {
      templateStepsController.text = '1';
    }
    final ui = getUiState();
    final name = templateNameController.text.trim();
    final data = {
      'category': ui.templateDialogCategory,
      'complexity': ui.templateDialogComplexity,
      'effort': ui.templateDialogEffort,
      'motivation': ui.templateDialogMotivation,
      'time': templateTimeController.text.trim(),
      'steps': templateStepsController.text.trim(),
      'Hours to complete': templateDeadlineController.text.trim(),
    };
    final updatedUserTemplates = Map<String, Map<String, dynamic>>.from(
      ui.userTemplates,
    );
    if (templateDetails.containsKey(name)) {
      templateDetails[name] = data;
    } else {
      updatedUserTemplates[name] = data;
    }
    uiNotifier.update(
      (state) => state.copyWith(userTemplates: updatedUserTemplates),
    );
    await saveTemplates(updatedUserTemplates);

    if (!isMounted()) return;
    if (!context.mounted) return;
    CommonUtils.showDialogWidget(
      context,
      'Template "$name" saved.',
      bundle.textStyle,
      bundle.secondaryColor,
    );
  }

  Future<TemplateGroupCleanupResult> pruneTemplateGroups() async {
    final validTemplateNames = {
      ...templateDetails.keys,
      ...getUiState().userTemplates.keys,
    };

    final result = cleanupTemplateGroups(
      groups: getUiState().templateGroups,
      validTemplateNames: validTemplateNames,
    );

    uiNotifier.update(
      (state) => state.copyWith(templateGroups: result.updatedGroups),
    );
    await repos.templates.writeTemplateGroups(result.updatedGroups);
    return result;
  }

  Future<void> validateTemplateGroups({
    required BuildContext context,
    required ThemeBundle bundle,
  }) async {
    final result = await pruneTemplateGroups();
    if (!isMounted() || !result.hasChanges) return;
    if (!context.mounted) return;
    CommonUtils.showBasicAlertDialog(
      context,
      'Multi-template groups updated',
      templateGroupCleanupMessage(result),
      bundle.textStyle,
      bundle.secondaryColor,
    );
  }

  void openTemplateManager({
    required BuildContext context,
    required ThemeBundle bundle,
    required void Function(BuildContext dialogContext) onDismiss,
  }) {
    uiNotifier.update(
      (state) => state.copyWith(
        templateDialogCategory: categories.first,
        templateDialogComplexity: levels.first,
        templateDialogEffort: levels.first,
        templateDialogMotivation: levels.first,
      ),
    );
    final templateFormKey = GlobalKey<FormState>();

    GoalsTemplateManagerDialog.show(
      context,
      templateFormKey: templateFormKey,
      templateNameController: templateNameController,
      templateTimeController: templateTimeController,
      templateStepsController: templateStepsController,
      templateDeadlineController: templateDeadlineController,
      categories: categories,
      levels: levels,
      templateDetails: templateDetails,
      onSaveTemplate:
          (key) => preSaveTemplate(
            templateFormKey: key,
            context: context,
            bundle: bundle,
          ),
      onDismiss: onDismiss,
      onDeleteUserTemplate: (name) async {
        final updatedTemplates = Map<String, Map<String, dynamic>>.from(
          getUiState().userTemplates,
        )..remove(name);
        uiNotifier.update(
          (state) => state.copyWith(userTemplates: updatedTemplates),
        );
        await saveTemplates(updatedTemplates);
        if (!context.mounted) return;
        await validateTemplateGroups(context: context, bundle: bundle);
      },
      onTemplateSelected: (name, templateData) {
        templateNameController.text = name;
        templateTimeController.text = templateData['time'] as String;
        templateDeadlineController.text =
            templateData['Hours to complete'] as String;
        templateStepsController.text = templateData['steps'] as String;
        uiNotifier.update(
          (state) => state.copyWith(
            templateDialogCategory: templateData['category'] as String,
            templateDialogComplexity: templateData['complexity'] as String,
            templateDialogEffort: templateData['effort'] as String,
            templateDialogMotivation: templateData['motivation'] as String,
          ),
        );
      },
    );
  }

  void openMultiTemplateManager({
    required BuildContext context,
    required ThemeBundle bundle,
    required Future<void> Function() onPlayGoalCreated,
    required void Function() syncGoalsCompletedToday,
    required void Function(BuildContext dialogContext) onDismiss,
  }) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => GoalsMultiTemplateManagerDialog(
            templateDetails: templateDetails,
            onCreateGoals:
                (names) => createGoalsFromTemplatesBulk(
                  context: context,
                  bundle: bundle,
                  templateNames: names,
                  onPlayGoalCreated: onPlayGoalCreated,
                  syncGoalsCompletedToday: syncGoalsCompletedToday,
                ),
            onDismiss: () => onDismiss(dialogContext),
          ),
    );
  }

  void onTemplateSelected(String templateName) {
    titleController.text = templateName;
    final data =
        templateDetails[templateName] ?? getUiState().userTemplates[templateName]!;
    uiNotifier.update(
      (state) => state.copyWith(
        category: data['category'] as String,
        complexity: data['complexity'] as String,
        effort: data['effort'] as String,
        motivation: data['motivation'] as String,
      ),
    );
    timeController.text = data['time'] as String;
    deadlineController.text = data['Hours to complete'] as String;
    stepsController.text = data['steps'] as String;
  }

  Future<void> createGoalsFromTemplatesBulk({
    required BuildContext context,
    required ThemeBundle bundle,
    required List<String> templateNames,
    required Future<void> Function() onPlayGoalCreated,
    required void Function() syncGoalsCompletedToday,
  }) async {
    if (templateNames.isEmpty) {
      CommonUtils.showBasicAlertDialog(
        context,
        'No templates Selected',
        'Please select at least one template to create goals from.',
        bundle.textStyle,
        bundle.secondaryColor,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            backgroundColor: bundle.secondaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Goals are being created.',
                style: bundle.textStyle,
              ),
            ),
          ),
    );

    try {
      final inputs = buildBulkCreateInputs(
        templateNames: templateNames,
        userTemplates: getUiState().userTemplates,
      );

      await goalsNotifier.createGoals(inputs: inputs, anchor: anchorDate);
      syncGoalsCompletedToday();
      await onPlayGoalCreated();
    } finally {
      if (isMounted() && context.mounted) {
        CommonUtils.dismissKeyboard();
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    }

    if (!isMounted()) return;
    if (!context.mounted) return;
    CommonUtils.showDialogWidget(
      context,
      'Goals created from selected templates.',
      bundle.textStyle,
      bundle.secondaryColor,
    );
  }

  /// Builds create inputs for [templateNames] from built-in and user templates.
  List<CreateGoalInput> buildBulkCreateInputs({
    required List<String> templateNames,
    required Map<String, Map<String, dynamic>> userTemplates,
  }) {
    return [
      for (final templateName in templateNames)
        () {
          final data =
              templateDetails[templateName] ?? userTemplates[templateName]!;
          return CreateGoalInput(
            title: templateName,
            category: data['category'] as String,
            complexity: data['complexity'] as String,
            effort: data['effort'] as String,
            motivation: data['motivation'] as String,
            time: data['time'] as String,
            steps: data['steps'] as String,
            deadlineHours:
                int.tryParse((data['Hours to complete'] as String?) ?? '') ?? 0,
          );
        }(),
    ];
  }
}

/// Built-in templates map owned by the goals screen for the session.
Map<String, Map<String, dynamic>> createBuiltinTemplateDetails() {
  return Map<String, Map<String, dynamic>>.from(builtinGoalTemplates);
}
