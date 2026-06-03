// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

import '../goals/builtin_goal_templates.dart';
import '../goals/goals_controller.dart';
import '../goals/goals_filter_sort.dart';
import '../goals/goals_use_case.dart';
import '../repositories/app_repositories.dart';
import '../services/sound_service.dart';
import '../models/classes/theme_bundle.dart';
import '../models/classes/goal_set.dart';
import '../utils/common_utils.dart';
import '../utils/screen_theme.dart';
import '../widgets/deferred_screen.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/settings_themed_builder.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  AppRepositories get _repos => AppRepositories.instance;
  GoalsController get _goals => _repos.goalsController;
  ThemeBundle get themeBundle =>
      _repos.theme.bundleFromSnapshot(_repos.settings.snapshot);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _templateName = TextEditingController();
  final TextEditingController _templateTime = TextEditingController();
  final TextEditingController _templateSteps = TextEditingController();
  final TextEditingController _templateDeadline = TextEditingController();
  String _selectedCategoryFilter = 'All';
  String _selectedComplexityFilter = 'All';
  String _selectedStatusFilter = 'Active';
  String _sortBy = 'None';
  String _category = 'Productivity';
  String _complexity = 'Low';
  String _effort = 'Low';
  final String today = DateFormat('dd MM yyyy').format(DateTime.now());
  int goalsCompletedToday = 0;
  String _motivation = 'Low';
  final _categories = [
    'Productivity',
    'Health',
    'Learning',
    'Social',
    'Self-care',
    'Work',
    'Relationships',
    'Other',
  ];
  final _levels = ['Low', 'Medium', 'High'];
  final Map<String, Map<String, dynamic>> _templateDetails =
      Map<String, Map<String, dynamic>>.from(builtinGoalTemplates);
  final DateTime _currentDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    DateTime.now().hour,
    DateTime.now().minute,
  );
  final DateFormat formatter = DateFormat('dd MMMM yyyy HH:mm');
  Map<String, Map<String, dynamic>> _userTemplates = {};
  Map<String, List<String>> _templateGroups = {};
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalsPage() async {
    _stepsController.text = '1';
    _templateSteps.text = '1';
    await _goals.load(now: _currentDate);
    await _loadTemplates();
    await _loadTemplateGroups();
    goalsCompletedToday = _goals.goalsCompletedToday;
  }

  void _dismissDialog(BuildContext dialogContext) {
    CommonUtils.dismissKeyboard();
    Navigator.pop(dialogContext);
  }

  Future<void> _loadTemplates() async {
    final templates = await _repos.templates.readUserTemplates();
    setState(() {
      _userTemplates = templates;
    });
  }

  Future<void> _saveTemplates() async {
    await _repos.templates.writeUserTemplates(_userTemplates);
    setState(() {});
  }

  List<GoalSet> get _filteredSortedGoals => filterAndSortGoals(
    source:
        _selectedStatusFilter == 'Active'
            ? _goals.activeGoals
            : _goals.completedGoals,
    categoryFilter: _selectedCategoryFilter,
    complexityFilter: _selectedComplexityFilter,
    sortBy: _sortBy,
    deadlineFormat: formatter,
  );

  Future<void> _clearGoals() => _goals.clearActiveGoals();

  Future<void> _clearCompleteGoals() => _goals.clearCompletedGoals();

  Future<void> _createGoal() async {
    if (_stepsController.text == '') {
      _stepsController.text = '1';
    }
    if (!_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_deadlineController.text.trim()) ?? 0;
    await _goals.createGoal(
      title: _titleController.text,
      category: _category,
      complexity: _complexity,
      effort: _effort,
      motivation: _motivation,
      time: _timeController.text,
      steps: _stepsController.text,
      deadlineHours: hours,
      anchor: _currentDate,
    );
    _resetControllers();
    goalsCompletedToday = _goals.goalsCompletedToday;
    SoundService.playGoalCreated();
  }

  void _resetControllers() {
    _titleController.clear();
    _timeController.clear();
    _deadlineController.clear();
    _stepsController.text = '1';
  }

  Future<void> _incrementStepProgress(int goalId) async {
    final result = await _goals.incrementStepProgress(goalId);
    if (result?.completed != null) {
      await _showGoalCompletedFeedback(result!.completed!);
    }
  }

  Future<void> _createGoalFromTemplates({
    required String title,
    required String category,
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required String deadlineHours,
  }) async {
    final hours = int.tryParse(deadlineHours) ?? 0;
    await _goals.createGoal(
      title: title,
      category: category,
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      deadlineHours: hours,
      anchor: _currentDate,
    );
    goalsCompletedToday = _goals.goalsCompletedToday;
  }

  Future<void> _createGoalsFromTemplatesBulk(List<String> templateNames) async {
    if (templateNames.isEmpty) {
      CommonUtils.showBasicAlertDialog(
        context,
        'No templates Selected',
        'Please select at least one template to create goals from.',
        themeBundle.textStyle,
        themeBundle.secondaryColor,
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            backgroundColor: themeBundle.secondaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Goals are being created.',
                style: themeBundle.textStyle,
              ),
            ),
          ),
    );

    try {
      final futures = <Future<void>>[];

      for (final templateName in templateNames) {
        final data =
            _templateDetails[templateName] ?? _userTemplates[templateName]!;

        futures.add(
          _createGoalFromTemplates(
            title: templateName,
            category: data['category'],
            complexity: data['complexity'],
            effort: data['effort'],
            motivation: data['motivation'],
            time: data['time'],
            steps: data['steps'],
            deadlineHours: data['Hours to complete'],
          ),
        );
      }

      await Future.wait(futures);
      SoundService.playGoalCreated();
    } finally {
      if (mounted) {
        CommonUtils.dismissKeyboard();
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    }

    if (!mounted) return;
    CommonUtils.showDialogWidget(
      context,
      'Goals created from selected templates.',
      themeBundle.textStyle,
      themeBundle.secondaryColor,
    );
  }

  Future<void> _completeGoal(int goalId) async {
    final result = await _goals.completeGoal(goalId);
    if (result == null) return;
    await _showGoalCompletedFeedback(result);
  }

  Future<void> _showGoalCompletedFeedback(CompleteGoalResult result) async {
    if (!mounted) return;
    goalsCompletedToday = result.goalsCompletedToday;
    SoundService.playGoalCompleted();
    _confettiController.play();
    CommonUtils.showSnackBar(
      context,
      '${result.goal.title} completed! +${result.pointsAwarded} points. '
      'Goals completed today: $goalsCompletedToday',
      themeBundle.textStyle,
      2000,
      5,
      backgroundColor: themeBundle.secondaryColor,
      labelColor: themeBundle.primaryColor,
    );
  }

  Future<void> _removeGoal(int goalId) => _goals.removeGoal(goalId);

  Future<void> _preSaveTemplate(
    String templateCategory,
    String templateComplexity,
    String templateEffort,
    String templateMotivation,
    GlobalKey<FormState> templateFormKey, {
    StateSetter? dialogSetState,
  }) async {
    if (!templateFormKey.currentState!.validate()) {
      return; // stop if validation fails
    }
    if (_templateSteps.text.trim() == '') {
      _templateSteps.text = '1';
    }
    final name = _templateName.text.trim();
    final data = {
      'category': templateCategory,
      'complexity': templateComplexity,
      'effort': templateEffort,
      'motivation': templateMotivation,
      'time': _templateTime.text.trim(),
      'steps': _templateSteps.text.trim(),
      'Hours to complete': _templateDeadline.text.trim(),
    };

    setState(() {
      if (_templateDetails.containsKey(name)) {
        _templateDetails[name] = data;
      } else {
        _userTemplates[name] = data;
      }
    });
    await _saveTemplates();
    dialogSetState?.call(() {});

    _templateName.clear();
    _templateTime.clear();
    _templateSteps.text = '1';
    _templateDeadline.clear();
  }

  void _viewGoalDetails(GoalSet goal) {
    showDialog(
      context: context,
      barrierColor: themeBundle.secondaryColor, // ✅ Sets overlay color
      builder:
          (_) => AlertDialog(
            backgroundColor: themeBundle.secondaryColor,
            iconColor: themeBundle.primaryColor,
            title: Text(goal.title, style: themeBundle.textStyle),
            content: Container(
              color: themeBundle.secondaryColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: ${goal.category}',
                    style: themeBundle.textStyle,
                  ),
                  Text(
                    'Complexity: ${goal.complexity}',
                    style: themeBundle.textStyle,
                  ),
                  Text('Effort: ${goal.effort}', style: themeBundle.textStyle),
                  Text(
                    'Motivation: ${goal.motivation}',
                    style: themeBundle.textStyle,
                  ),
                  Text(
                    'Time Needed in minutes: ${goal.time}',
                    style: themeBundle.textStyle,
                  ),
                  Text(
                    'Deadline: ${goal.deadline}',
                    style: themeBundle.textStyle,
                  ),
                  Text('Steps: ${goal.steps}', style: themeBundle.textStyle),
                  Text(
                    'Points: ${goal.points}',
                    style: themeBundle.textStyle,
                  ),
                  Text('Id: ${goal.goalId}', style: themeBundle.textStyle),
                ],
              ),
            ),
            actions: [
              Container(
                color: themeBundle.secondaryColor,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: themeBundle.textStyle),
                ),
              ),
            ],
          ),
    );
  }

  void _openTemplateManager() {
    String templateCategory = _categories.first;
    String templateComplexity = _levels.first;
    String templateEffort = _levels.first;
    String templateMotivation = _levels.first;

    int minutesRequired = 0;
    int minutesToDeadline = 0;

    final GlobalKey<FormState> templateFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, dialogSetState) => AlertDialog(
                  backgroundColor: themeBundle.secondaryColor,
                  title: Text('Manage Templates', style: themeBundle.textStyle),
                  content: SingleChildScrollView(
                    child: Container(
                      color: themeBundle.secondaryColor,
                      child: Form(
                        key: templateFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CommonUtils.buildTextFormField(
                              _templateName,
                              'Template Name (required)',
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
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
                              templateCategory,
                              _categories,
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
                              (v) =>
                                  dialogSetState(() => templateCategory = v!),
                            ),
                            CommonUtils.buildDropdownButtonFormField(
                              'Complexity',
                              templateComplexity,
                              _levels,
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
                              (v) =>
                                  dialogSetState(() => templateComplexity = v!),
                            ),
                            CommonUtils.buildDropdownButtonFormField(
                              'Effort',
                              templateEffort,
                              _levels,
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
                              (v) => dialogSetState(() => templateEffort = v!),
                            ),
                            CommonUtils.buildDropdownButtonFormField(
                              'Motivation',
                              templateMotivation,
                              _levels,
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
                              (v) =>
                                  dialogSetState(() => templateMotivation = v!),
                            ),
                            CommonUtils.buildTextFormField(
                              _templateTime,
                              'Time (minutes, required)',
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
                              true,
                              (v) {
                                final parsed = int.tryParse(v?.trim() ?? '');
                                if (parsed == null ||
                                    parsed < 1 ||
                                    parsed > 999) {
                                  return 'Please enter a whole number > 0 and < 1000';
                                }
                                minutesRequired = parsed;
                                return null;
                              },
                              keyboardType: TextInputType.number,
                            ),

                            CommonUtils.buildTextFormField(
                              _templateDeadline,
                              'Hours to complete (optional)',
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
                              true,
                              (v) {
                                if (v == null || v.trim().isEmpty)
                                  return null; // optional
                                final parsed = int.tryParse(v.trim());
                                if (parsed == null ||
                                    parsed <= 0 ||
                                    parsed > 10000) {
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
                              _templateSteps,
                              'Steps (Required)',
                              themeBundle.textStyle,
                              themeBundle.secondaryColor,
                              true,
                              (v) {
                                final trimmed = v?.trim();
                                final parsed = int.tryParse(
                                  trimmed?.isEmpty ?? true ? '1' : trimmed!,
                                );
                                if (parsed == null ||
                                    parsed < 1 ||
                                    parsed > 999) {
                                  return 'Please enter a valid whole number > 0 and smaller than 1000';
                                }
                                return null;
                              },
                            ),
                            CommonUtils.buildElevatedButton(
                              'Save Template',
                              themeBundle.primaryColor,
                              themeBundle.secondaryColor,
                              themeBundle.textStyle,
                              14,
                              10,
                              () => _preSaveTemplate(
                                templateCategory,
                                templateComplexity,
                                templateEffort,
                                templateMotivation,
                                templateFormKey,
                                dialogSetState: dialogSetState,
                              ),
                              borderColor: themeBundle.accentColor,
                            ),
                            const Divider(),
                            Text('Templates:', style: themeBundle.textStyle),
                            ...[
                              ..._templateDetails.keys,
                              ..._userTemplates.keys,
                            ].map(
                              (name) => CommonUtils.buildListTile(
                                title: name,
                                textStyle: themeBundle.textStyle,
                                trailing:
                                    _userTemplates.containsKey(name)
                                        ? IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () async {
                                            setState(() {
                                              _userTemplates.remove(name);
                                            });
                                            await _saveTemplates();
                                            await _validateTemplateGroups();
                                            dialogSetState(() {});
                                          },
                                        )
                                        : null,
                                onTap: () {
                                  final t =
                                      _templateDetails[name] ??
                                      _userTemplates[name]!;
                                  dialogSetState(() {
                                    _templateName.text = name;
                                    templateCategory = t['category'];
                                    templateComplexity = t['complexity'];
                                    templateEffort = t['effort'];
                                    templateMotivation = t['motivation'];
                                    _templateTime.text = t['time'];
                                    _templateDeadline.text =
                                        t['Hours to complete'];
                                    _templateSteps.text = t['steps'];
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => _dismissDialog(dialogContext),
                      child: Text('Close', style: themeBundle.textStyle),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _saveTemplateGroups() async {
    await _repos.templates.writeTemplateGroups(_templateGroups);
  }

  Future<void> _validateTemplateGroups() async {
    // Cleans up template groups with deleted templates.
    // Collect all valid template names
    final validTemplateNames = _userTemplates.keys.toSet();

    final Map<String, List<String>> updatedGroups = {};

    _templateGroups.forEach((groupName, templates) {
      // Keep only templates that still exist
      final validTemplates =
          templates.where((t) => validTemplateNames.contains(t)).toList();

      if (validTemplates.isEmpty) {
        debugPrint(
          'Group "$groupName" only contained deleted templates. Removing group.',
        );
        CommonUtils.showBasicAlertDialog(
          context,
          'Multi-template using deleted template(s)',
          '$groupName contained only deleted templates. Removing group.',
          themeBundle.textStyle,
          themeBundle.secondaryColor,
        );
        // skip this group entirely
      } else if (validTemplates.length < templates.length) {
        debugPrint(
          'Group "$groupName" had some deleted templates. Rebuilding with valid ones: $validTemplates',
        );
        CommonUtils.showBasicAlertDialog(
          context,
          'Multi-template using deleted template(s)',
          'Group "$groupName" had some deleted templates. Rebuilding with valid ones: $validTemplates',
          themeBundle.textStyle,
          themeBundle.secondaryColor,
        );
        updatedGroups[groupName] = validTemplates;
      } else {
        // all templates still valid
        updatedGroups[groupName] = templates;
      }
    });

    setState(() {
      _templateGroups = updatedGroups;
    });

    // persist the cleaned-up groups
    await _repos.templates.writeTemplateGroups(_templateGroups);
  }

  Future<void> _loadTemplateGroups() async {
    final groups = await _repos.templates.readTemplateGroups();
    setState(() {
      _templateGroups = groups;
    });
  }

  void _openMultiTemplateManager() {
    String? validationMessage;

    final TextEditingController groupNameController = TextEditingController();
    List<String> selectedTemplates = [];
    String? selectedGroup;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, dialogSetState) {
              return AlertDialog(
                backgroundColor: themeBundle.secondaryColor,
                title: Text(
                  'Select Multiple Templates',
                  style: themeBundle.textStyle,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KeyedSubtree(
                        key: ValueKey(
                          'template-groups-${_templateGroups.keys.join('|')}',
                        ),
                        child: CommonUtils.buildDropdownButtonFormField(
                          'Load Saved Group',
                          selectedGroup,
                          _templateGroups.keys.toList(),
                          themeBundle.textStyle,
                          themeBundle.secondaryColor,
                          (groupName) {
                            dialogSetState(() {
                              selectedGroup = groupName;
                              selectedTemplates = List.from(
                                _templateGroups[groupName!] ?? [],
                              );
                              groupNameController.text =
                                  groupName; // auto-fill name when loading group
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      CommonUtils.buildTextFormField(
                        groupNameController,
                        'Group Name (required to save/update)',
                        themeBundle.textStyle,
                        themeBundle.secondaryColor,
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
                        style: themeBundle.textStyle,
                      ),
                      ...[..._templateDetails.keys, ..._userTemplates.keys].map(
                        (templateName) {
                          final selected = selectedTemplates.contains(
                            templateName,
                          );
                          return CommonUtils.buildCheckboxListTile(
                            title: templateName,
                            textStyle: themeBundle.textStyle,
                            value: selected,
                            activeColor: themeBundle.primaryColor,
                            checkColor: themeBundle.secondaryColor,
                            onChanged: (bool? value) {
                              dialogSetState(() {
                                if (value == true) {
                                  selectedTemplates.add(templateName);
                                } else {
                                  selectedTemplates.remove(templateName);
                                }
                              });
                            },
                          );
                        },
                      ),
                      const Divider(),
                      Text('Existing Groups:', style: themeBundle.textStyle),
                      ..._templateGroups.keys.map((name) {
                        return CommonUtils.buildListTile(
                          title: name,
                          textStyle: themeBundle.textStyle,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            color: themeBundle.primaryColor,
                            onPressed: () async {
                              setState(() {
                                _templateGroups.remove(name);
                              });
                              await _saveTemplateGroups();
                              dialogSetState(() {
                                if (selectedGroup == name) {
                                  selectedGroup = null;
                                }
                              });
                            },
                          ),
                          onTap: () async {
                            dialogSetState(() {
                              selectedGroup = name;
                              selectedTemplates = List.from(
                                _templateGroups[name]!,
                              );
                              groupNameController.text =
                                  name; // auto-fill name when selecting existing group
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
                actions: [
                  CommonUtils.buildTextButton(
                    () => _dismissDialog(dialogContext),
                    'Cancel',
                    themeBundle.textStyle,
                  ),
                  CommonUtils.buildTextButton(
                    () async {
                      final groupName = groupNameController.text.trim();
                      if (groupName.isEmpty || selectedTemplates.isEmpty) {
                        dialogSetState(() {
                          validationMessage =
                              'Please enter a group name and select at least one template.';
                        });
                        return;
                      }

                      setState(() {
                        _templateGroups[groupName] = List.from(
                          selectedTemplates,
                        );
                      });
                      await _saveTemplateGroups();
                      dialogSetState(() {
                        selectedGroup = groupName;
                        validationMessage = null;
                      });
                      if (!context.mounted) return;
                      CommonUtils.showDialogWidget(
                        context,
                        '$groupName has been updated.',
                        themeBundle.textStyle,
                        themeBundle.secondaryColor,
                      );
                    },
                    'Save/Update Group',
                    themeBundle.textStyle,
                  ),
                  if (validationMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        validationMessage!,
                        style: themeBundle.textStyle.copyWith(
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  CommonUtils.buildElevatedButton(
                    'Create Goals',
                    themeBundle.primaryColor,
                    themeBundle.secondaryColor,
                    themeBundle.textStyle,
                    0,
                    0,
                    () async {
                      if (selectedTemplates.isEmpty) {
                        CommonUtils.showBasicAlertDialog(
                          context,
                          'No templates Selected',
                          'Please select at least one template to create goals from.',
                          themeBundle.textStyle,
                          themeBundle.secondaryColor,
                        );
                        return;
                      }
                      await _createGoalsFromTemplatesBulk(selectedTemplates);
                    },
                    borderColor: themeBundle.accentColor,
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        return DeferredScreen<void>(
          load: _loadGoalsPage,
          minLoadingMs: 120,
          loading:
              (_) => themedLoadingShell(
                bundle,
                title: 'Goals',
                body: GoalsSkeleton(bundle: bundle),
              ),
          builder:
              (context, _) => ListenableBuilder(
                listenable: _goals,
                builder: (context, _) => _buildGoalsScaffold(context, bundle),
              ),
        );
      },
    );
  }

  Widget _buildGoalsScaffold(BuildContext context, ThemeBundle bundle) {
    int minutesRequired = 0;
    int minutesToDeadline = 0;

    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Goals', style: bundle.textStyle),
          backgroundColor: bundle.secondaryColor,
          iconTheme: IconThemeData(color: bundle.primaryColor),
        ),
        backgroundColor: bundle.secondaryColor,
        body: Container(
          // SafeArea - Container
          color: bundle.secondaryColor,
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                KeyedSubtree(
                                  key: ValueKey(
                                    'goal-templates-${_templateDetails.length}-${_userTemplates.length}-${_userTemplates.keys.join('|')}',
                                  ),
                                  child:
                                      CommonUtils.buildDropdownButtonFormField(
                                        'Template (optional)',
                                        null,
                                        [
                                          ..._templateDetails.keys,
                                          ..._userTemplates.keys,
                                        ],
                                        themeBundle.textStyle,
                                        themeBundle.secondaryColor,
                                        (val) {
                                          if (val == null) return;
                                          _titleController.text = val;
                                          final data =
                                              _templateDetails[val] ??
                                              _userTemplates[val]!;
                                          setState(() {
                                            _category = data['category'];
                                            _complexity = data['complexity'];
                                            _effort = data['effort'];
                                            _motivation = data['motivation'];
                                          });
                                          _timeController.text = data['time'];
                                          _deadlineController.text =
                                              data['Hours to complete'];
                                          _stepsController.text = data['steps'];
                                        },
                                      ),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Category',
                                  _category,
                                  _categories,
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
                                  (val) => setState(
                                    () => _category = val ?? 'Productivity',
                                  ),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Complexity',
                                  _complexity,
                                  _levels,
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
                                  (val) => setState(
                                    () => _complexity = val ?? 'Low',
                                  ),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Effort Required',
                                  _effort,
                                  _levels,
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
                                  (val) =>
                                      setState(() => _effort = val ?? 'Low'),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Motivation Needed',
                                  _motivation,
                                  _levels,
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
                                  (val) => setState(
                                    () => _motivation = val ?? 'Low',
                                  ),
                                ),
                                CommonUtils.buildTextFormField(
                                  _titleController,
                                  'Goal Title',
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
                                  true,
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Title required'
                                          : null,
                                ),
                                CommonUtils.buildTextFormField(
                                  _timeController,
                                  'Time Required in minutes',
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
                                  true,
                                  (v) {
                                    final parsed = int.tryParse(
                                      v?.trim() ?? '',
                                    );
                                    if (parsed == null || parsed < 1) {
                                      return 'Please enter a valid whole number';
                                    }
                                    minutesRequired = parsed;
                                    return null;
                                  },
                                ),
                                CommonUtils.buildTextFormField(
                                  _deadlineController,
                                  'Hours to complete (optional)',
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
                                  true,
                                  (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return null;
                                    final parsed = int.tryParse(v);
                                    if (parsed == null ||
                                        parsed <= 0 ||
                                        parsed > 9999) {
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
                                  _stepsController,
                                  'Steps (Required)',
                                  themeBundle.textStyle,
                                  themeBundle.secondaryColor,
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
                                const SizedBox(height: 10),
                                CommonUtils.buildElevatedButton(
                                  'Add Goal',
                                  themeBundle.primaryColor,
                                  themeBundle.secondaryColor,
                                  themeBundle.textStyle,
                                  5,
                                  5,
                                  _createGoal,
                                  borderColor: themeBundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Clear Active Goals',
                                  themeBundle.primaryColor,
                                  themeBundle.secondaryColor,
                                  themeBundle.textStyle,
                                  5,
                                  5,
                                  _clearGoals,
                                  borderColor: themeBundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Clear Completed Goals',
                                  themeBundle.primaryColor,
                                  themeBundle.secondaryColor,
                                  themeBundle.textStyle,
                                  5,
                                  5,
                                  _clearCompleteGoals,
                                  borderColor: themeBundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Manage Multi-templates',
                                  themeBundle.primaryColor,
                                  themeBundle.secondaryColor,
                                  themeBundle.textStyle,
                                  5,
                                  5,
                                  _openMultiTemplateManager,
                                  borderColor: themeBundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Manage Templates',
                                  themeBundle.primaryColor,
                                  themeBundle.secondaryColor,
                                  themeBundle.textStyle,
                                  5,
                                  5,
                                  _openTemplateManager,
                                  borderColor: themeBundle.accentColor,
                                ),
                                ConfettiWidget(
                                  confettiController: _confettiController,
                                  blastDirectionality:
                                      BlastDirectionality.explosive,
                                  shouldLoop: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Sort and Filter Controls
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CommonUtils.buildDropdownButton(
                                _selectedCategoryFilter,
                                ['All', ..._categories],
                                themeBundle.textStyle,
                                themeBundle.secondaryColor,
                                (val) => setState(
                                  () => _selectedCategoryFilter = val ?? 'All',
                                ),
                                displayText: (v) => 'Category: $v',
                              ),
                              CommonUtils.buildDropdownButton(
                                _selectedComplexityFilter,
                                ['All', ..._levels],
                                themeBundle.textStyle,
                                themeBundle.secondaryColor,
                                (val) => setState(
                                  () =>
                                      _selectedComplexityFilter = val ?? 'All',
                                ),
                                displayText: (v) => 'Complexity: $v',
                              ),
                              CommonUtils.buildDropdownButton(
                                _selectedStatusFilter,
                                ['Active', 'Completed'],
                                themeBundle.textStyle,
                                themeBundle.secondaryColor,
                                (val) => setState(
                                  () => _selectedStatusFilter = val ?? 'Active',
                                ),
                                displayText: (v) => 'Status: $v',
                              ),
                              CommonUtils.buildDropdownButton(
                                _sortBy,
                                [
                                  'None',
                                  'Title A-Z',
                                  'Title Z-A',
                                  'Time ↑',
                                  'Time ↓',
                                  'Steps ↑',
                                  'Steps ↓',
                                  'Closest deadline',
                                ],
                                themeBundle.textStyle,
                                themeBundle.secondaryColor,
                                (val) =>
                                    setState(() => _sortBy = val ?? 'None'),
                                displayText: (v) => 'Sort: $v',
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 🗂 Filter + Sort Results
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: _filteredSortedGoals.length,
                              itemBuilder: (_, i) {
                                final g = _filteredSortedGoals[i];
                                final steps = g.steps > 0 ? g.steps : 1;
                                return ListTile(
                                  titleTextStyle: themeBundle.textStyle,
                                  textColor: themeBundle.primaryColor,
                                  title: Text(g.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${g.points} pts | ${g.category}',
                                        style: themeBundle.textStyle,
                                      ),
                                      if (_selectedStatusFilter == 'Active' &&
                                          steps > 1)
                                        buildStepDisplay(
                                          g,
                                          _repos.settings.userFontSize,
                                        ),
                                    ],
                                  ),
                                  onTap: () => _viewGoalDetails(g),
                                  trailing:
                                      _selectedStatusFilter == 'Active'
                                          ? Wrap(
                                            children: [
                                              CommonUtils.buildIconButton(
                                                'Add Step Progress',
                                                Icons.add_circle_outline,
                                                themeBundle.primaryColor,
                                                () => _incrementStepProgress(
                                                  g.goalId,
                                                ),
                                              ),
                                              CommonUtils.buildIconButton(
                                                'Complete Goal',
                                                Icons.add_task,
                                                themeBundle.primaryColor,
                                                () => _completeGoal(g.goalId),
                                              ),
                                              CommonUtils.buildIconButton(
                                                'Remove Goal',
                                                Icons.delete,
                                                themeBundle.primaryColor,
                                                () => _removeGoal(g.goalId),
                                              ),
                                            ],
                                          )
                                          : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

Widget buildStepDisplay(GoalSet g, double userFontSize) {
  final totalSteps = g.steps > 0 ? g.steps : 1;
  final currentProgress = g.stepProgress.clamp(0, totalSteps);

  if (totalSteps > 10) {
    return Text(
      'Step $currentProgress/$totalSteps',
      style: TextStyle(fontSize: userFontSize),
    );
  }

  return Wrap(
    spacing: 4.0,
    runSpacing: 4.0,
    children: List.generate(
      totalSteps,
      (i) => Icon(
        i < currentProgress ? Icons.check_box : Icons.check_box_outline_blank,
        size: userFontSize,
      ),
    ),
  );
}
