import 'package:flutter/material.dart';

import 'package:focusNexus/goals/goal_field_validators.dart';
import 'package:focusNexus/goals/goal_points_labels.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/goal_points.dart';

/// Goal create form fields and action buttons (template through Manage Templates).
class GoalsCreateFieldsSection extends StatelessWidget {
  const GoalsCreateFieldsSection({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.timeController,
    required this.deadlineController,
    required this.stepsController,
    required this.categories,
    required this.levels,
    required this.templateNames,
    required this.templateDetails,
    required this.uiState,
    required this.bundle,
    required this.onTemplateSelected,
    required this.onCategoryChanged,
    required this.onComplexityChanged,
    required this.onEffortChanged,
    required this.onMotivationChanged,
    required this.onCreateGoal,
    required this.onClearGoals,
    required this.onClearCompleteGoals,
    required this.onOpenMultiTemplateManager,
    required this.onOpenTemplateManager,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController timeController;
  final TextEditingController deadlineController;
  final TextEditingController stepsController;
  final List<String> categories;
  final List<String> levels;
  final List<String> templateNames;
  final Map<String, Map<String, dynamic>> templateDetails;
  final GoalsScreenUiState uiState;
  final ThemeBundle bundle;
  final ValueChanged<String> onTemplateSelected;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onComplexityChanged;
  final ValueChanged<String?> onEffortChanged;
  final ValueChanged<String?> onMotivationChanged;
  final VoidCallback onCreateGoal;
  final VoidCallback onClearGoals;
  final VoidCallback onClearCompleteGoals;
  final VoidCallback onOpenMultiTemplateManager;
  final VoidCallback onOpenTemplateManager;

  @override
  Widget build(BuildContext context) {
    var minutesRequired = 0;
    var minutesToDeadline = 0;

    return Form(
      key: formKey,
      child: Column(
        children: [
          KeyedSubtree(
            key: ValueKey(
              'goal-templates-${templateDetails.length}-${uiState.userTemplates.length}-${uiState.userTemplates.keys.join('|')}',
            ),
            child: CommonUtils.buildDropdownButtonFormField(
              'Template (optional)',
              templateNames.contains(uiState.selectedTemplate)
                  ? uiState.selectedTemplate
                  : null,
              templateNames,
              bundle.textStyle,
              bundle.secondaryColor,
              (val) {
                if (val == null) return;
                onTemplateSelected(val);
              },
              pinLabelToTop: true,
            ),
          ),
          CommonUtils.buildDropdownButtonFormField(
            'Category',
            uiState.category,
            categories,
            bundle.textStyle,
            bundle.secondaryColor,
            onCategoryChanged,
          ),
          CommonUtils.buildDropdownButtonFormField(
            'Complexity',
            uiState.complexity,
            levels,
            bundle.textStyle,
            bundle.secondaryColor,
            onComplexityChanged,
          ),
          CommonUtils.buildDropdownButtonFormField(
            'Effort Required',
            uiState.effort,
            levels,
            bundle.textStyle,
            bundle.secondaryColor,
            onEffortChanged,
          ),
          CommonUtils.buildDropdownButtonFormField(
            'Motivation Needed',
            uiState.motivation,
            levels,
            bundle.textStyle,
            bundle.secondaryColor,
            onMotivationChanged,
          ),
          CommonUtils.buildTextFormField(
            titleController,
            'Goal Title',
            bundle.textStyle,
            bundle.secondaryColor,
            true,
            (v) => v == null || v.isEmpty ? 'Title required' : null,
          ),
          CommonUtils.buildTextFormField(
            timeController,
            'Time Required in minutes',
            bundle.textStyle,
            bundle.secondaryColor,
            true,
            (v) {
              final error = GoalFieldValidators.timeMinutes(v);
              if (error != null) return error;
              minutesRequired = int.parse(v!.trim());
              return null;
            },
          ),
          CommonUtils.buildTextFormField(
            deadlineController,
            'Hours to complete (optional)',
            bundle.textStyle,
            bundle.secondaryColor,
            true,
            (v) {
              if (v == null || v.trim().isEmpty) {
                return null;
              }
              final parsed = int.tryParse(v);
              if (parsed == null || parsed <= 0 || parsed > 9999) {
                return 'Must be a whole number > 0 and < 10000';
              }
              minutesToDeadline = parsed * 60;
              if (minutesRequired > minutesToDeadline) {
                return 'Deadline must be greater than time required.';
              }
              return null;
            },
          ),
          CommonUtils.buildTextFormField(
            stepsController,
            'Steps (Required)',
            bundle.textStyle,
            bundle.secondaryColor,
            true,
            GoalFieldValidators.steps,
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              timeController,
              stepsController,
              deadlineController,
            ]),
            builder: (context, _) {
              final timeText = timeController.text.trim();
              final stepsText = stepsController.text.trim().isEmpty
                  ? '1'
                  : stepsController.text.trim();
              final timeOk = GoalFieldValidators.timeMinutes(timeText) == null;
              final stepsOk = GoalFieldValidators.steps(stepsText) == null;
              if (!timeOk || !stepsOk) {
                return const SizedBox.shrink();
              }
              final deadlineRaw = deadlineController.text.trim();
              final deadline = deadlineRaw.isEmpty ||
                      (int.tryParse(deadlineRaw) ?? 0) <= 0
                  ? 'no deadline'
                  : 'deadline';
              final stored = GoalPoints.calculatePointsFromTemplate(
                complexity: uiState.complexity,
                effort: uiState.effort,
                motivation: uiState.motivation,
                time: timeText,
                steps: stepsText,
                deadline: deadline,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  activeGoalDetailPointsLabel(stored),
                  style: bundle.textStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          CommonUtils.buildElevatedButton(
            'Add Goal',
            bundle.primaryColor,
            bundle.secondaryColor,
            bundle.textStyle,
            5,
            5,
            onCreateGoal,
            borderColor: bundle.accentColor,
          ),
          CommonUtils.buildElevatedButton(
            'Clear Active Goals',
            bundle.primaryColor,
            bundle.secondaryColor,
            bundle.textStyle,
            5,
            5,
            onClearGoals,
            borderColor: bundle.accentColor,
          ),
          CommonUtils.buildElevatedButton(
            'Clear Completed Goals',
            bundle.primaryColor,
            bundle.secondaryColor,
            bundle.textStyle,
            5,
            5,
            onClearCompleteGoals,
            borderColor: bundle.accentColor,
          ),
          CommonUtils.buildElevatedButton(
            'Manage Multi-templates',
            bundle.primaryColor,
            bundle.secondaryColor,
            bundle.textStyle,
            5,
            5,
            onOpenMultiTemplateManager,
            borderColor: bundle.accentColor,
          ),
          CommonUtils.buildElevatedButton(
            'Manage Templates',
            bundle.primaryColor,
            bundle.secondaryColor,
            bundle.textStyle,
            5,
            5,
            onOpenTemplateManager,
            borderColor: bundle.accentColor,
          ),
        ],
      ),
    );
  }
}
