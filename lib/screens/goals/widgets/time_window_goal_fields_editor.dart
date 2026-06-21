import 'package:flutter/material.dart';
import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Category, complexity, effort, motivation, title, minutes, and steps.
class TimeWindowGoalFieldsEditor extends StatelessWidget {
  const TimeWindowGoalFieldsEditor({
    super.key,
    required this.bundle,
    required this.titleController,
    required this.timeController,
    required this.stepsController,
    required this.category,
    required this.complexity,
    required this.effort,
    required this.motivation,
    required this.onCategoryChanged,
    required this.onComplexityChanged,
    required this.onEffortChanged,
    required this.onMotivationChanged,
    this.showTitleField = true,
  });

  final ThemeBundle bundle;
  final TextEditingController titleController;
  final TextEditingController timeController;
  final TextEditingController stepsController;
  final String category;
  final String complexity;
  final String effort;
  final String motivation;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onComplexityChanged;
  final ValueChanged<String?> onEffortChanged;
  final ValueChanged<String?> onMotivationChanged;
  final bool showTitleField;

  static const _levels = ['Low', 'Medium', 'High'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommonUtils.buildDropdownButtonFormField(
          'Category',
          category,
          kGoalCategories,
          bundle.textStyle,
          bundle.secondaryColor,
          onCategoryChanged,
        ),
        CommonUtils.buildDropdownButtonFormField(
          'Complexity',
          complexity,
          _levels,
          bundle.textStyle,
          bundle.secondaryColor,
          onComplexityChanged,
        ),
        CommonUtils.buildDropdownButtonFormField(
          'Effort Required',
          effort,
          _levels,
          bundle.textStyle,
          bundle.secondaryColor,
          onEffortChanged,
        ),
        CommonUtils.buildDropdownButtonFormField(
          'Motivation Needed',
          motivation,
          _levels,
          bundle.textStyle,
          bundle.secondaryColor,
          onMotivationChanged,
        ),
        if (showTitleField)
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
            final parsed = int.tryParse(v?.trim() ?? '');
            if (parsed == null || parsed < 1) {
              return 'Please enter a valid whole number';
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
          (v) {
            final trimmed = v?.trim();
            final parsed = int.tryParse(
              trimmed?.isEmpty ?? true ? '1' : trimmed!,
            );
            if (parsed == null || parsed < 1) {
              return 'Please enter a valid whole number above 0';
            }
            return null;
          },
        ),
      ],
    );
  }
}
