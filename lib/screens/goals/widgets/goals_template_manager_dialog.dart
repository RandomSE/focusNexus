import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/goals/goal_field_validators.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';

class GoalsTemplateManagerDialog extends ConsumerStatefulWidget {
  const GoalsTemplateManagerDialog({
    super.key,
    required this.dialogContext,
    required this.templateFormKey,
    required this.templateNameController,
    required this.templateTimeController,
    required this.templateStepsController,
    required this.templateDeadlineController,
    required this.categories,
    required this.levels,
    required this.templateDetails,
    required this.onSaveTemplate,
    required this.onDismiss,
    required this.onDeleteUserTemplate,
    required this.onTemplateSelected,
  });

  final BuildContext dialogContext;
  final GlobalKey<FormState> templateFormKey;
  final TextEditingController templateNameController;
  final TextEditingController templateTimeController;
  final TextEditingController templateStepsController;
  final TextEditingController templateDeadlineController;
  final List<String> categories;
  final List<String> levels;
  final Map<String, Map<String, dynamic>> templateDetails;

  /// Returns a user-facing validation message when save is blocked; null on success.
  final Future<String?> Function(GlobalKey<FormState> templateFormKey)
      onSaveTemplate;
  final void Function(BuildContext dialogContext) onDismiss;
  final Future<void> Function(String name) onDeleteUserTemplate;
  final void Function(String name, Map<String, dynamic> data) onTemplateSelected;

  static Future<void> show(
    BuildContext context, {
    required GlobalKey<FormState> templateFormKey,
    required TextEditingController templateNameController,
    required TextEditingController templateTimeController,
    required TextEditingController templateStepsController,
    required TextEditingController templateDeadlineController,
    required List<String> categories,
    required List<String> levels,
    required Map<String, Map<String, dynamic>> templateDetails,
    required Future<String?> Function(GlobalKey<FormState> templateFormKey)
        onSaveTemplate,
    required void Function(BuildContext dialogContext) onDismiss,
    required Future<void> Function(String name) onDeleteUserTemplate,
    required void Function(String name, Map<String, dynamic> data)
        onTemplateSelected,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => GoalsTemplateManagerDialog(
        dialogContext: dialogContext,
        templateFormKey: templateFormKey,
        templateNameController: templateNameController,
        templateTimeController: templateTimeController,
        templateStepsController: templateStepsController,
        templateDeadlineController: templateDeadlineController,
        categories: categories,
        levels: levels,
        templateDetails: templateDetails,
        onSaveTemplate: onSaveTemplate,
        onDismiss: onDismiss,
        onDeleteUserTemplate: onDeleteUserTemplate,
        onTemplateSelected: onTemplateSelected,
      ),
    );
  }

  @override
  ConsumerState<GoalsTemplateManagerDialog> createState() =>
      _GoalsTemplateManagerDialogState();
}

class _GoalsTemplateManagerDialogState
    extends ConsumerState<GoalsTemplateManagerDialog> {
  String? _validationMessage;

  Future<void> _onSavePressed() async {
    final message = await widget.onSaveTemplate(widget.templateFormKey);
    if (!mounted) return;
    setState(() => _validationMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(themeBundleProvider);
    final ui = ref.watch(goalsScreenUiProvider);
    final uiNotifier = ref.read(goalsScreenUiProvider.notifier);
    final allTemplateNames = [
      ...widget.templateDetails.keys,
      ...ui.userTemplates.keys,
    ];
    var minutesRequired = 0;
    var minutesToDeadline = 0;

    return AlertDialog(
      backgroundColor: bundle.secondaryColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text('Manage Templates', style: bundle.textStyle),
      content: CommonUtils.scrollableDialogBody(
        context: context,
        children: [
          Form(
            key: widget.templateFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonUtils.buildTextFormField(
                  widget.templateNameController,
                  'Template Name (required)',
                  bundle.textStyle,
                  bundle.secondaryColor,
                  true,
                  (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Template name is required';
                    }
                    return null;
                  },
                ),
                CommonUtils.buildDropdownButtonFormField(
                  'Category',
                  ui.templateDialogCategory,
                  widget.categories,
                  bundle.textStyle,
                  bundle.secondaryColor,
                  (v) => uiNotifier.update(
                    (state) => state.copyWith(
                      templateDialogCategory: v ?? widget.categories.first,
                    ),
                  ),
                ),
                CommonUtils.buildDropdownButtonFormField(
                  'Complexity',
                  ui.templateDialogComplexity,
                  widget.levels,
                  bundle.textStyle,
                  bundle.secondaryColor,
                  (v) => uiNotifier.update(
                    (state) => state.copyWith(
                      templateDialogComplexity: v ?? widget.levels.first,
                    ),
                  ),
                ),
                CommonUtils.buildDropdownButtonFormField(
                  'Effort',
                  ui.templateDialogEffort,
                  widget.levels,
                  bundle.textStyle,
                  bundle.secondaryColor,
                  (v) => uiNotifier.update(
                    (state) => state.copyWith(
                      templateDialogEffort: v ?? widget.levels.first,
                    ),
                  ),
                ),
                CommonUtils.buildDropdownButtonFormField(
                  'Motivation',
                  ui.templateDialogMotivation,
                  widget.levels,
                  bundle.textStyle,
                  bundle.secondaryColor,
                  (v) => uiNotifier.update(
                    (state) => state.copyWith(
                      templateDialogMotivation: v ?? widget.levels.first,
                    ),
                  ),
                ),
                CommonUtils.buildTextFormField(
                  widget.templateTimeController,
                  'Time (minutes, required)',
                  bundle.textStyle,
                  bundle.secondaryColor,
                  true,
                  (v) {
                    final error = GoalFieldValidators.timeMinutes(v);
                    if (error != null) return error;
                    minutesRequired = int.parse(v!.trim());
                    return null;
                  },
                  keyboardType: TextInputType.number,
                ),
                CommonUtils.buildTextFormField(
                  widget.templateDeadlineController,
                  'Hours to complete (optional)',
                  bundle.textStyle,
                  bundle.secondaryColor,
                  true,
                  (v) {
                    if (v == null || v.trim().isEmpty) {
                      return null;
                    }
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed <= 0 || parsed > 10000) {
                      return 'Must be a whole number > 0 and < 10000';
                    }
                    minutesToDeadline = parsed * 60;
                    if (minutesRequired > minutesToDeadline) {
                      return 'Deadline must be greater than time required.';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                ),
                CommonUtils.buildTextFormField(
                  widget.templateStepsController,
                  'Steps (Required)',
                  bundle.textStyle,
                  bundle.secondaryColor,
                  true,
                  GoalFieldValidators.steps,
                ),
                if (_validationMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validationMessage!,
                    style: bundle.textStyle.copyWith(color: Colors.purple),
                    softWrap: true,
                    maxLines: 8,
                    overflow: TextOverflow.visible,
                  ),
                ],
                CommonUtils.buildElevatedButton(
                  'Save Template',
                  bundle.primaryColor,
                  bundle.secondaryColor,
                  bundle.textStyle,
                  14,
                  10,
                  _onSavePressed,
                  borderColor: bundle.accentColor,
                ),
                const Divider(),
                Text('Templates:', style: bundle.textStyle),
                ...allTemplateNames.map(
                  (name) => CommonUtils.buildListTile(
                    title: name,
                    textStyle: bundle.textStyle,
                    trailing: ui.userTemplates.containsKey(name)
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => widget.onDeleteUserTemplate(name),
                          )
                        : null,
                    onTap: () {
                      final templateData = widget.templateDetails[name] ??
                          ui.userTemplates[name]!;
                      setState(() => _validationMessage = null);
                      widget.onTemplateSelected(name, templateData);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => widget.onDismiss(widget.dialogContext),
              child: Text('Close', style: bundle.textStyle),
            ),
          ),
        ],
      ),
      actions: const [],
    );
  }
}
