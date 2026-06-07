// lib/screens/goals_screen.dart
import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:focusNexus/goals/builtin_goal_templates.dart';
import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/goals/goal_deadline_label.dart';
import 'package:focusNexus/goals/goals_filter_sort.dart';
import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/goals/template_group_cleanup.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/widgets/deferred_screen.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalsNotifier get _goalsNotifier => ref.read(goalsProvider.notifier);
  GoalsScreenUiNotifier get _uiNotifier => ref.read(goalsScreenUiProvider.notifier);
  GoalsScreenUiState get _uiState => ref.read(goalsScreenUiProvider);
  ThemeBundle get _themeBundle => ref.read(themeBundleProvider);
  AppRepositories get _repos => ref.read(appRepositoriesProvider);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _templateName = TextEditingController();
  final TextEditingController _templateTime = TextEditingController();
  final TextEditingController _templateSteps = TextEditingController();
  final TextEditingController _templateDeadline = TextEditingController();
  final _categories = kGoalCategories;
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
    _titleController.dispose();
    _timeController.dispose();
    _deadlineController.dispose();
    _stepsController.dispose();
    _templateName.dispose();
    _templateTime.dispose();
    _templateSteps.dispose();
    _templateDeadline.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalsPage() async {
    _stepsController.text = '1';
    _templateSteps.text = '1';
    await _goalsNotifier.load(now: _currentDate);
    await _loadTemplates();
    await _loadTemplateGroups();
    _syncGoalsCompletedToday();
    unawaited(ref.read(soundServiceProvider).warmPlaybackCache());
  }

  void _dismissDialog(BuildContext dialogContext) {
    CommonUtils.dismissKeyboard();
    Navigator.pop(dialogContext);
  }

  Future<void> _loadTemplates() async {
    final templates = await _repos.templates.readUserTemplates();
    _uiNotifier.update(
      (state) => state.copyWith(
        userTemplates: Map<String, Map<String, dynamic>>.from(templates),
      ),
    );
  }

  Future<void> _saveTemplates([Map<String, Map<String, dynamic>>? templates]) async {
    await _repos.templates.writeUserTemplates(templates ?? _uiState.userTemplates);
  }

  void _syncGoalsCompletedToday() {
    _uiNotifier.update(
      (state) => state.copyWith(
        goalsCompletedToday: ref.read(goalsProvider).goalsCompletedToday,
      ),
    );
  }

  Future<void> _clearGoals() => _goalsNotifier.clearActiveGoals();

  Future<void> _clearCompleteGoals() => _goalsNotifier.clearCompletedGoals();

  Future<void> _createGoal() async {
    if (_stepsController.text == '') {
      _stepsController.text = '1';
    }
    if (!_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_deadlineController.text.trim()) ?? 0;
    final ui = _uiState;
    final title = _titleController.text.trim();
    await _goalsNotifier.createGoal(
      title: title,
      category: ui.category,
      complexity: ui.complexity,
      effort: ui.effort,
      motivation: ui.motivation,
      time: _timeController.text,
      steps: _stepsController.text,
      deadlineHours: hours,
      anchor: _currentDate,
    );
    _resetControllers();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncGoalsCompletedToday();
      ref.read(soundServiceProvider).playGoalCreated();
      CommonUtils.showSnackBar(
        context,
        'Goal "$title" created!',
        _themeBundle.textStyle,
        2500,
        12,
        backgroundColor: _themeBundle.secondaryColor,
        labelColor: _themeBundle.primaryColor,
      );
    });
  }

  void _resetControllers() {
    _titleController.clear();
    _timeController.clear();
    _deadlineController.clear();
    _stepsController.text = '1';
  }

  Future<void> _incrementStepProgress(int goalId) async {
    final result = await _goalsNotifier.incrementStepProgress(goalId);
    if (result?.completed != null) {
      _scheduleGoalCompletedFeedback(result!.completed!);
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
    await _goalsNotifier.createGoal(
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
    _syncGoalsCompletedToday();
  }

  Future<void> _createGoalsFromTemplatesBulk(List<String> templateNames) async {
    if (templateNames.isEmpty) {
      CommonUtils.showBasicAlertDialog(
        context,
        'No templates Selected',
        'Please select at least one template to create goals from.',
        _themeBundle.textStyle,
        _themeBundle.secondaryColor,
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            backgroundColor: _themeBundle.secondaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Goals are being created.',
                style: _themeBundle.textStyle,
              ),
            ),
          ),
    );

    try {
      final inputs = <CreateGoalInput>[
        for (final templateName in templateNames)
          () {
            final data =
                _templateDetails[templateName] ??
                _uiState.userTemplates[templateName]!;
            return CreateGoalInput(
              title: templateName,
              category: data['category'] as String,
              complexity: data['complexity'] as String,
              effort: data['effort'] as String,
              motivation: data['motivation'] as String,
              time: data['time'] as String,
              steps: data['steps'] as String,
              deadlineHours: int.tryParse(
                    (data['Hours to complete'] as String?) ?? '',
                  ) ??
                  0,
            );
          }(),
      ];

      await _goalsNotifier.createGoals(
        inputs: inputs,
        anchor: _currentDate,
      );
      _syncGoalsCompletedToday();
      ref.read(soundServiceProvider).playGoalCreated();
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
      _themeBundle.textStyle,
      _themeBundle.secondaryColor,
    );
  }

  void _completeGoal(int goalId) {
    final result = _goalsNotifier.completeGoalOptimistic(goalId);
    if (result == null || !mounted) return;
    _scheduleGoalCompletedFeedback(result);
  }

  /// List repaint first, then confetti/snackbar/sound on the next frame.
  void _scheduleGoalCompletedFeedback(CompleteGoalResult result) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confettiController.play();
      CommonUtils.showSnackBar(
        context,
        '${result.goal.title} completed! +${result.pointsAwarded} points. '
        'Goals completed today: ${result.goalsCompletedToday}',
        _themeBundle.textStyle,
        2000,
        5,
        backgroundColor: _themeBundle.secondaryColor,
        labelColor: _themeBundle.primaryColor,
      );
      unawaited(ref.read(soundServiceProvider).playGoalCompleted());
    });
  }

  Future<void> _removeGoal(int goalId) => _goalsNotifier.removeGoal(goalId);

  Future<void> _preSaveTemplate(
    GlobalKey<FormState> templateFormKey,
  ) async {
    if (!templateFormKey.currentState!.validate()) {
      return; // stop if validation fails
    }
    if (_templateSteps.text.trim() == '') {
      _templateSteps.text = '1';
    }
    final ui = _uiState;
    final name = _templateName.text.trim();
    final data = {
      'category': ui.templateDialogCategory,
      'complexity': ui.templateDialogComplexity,
      'effort': ui.templateDialogEffort,
      'motivation': ui.templateDialogMotivation,
      'time': _templateTime.text.trim(),
      'steps': _templateSteps.text.trim(),
      'Hours to complete': _templateDeadline.text.trim(),
    };
    final updatedUserTemplates = Map<String, Map<String, dynamic>>.from(
      ui.userTemplates,
    );
    if (_templateDetails.containsKey(name)) {
      _templateDetails[name] = data;
    } else {
      updatedUserTemplates[name] = data;
    }
    _uiNotifier.update((state) => state.copyWith(userTemplates: updatedUserTemplates));
    await _saveTemplates(updatedUserTemplates);

    if (mounted) {
      CommonUtils.showDialogWidget(
        context,
        'Template "$name" saved.',
        _themeBundle.textStyle,
        _themeBundle.secondaryColor,
      );
    }
  }

  void _viewGoalDetails(GoalSet goal) {
    final bundle = _themeBundle;
    showDialog(
      context: context,
      barrierColor: bundle.secondaryColor, // ✅ Sets overlay color
      builder:
          (_) => AlertDialog(
            backgroundColor: bundle.secondaryColor,
            iconColor: bundle.primaryColor,
            title: Text(goal.title, style: bundle.textStyle),
            content: CommonUtils.scrollableDialogBody(
              context: context,
              heightFactor: 0.5,
              children: [
                Text('Category: ${goal.category}', style: bundle.textStyle),
                Text('Complexity: ${goal.complexity}', style: bundle.textStyle),
                Text('Effort: ${goal.effort}', style: bundle.textStyle),
                Text('Motivation: ${goal.motivation}', style: bundle.textStyle),
                Text(
                  'Time Needed in minutes: ${goal.time}',
                  style: bundle.textStyle,
                ),
                Text(
                  'Deadline: ${goalDeadlineLabel(goal.deadline)}',
                  style: bundle.textStyle,
                ),
                Text('Steps: ${goal.steps}', style: bundle.textStyle),
                Text('Points: ${goal.points}', style: bundle.textStyle),
                Text('Id: ${goal.goalId}', style: bundle.textStyle),
              ],
            ),
            actions: [
              Container(
                color: bundle.secondaryColor,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: bundle.textStyle),
                ),
              ),
            ],
          ),
    );
  }

  void _openTemplateManager() {
    _uiNotifier.update(
      (state) => state.copyWith(
        templateDialogCategory: _categories.first,
        templateDialogComplexity: _levels.first,
        templateDialogEffort: _levels.first,
        templateDialogMotivation: _levels.first,
      ),
    );
    int minutesRequired = 0;
    int minutesToDeadline = 0;

    final GlobalKey<FormState> templateFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
            builder: (context, ref, _) {
              final bundle = ref.watch(themeBundleProvider);
              final ui = ref.watch(goalsScreenUiProvider);
              final allTemplateNames = [
                ..._templateDetails.keys,
                ...ui.userTemplates.keys,
              ];
              return AlertDialog(
                  backgroundColor: bundle.secondaryColor,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  title: Text('Manage Templates', style: bundle.textStyle),
                  content: CommonUtils.scrollableDialogBody(
                    context: context,
                    children: [
                      Form(
                        key: templateFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CommonUtils.buildTextFormField(
                              _templateName,
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
                              _categories,
                              bundle.textStyle,
                              bundle.secondaryColor,
                              (v) => _uiNotifier.update(
                                (state) => state.copyWith(
                                  templateDialogCategory: v ?? _categories.first,
                                ),
                              ),
                            ),
                            CommonUtils.buildDropdownButtonFormField(
                              'Complexity',
                              ui.templateDialogComplexity,
                              _levels,
                              bundle.textStyle,
                              bundle.secondaryColor,
                              (v) => _uiNotifier.update(
                                (state) => state.copyWith(
                                  templateDialogComplexity: v ?? _levels.first,
                                ),
                              ),
                            ),
                            CommonUtils.buildDropdownButtonFormField(
                              'Effort',
                              ui.templateDialogEffort,
                              _levels,
                              bundle.textStyle,
                              bundle.secondaryColor,
                              (v) => _uiNotifier.update(
                                (state) => state.copyWith(
                                  templateDialogEffort: v ?? _levels.first,
                                ),
                              ),
                            ),
                            CommonUtils.buildDropdownButtonFormField(
                              'Motivation',
                              ui.templateDialogMotivation,
                              _levels,
                              bundle.textStyle,
                              bundle.secondaryColor,
                              (v) => _uiNotifier.update(
                                (state) => state.copyWith(
                                  templateDialogMotivation: v ?? _levels.first,
                                ),
                              ),
                            ),
                            CommonUtils.buildTextFormField(
                              _templateTime,
                              'Time (minutes, required)',
                              bundle.textStyle,
                              bundle.secondaryColor,
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
                              bundle.textStyle,
                              bundle.secondaryColor,
                              true,
                              (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return null; // optional
                                }
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
                              bundle.textStyle,
                              bundle.secondaryColor,
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
                              bundle.primaryColor,
                              bundle.secondaryColor,
                              bundle.textStyle,
                              14,
                              10,
                              () => _preSaveTemplate(templateFormKey),
                              borderColor: bundle.accentColor,
                            ),
                            const Divider(),
                            Text('Templates:', style: bundle.textStyle),
                            ...allTemplateNames.map(
                              (name) => CommonUtils.buildListTile(
                                title: name,
                                textStyle: bundle.textStyle,
                                trailing:
                                    ui.userTemplates.containsKey(name)
                                        ? IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () async {
                                            final updatedTemplates = Map<String, Map<String, dynamic>>.from(
                                              ui.userTemplates,
                                            )..remove(name);
                                            _uiNotifier.update(
                                              (state) => state.copyWith(
                                                userTemplates: updatedTemplates,
                                              ),
                                            );
                                            await _saveTemplates(updatedTemplates);
                                            await _validateTemplateGroups();
                                          },
                                        )
                                        : null,
                                onTap: () {
                                  final t =
                                      _templateDetails[name] ??
                                      ui.userTemplates[name]!;
                                  _templateName.text = name;
                                  _templateTime.text = t['time'];
                                  _templateDeadline.text = t['Hours to complete'];
                                  _templateSteps.text = t['steps'];
                                  _uiNotifier.update(
                                    (state) => state.copyWith(
                                      templateDialogCategory: t['category'],
                                      templateDialogComplexity: t['complexity'],
                                      templateDialogEffort: t['effort'],
                                      templateDialogMotivation: t['motivation'],
                                    ),
                                  );
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
                          onPressed: () => _dismissDialog(dialogContext),
                          child: Text('Close', style: bundle.textStyle),
                        ),
                      ),
                    ],
                  ),
                  actions: const [],
                );
            },
          ),
    );
  }

  Future<void> _validateTemplateGroups() async {
    final validTemplateNames = {
      ..._templateDetails.keys,
      ..._uiState.userTemplates.keys,
    };

    final result = cleanupTemplateGroups(
      groups: _uiState.templateGroups,
      validTemplateNames: validTemplateNames,
    );

    _uiNotifier.update(
      (state) => state.copyWith(templateGroups: result.updatedGroups),
    );
    await _repos.templates.writeTemplateGroups(result.updatedGroups);

    if (!mounted || !result.hasChanges) return;
    CommonUtils.showBasicAlertDialog(
      context,
      'Multi-template groups updated',
      templateGroupCleanupMessage(result),
      _themeBundle.textStyle,
      _themeBundle.secondaryColor,
    );
  }

  Future<void> _loadTemplateGroups() async {
    final groups = await _repos.templates.readTemplateGroups();
    _uiNotifier.update(
      (state) => state.copyWith(templateGroups: Map<String, List<String>>.from(groups)),
    );
  }

  void _openMultiTemplateManager() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _MultiTemplateManagerDialog(
        templateDetails: _templateDetails,
        onCreateGoals: _createGoalsFromTemplatesBulk,
        onDismiss: () => _dismissDialog(dialogContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(themeBundleProvider);
    final uiState = ref.watch(goalsScreenUiProvider);
    return DeferredScreen<void>(
      loadToken: 'goals-page',
      load: _loadGoalsPage,
      minLoadingMs: 120,
      loading:
          (_) => themedLoadingShell(
            bundle,
            title: 'Goals',
            body: GoalsSkeleton(bundle: bundle),
          ),
      builder:
          (context, _) => _buildGoalsScaffold(
            context,
            bundle,
            uiState,
          ),
    );
  }

  Widget _buildGoalsScaffold(
    BuildContext context,
    ThemeBundle bundle,
    GoalsScreenUiState uiState,
  ) {
    int minutesRequired = 0;
    int minutesToDeadline = 0;
    final allTemplateNames = [
      ..._templateDetails.keys,
      ...uiState.userTemplates.keys,
    ];

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
        body: Stack(
          children: [
            CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                KeyedSubtree(
                                  key: ValueKey(
                                    'goal-templates-${_templateDetails.length}-${uiState.userTemplates.length}-${uiState.userTemplates.keys.join('|')}',
                                  ),
                                  child:
                                      CommonUtils.buildDropdownButtonFormField(
                                        'Template (optional)',
                                        null,
                                        allTemplateNames,
                                        bundle.textStyle,
                                        bundle.secondaryColor,
                                        (val) {
                                          if (val == null) return;
                                          _titleController.text = val;
                                          final data =
                                              _templateDetails[val] ??
                                              uiState.userTemplates[val]!;
                                          _uiNotifier.update(
                                            (state) => state.copyWith(
                                              category: data['category'],
                                              complexity: data['complexity'],
                                              effort: data['effort'],
                                              motivation: data['motivation'],
                                            ),
                                          );
                                          _timeController.text = data['time'];
                                          _deadlineController.text =
                                              data['Hours to complete'];
                                          _stepsController.text = data['steps'];
                                        },
                                      ),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Category',
                                  uiState.category,
                                  _categories,
                                  bundle.textStyle,
                                  bundle.secondaryColor,
                                  (val) => _uiNotifier.update(
                                    (state) =>
                                        state.copyWith(category: val ?? 'Productivity'),
                                  ),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Complexity',
                                  uiState.complexity,
                                  _levels,
                                  bundle.textStyle,
                                  bundle.secondaryColor,
                                  (val) => _uiNotifier.update(
                                    (state) => state.copyWith(complexity: val ?? 'Low'),
                                  ),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Effort Required',
                                  uiState.effort,
                                  _levels,
                                  bundle.textStyle,
                                  bundle.secondaryColor,
                                  (val) => _uiNotifier.update(
                                    (state) => state.copyWith(effort: val ?? 'Low'),
                                  ),
                                ),
                                CommonUtils.buildDropdownButtonFormField(
                                  'Motivation Needed',
                                  uiState.motivation,
                                  _levels,
                                  bundle.textStyle,
                                  bundle.secondaryColor,
                                  (val) => _uiNotifier.update(
                                    (state) =>
                                        state.copyWith(motivation: val ?? 'Low'),
                                  ),
                                ),
                                CommonUtils.buildTextFormField(
                                  _titleController,
                                  'Goal Title',
                                  bundle.textStyle,
                                  bundle.secondaryColor,
                                  true,
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Title required'
                                          : null,
                                ),
                                CommonUtils.buildTextFormField(
                                  _timeController,
                                  'Time Required in minutes',
                                  bundle.textStyle,
                                  bundle.secondaryColor,
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
                                  bundle.textStyle,
                                  bundle.secondaryColor,
                                  true,
                                  (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return null;
                                    }
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
                                const SizedBox(height: 10),
                                CommonUtils.buildElevatedButton(
                                  'Add Goal',
                                  bundle.primaryColor,
                                  bundle.secondaryColor,
                                  bundle.textStyle,
                                  5,
                                  5,
                                  _createGoal,
                                  borderColor: bundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Clear Active Goals',
                                  bundle.primaryColor,
                                  bundle.secondaryColor,
                                  bundle.textStyle,
                                  5,
                                  5,
                                  _clearGoals,
                                  borderColor: bundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Clear Completed Goals',
                                  bundle.primaryColor,
                                  bundle.secondaryColor,
                                  bundle.textStyle,
                                  5,
                                  5,
                                  _clearCompleteGoals,
                                  borderColor: bundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Manage Multi-templates',
                                  bundle.primaryColor,
                                  bundle.secondaryColor,
                                  bundle.textStyle,
                                  5,
                                  5,
                                  _openMultiTemplateManager,
                                  borderColor: bundle.accentColor,
                                ),
                                CommonUtils.buildElevatedButton(
                                  'Manage Templates',
                                  bundle.primaryColor,
                                  bundle.secondaryColor,
                                  bundle.textStyle,
                                  5,
                                  5,
                                  _openTemplateManager,
                                  borderColor: bundle.accentColor,
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
                                uiState.selectedCategoryFilter,
                                ['All', ..._categories],
                                bundle.textStyle,
                                bundle.secondaryColor,
                                (val) => _uiNotifier.update(
                                  (state) => state.copyWith(
                                    selectedCategoryFilter: val ?? 'All',
                                  ),
                                ),
                                displayText: (v) => 'Category: $v',
                              ),
                              CommonUtils.buildDropdownButton(
                                uiState.selectedComplexityFilter,
                                ['All', ..._levels],
                                bundle.textStyle,
                                bundle.secondaryColor,
                                (val) => _uiNotifier.update(
                                  (state) => state.copyWith(
                                    selectedComplexityFilter: val ?? 'All',
                                  ),
                                ),
                                displayText: (v) => 'Complexity: $v',
                              ),
                              CommonUtils.buildDropdownButton(
                                uiState.selectedStatusFilter,
                                ['Active', 'Completed'],
                                bundle.textStyle,
                                bundle.secondaryColor,
                                (val) => _uiNotifier.update(
                                  (state) => state.copyWith(
                                    selectedStatusFilter: val ?? 'Active',
                                  ),
                                ),
                                displayText: (v) => 'Status: $v',
                              ),
                              CommonUtils.buildDropdownButton(
                                uiState.sortBy,
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
                                bundle.textStyle,
                                bundle.secondaryColor,
                                (val) => _uiNotifier.update(
                                  (state) =>
                                      state.copyWith(sortBy: val ?? 'None'),
                                ),
                                displayText: (v) => 'Sort: $v',
                              ),
                            ],
                          ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _GoalsListSectionHeader(bundle: bundle)),
            Consumer(
              builder: (context, ref, _) {
                final filters = ref.watch(
                  goalsScreenUiProvider.select(
                    (s) => (
                      s.selectedStatusFilter,
                      s.selectedCategoryFilter,
                      s.selectedComplexityFilter,
                      s.sortBy,
                    ),
                  ),
                );
                final goalsList = ref.watch(
                  goalsProvider.select(
                    (s) => filters.$1 == 'Active'
                        ? s.activeGoals
                        : s.completedGoals,
                  ),
                );
                final filteredGoals = filterAndSortGoals(
                  source: goalsList,
                  categoryFilter: filters.$2,
                  complexityFilter: filters.$3,
                  sortBy: filters.$4,
                  deadlineFormat: formatter,
                );

                if (filteredGoals.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          filters.$1 == 'Active'
                              ? 'No active goals yet.'
                              : 'No completed goals yet.',
                          style: bundle.textStyle,
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildGoalListTile(
                      bundle,
                      filters.$1,
                      filteredGoals[index],
                    ),
                    childCount: filteredGoals.length,
                  ),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactGoalAction({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildGoalListTile(
    ThemeBundle bundle,
    String selectedStatusFilter,
    GoalSet g,
  ) {
    final steps = g.steps > 0 ? g.steps : 1;
    final subtitleStyle = bundle.textStyle.copyWith(
      fontSize: (bundle.textStyle.fontSize ?? 14) * 0.92,
    );
    final subtitleLines = <String>[
      '${g.points} pts · ${goalDeadlineLabel(g.deadline)}',
    ];
    if (selectedStatusFilter == 'Active' && steps > 1) {
      subtitleLines.add('Step ${g.stepProgress.clamp(0, steps)}/$steps');
    }

    final tile = ListTile(
      key: ValueKey('goal-list-$selectedStatusFilter-${g.goalId}'),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      titleTextStyle: bundle.textStyle,
      textColor: bundle.primaryColor,
      title: Text(
        g.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitleLines.join('\n'),
        style: subtitleStyle,
        maxLines: 2,
      ),
      onTap: () => _viewGoalDetails(g),
      trailing: selectedStatusFilter == 'Active'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _compactGoalAction(
                  tooltip: 'Add Step Progress',
                  icon: Icons.add_circle_outline,
                  color: bundle.primaryColor,
                  onPressed: () => _incrementStepProgress(g.goalId),
                ),
                _compactGoalAction(
                  tooltip: 'Complete Goal',
                  icon: Icons.add_task,
                  color: bundle.primaryColor,
                  onPressed: () => _completeGoal(g.goalId),
                ),
                _compactGoalAction(
                  tooltip: 'Remove Goal',
                  icon: Icons.delete,
                  color: bundle.primaryColor,
                  onPressed: () => _removeGoal(g.goalId),
                ),
              ],
            )
          : null,
    );

    if (selectedStatusFilter != 'Active') return tile;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: bundle.primaryColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: tile,
      ),
    );
  }

}

class _MultiTemplateManagerDialog extends ConsumerStatefulWidget {
  const _MultiTemplateManagerDialog({
    required this.templateDetails,
    required this.onCreateGoals,
    required this.onDismiss,
  });

  final Map<String, Map<String, dynamic>> templateDetails;
  final Future<void> Function(List<String> templateNames) onCreateGoals;
  final VoidCallback onDismiss;

  @override
  ConsumerState<_MultiTemplateManagerDialog> createState() =>
      _MultiTemplateManagerDialogState();
}

class _MultiTemplateManagerDialogState
    extends ConsumerState<_MultiTemplateManagerDialog> {
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

class _GoalsListSectionHeader extends StatelessWidget {
  const _GoalsListSectionHeader({required this.bundle});

  final ThemeBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 2,
          thickness: 2,
          color: bundle.primaryColor.withValues(alpha: 0.35),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            'Your goals',
            style: bundle.textStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: bundle.primaryColor,
            ),
          ),
        ),
      ],
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
