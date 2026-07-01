import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';

class GoalsMultiTemplateManagerDialog extends ConsumerStatefulWidget {
  const GoalsMultiTemplateManagerDialog({
    super.key,
    required this.templateDetails,
    required this.onCreateGoals,
    required this.onDismiss,
  });

  final Map<String, Map<String, dynamic>> templateDetails;
  final Future<void> Function(List<String> templateNames) onCreateGoals;
  final VoidCallback onDismiss;

  @override
  ConsumerState<GoalsMultiTemplateManagerDialog> createState() =>
      _GoalsMultiTemplateManagerDialogState();
}

class _GoalsMultiTemplateManagerDialogState
    extends ConsumerState<GoalsMultiTemplateManagerDialog> {
  late final TextEditingController _groupNameController;
  List<String> _selectedTemplates = [];
  String? _selectedGroup;
  String? _validationMessage;

  GoalsScreenUiNotifier get _uiNotifier =>
      ref.read(goalsScreenUiProvider.notifier);

  Future<void> _saveTemplateGroups(Map<String, List<String>> groups) async {
    await ref.read(appRepositoriesProvider).templates.writeTemplateGroups(groups);
  }

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(themeBundleProvider);
    final ui = ref.watch(goalsScreenUiProvider);
    final allTemplateNames = [
      ...widget.templateDetails.keys,
      ...ui.userTemplates.keys,
    ];

    return AlertDialog(
      backgroundColor: bundle.secondaryColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text('Select Multiple Templates', style: bundle.textStyle),
      content: CommonUtils.scrollableDialogBody(
        context: context,
        children: [
          KeyedSubtree(
            key: ValueKey('template-groups-${ui.templateGroups.keys.join('|')}'),
            child: CommonUtils.buildDropdownButtonFormField(
              'Load Saved Group',
              _selectedGroup,
              ui.templateGroups.keys.toList(),
              bundle.textStyle,
              bundle.secondaryColor,
              (groupName) {
                setState(() {
                  _selectedGroup = groupName;
                  _selectedTemplates = List.from(
                    ui.templateGroups[groupName!] ?? [],
                  );
                  _groupNameController.text = groupName;
                  _validationMessage = null;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          CommonUtils.buildTextFormField(
            _groupNameController,
            'Group Name (required to save/update)',
            bundle.textStyle,
            bundle.secondaryColor,
            false,
            (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Group name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Select Templates to Create Goals:',
            style: bundle.textStyle,
          ),
          ...allTemplateNames.map((templateName) {
            final selected = _selectedTemplates.contains(templateName);
            return CommonUtils.buildCheckboxListTile(
              title: templateName,
              textStyle: bundle.textStyle,
              value: selected,
              activeColor: bundle.primaryColor,
              checkColor: bundle.secondaryColor,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedTemplates.add(templateName);
                  } else {
                    _selectedTemplates.remove(templateName);
                  }
                  _validationMessage = null;
                });
              },
            );
          }),
          const Divider(),
          Text('Existing Groups:', style: bundle.textStyle),
          ...ui.templateGroups.keys.map((name) {
            return CommonUtils.buildListTile(
              title: name,
              textStyle: bundle.textStyle,
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                color: bundle.primaryColor,
                onPressed: () async {
                  final updatedGroups = Map<String, List<String>>.from(
                    ui.templateGroups,
                  )..remove(name);
                  _uiNotifier.update(
                    (state) => state.copyWith(templateGroups: updatedGroups),
                  );
                  await _saveTemplateGroups(updatedGroups);
                  if (!mounted) return;
                  setState(() {
                    if (_selectedGroup == name) {
                      _selectedGroup = null;
                      _selectedTemplates = [];
                      _groupNameController.clear();
                    }
                    _validationMessage = null;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _selectedGroup = name;
                  _selectedTemplates = List.from(ui.templateGroups[name]!);
                  _groupNameController.text = name;
                  _validationMessage = null;
                });
              },
            );
          }),
          if (_validationMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationMessage!,
              style: bundle.textStyle.copyWith(color: Colors.purple),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              CommonUtils.buildTextButton(
                widget.onDismiss,
                'Cancel',
                bundle.textStyle,
              ),
              CommonUtils.buildTextButton(
                () async {
                  final groupName = _groupNameController.text.trim();
                  if (groupName.isEmpty || _selectedTemplates.isEmpty) {
                    setState(() {
                      _validationMessage =
                          'Please enter a group name and select at least one template.';
                    });
                    return;
                  }

                  final updatedGroups = Map<String, List<String>>.from(
                    ui.templateGroups,
                  )..[groupName] = List.from(_selectedTemplates);
                  _uiNotifier.update(
                    (state) => state.copyWith(templateGroups: updatedGroups),
                  );
                  await _saveTemplateGroups(updatedGroups);
                  if (!mounted) return;
                  setState(() {
                    _selectedGroup = groupName;
                    _validationMessage = null;
                  });
                  if (!context.mounted) return;
                  CommonUtils.showDialogWidget(
                    context,
                    '$groupName has been updated.',
                    bundle.textStyle,
                    bundle.secondaryColor,
                  );
                },
                'Save/Update Group',
                bundle.textStyle,
              ),
            ],
          ),
          CommonUtils.buildElevatedButton(
            'Create Goals',
            bundle.primaryColor,
            bundle.secondaryColor,
            bundle.textStyle,
            0,
            0,
            () async {
              if (_selectedTemplates.isEmpty) {
                CommonUtils.showBasicAlertDialog(
                  context,
                  'No templates Selected',
                  'Please select at least one template to create goals from.',
                  bundle.textStyle,
                  bundle.secondaryColor,
                );
                return;
              }
              await widget.onCreateGoals(_selectedTemplates);
            },
            borderColor: bundle.accentColor,
          ),
        ],
      ),
      actions: const [],
    );
  }
}
