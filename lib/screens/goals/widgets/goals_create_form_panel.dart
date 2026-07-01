import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/screens/goals/widgets/goals_create_fields_section.dart';
import 'package:focusNexus/screens/goals/widgets/goals_list_filters_section.dart';

/// Composes goal create fields and list filter controls for the goals screen.
class GoalsCreateFormPanel extends StatelessWidget {
  const GoalsCreateFormPanel({
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
    required this.onCategoryFilterChanged,
    required this.onComplexityFilterChanged,
    required this.onStatusFilterChanged,
    required this.onSortByChanged,
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
  final ValueChanged<String?> onCategoryFilterChanged;
  final ValueChanged<String?> onComplexityFilterChanged;
  final ValueChanged<String?> onStatusFilterChanged;
  final ValueChanged<String?> onSortByChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoalsCreateFieldsSection(
          formKey: formKey,
          titleController: titleController,
          timeController: timeController,
          deadlineController: deadlineController,
          stepsController: stepsController,
          categories: categories,
          levels: levels,
          templateNames: templateNames,
          templateDetails: templateDetails,
          uiState: uiState,
          bundle: bundle,
          onTemplateSelected: onTemplateSelected,
          onCategoryChanged: onCategoryChanged,
          onComplexityChanged: onComplexityChanged,
          onEffortChanged: onEffortChanged,
          onMotivationChanged: onMotivationChanged,
          onCreateGoal: onCreateGoal,
          onClearGoals: onClearGoals,
          onClearCompleteGoals: onClearCompleteGoals,
          onOpenMultiTemplateManager: onOpenMultiTemplateManager,
          onOpenTemplateManager: onOpenTemplateManager,
        ),
        const SizedBox(height: 20),
        GoalsListFiltersSection(
          uiState: uiState,
          bundle: bundle,
          categories: categories,
          levels: levels,
          onCategoryFilterChanged: onCategoryFilterChanged,
          onComplexityFilterChanged: onComplexityFilterChanged,
          onStatusFilterChanged: onStatusFilterChanged,
          onSortByChanged: onSortByChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
