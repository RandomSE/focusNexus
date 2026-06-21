// lib/screens/goals_screen.dart
import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/goals/goals_notification_navigation.dart';
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
import 'package:focusNexus/providers/achievement_ready_toast_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/screens/goals/widgets/clear_active_goals_repeat_dialog.dart';
import 'package:focusNexus/screens/goals/widgets/goals_create_form_panel.dart';
import 'package:focusNexus/screens/goals/widgets/goals_goal_list_tile.dart';
import 'package:focusNexus/screens/goals/widgets/goals_list_section_header.dart';
import 'package:focusNexus/screens/goals/widgets/goals_multi_template_manager_dialog.dart';
import 'package:focusNexus/screens/goals/widgets/goals_template_manager_dialog.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/screen_theme.dart';
import 'package:focusNexus/widgets/deferred_screen.dart';
import 'package:focusNexus/widgets/skeleton_loaders.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key, this.highlightGoalId});

  final int? highlightGoalId;

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _listScrollController = ScrollController();
  final _highlightTileKey = GlobalKey();
  int? _highlightGoalId;
  bool _scrolledToHighlight = false;
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
  bool _achievementToastShowing = false;

  @override
  void initState() {
    super.initState();
    _highlightGoalId = widget.highlightGoalId ?? takePendingGoalsNotificationGoalId();
    if (_highlightGoalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(goalsScreenUiProvider.notifier).update(
          (state) => state.copyWith(selectedStatusFilter: 'Active'),
        );
      });
    }
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _listScrollController.dispose();
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
    _scheduleScrollToHighlight();
  }

  void _scheduleScrollToHighlight({int? highlightIndex}) {
    if (_highlightGoalId == null || _scrolledToHighlight) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_scrollToHighlightedGoal(highlightIndex: highlightIndex)),
    );
  }

  Future<void> _scrollToHighlightedGoal({
    int? highlightIndex,
    int attempt = 0,
  }) async {
    if (_highlightGoalId == null || _scrolledToHighlight || attempt > 12) {
      return;
    }
    final tileContext = _highlightTileKey.currentContext;
    if (tileContext == null) {
      if (highlightIndex != null &&
          highlightIndex > 0 &&
          _listScrollController.hasClients) {
        const headerEstimate = 980.0;
        const tileHeight = 76.0;
        final targetOffset = (headerEstimate + highlightIndex * tileHeight).clamp(
          0.0,
          _listScrollController.position.maxScrollExtent,
        );
        await _listScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else if (_listScrollController.hasClients && attempt > 0) {
        final nudge = (attempt * 140.0).clamp(
          0.0,
          _listScrollController.position.maxScrollExtent,
        );
        await _listScrollController.animateTo(
          nudge,
          duration: const Duration(milliseconds: 120),
          curve: Curves.linear,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(
          _scrollToHighlightedGoal(
            highlightIndex: highlightIndex,
            attempt: attempt + 1,
          ),
        ),
      );
      return;
    }
    await Scrollable.ensureVisible(
      tileContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
    _scrolledToHighlight = true;
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

  Future<void> _clearGoals() async {
    final notifier = _goalsNotifier;
    if (notifier.hasActiveGoalsWithRepeats) {
      final cancelRepeats = await showClearActiveGoalsRepeatDialog(
        context: context,
        bundle: _themeBundle,
      );
      if (!mounted || cancelRepeats == null) return;
      await notifier.clearActiveGoals(cancelRepeatSeries: cancelRepeats);
      return;
    }
    await notifier.clearActiveGoals();
  }

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

  void _showNextAchievementToast() {
    if (_achievementToastShowing || !mounted) return;
    final queue = ref.read(achievementReadyToastQueueProvider);
    if (queue.isEmpty) return;

    _achievementToastShowing = true;
    final toast = queue.first;
    CommonUtils.showSnackBar(
      context,
      'Achievement ready: ${toast.title}',
      _themeBundle.textStyle,
      toast.durationMs,
      5,
      backgroundColor: _themeBundle.secondaryColor,
      labelColor: _themeBundle.primaryColor,
    );
    Future<void>.delayed(Duration(milliseconds: toast.durationMs + 50), () {
      if (!mounted) return;
      ref.read(achievementReadyToastQueueProvider.notifier).consumeHead();
      _achievementToastShowing = false;
      _showNextAchievementToast();
    });
  }

  Future<void> _removeGoal(int goalId) => _goalsNotifier.removeGoal(goalId);

  Future<void> _preSaveTemplate(
    GlobalKey<FormState> templateFormKey,
  ) async {
    if (!templateFormKey.currentState!.validate()) {
      return;
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
    final isCompleted = ref
        .read(goalsProvider)
        .completedGoals
        .any((g) => g.goalId == goal.goalId);
    showDialog(
      context: context,
      barrierColor: bundle.secondaryColor,
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
                if (isCompleted)
                  Text(
                    'Completed: ${goalCompletedLabel(goal.completedAt)}',
                    style: bundle.textStyle,
                  )
                else
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
    final templateFormKey = GlobalKey<FormState>();

    GoalsTemplateManagerDialog.show(
      context,
      templateFormKey: templateFormKey,
      templateNameController: _templateName,
      templateTimeController: _templateTime,
      templateStepsController: _templateSteps,
      templateDeadlineController: _templateDeadline,
      categories: _categories,
      levels: _levels,
      templateDetails: _templateDetails,
      onSaveTemplate: _preSaveTemplate,
      onDismiss: _dismissDialog,
      onDeleteUserTemplate: (name) async {
        final updatedTemplates = Map<String, Map<String, dynamic>>.from(
          _uiState.userTemplates,
        )..remove(name);
        _uiNotifier.update(
          (state) => state.copyWith(userTemplates: updatedTemplates),
        );
        await _saveTemplates(updatedTemplates);
        await _validateTemplateGroups();
      },
      onTemplateSelected: (name, templateData) {
        _templateName.text = name;
        _templateTime.text = templateData['time'] as String;
        _templateDeadline.text = templateData['Hours to complete'] as String;
        _templateSteps.text = templateData['steps'] as String;
        _uiNotifier.update(
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
      builder: (dialogContext) => GoalsMultiTemplateManagerDialog(
        templateDetails: _templateDetails,
        onCreateGoals: _createGoalsFromTemplatesBulk,
        onDismiss: () => _dismissDialog(dialogContext),
      ),
    );
  }

  void _onTemplateSelected(String templateName) {
    _titleController.text = templateName;
    final data =
        _templateDetails[templateName] ?? _uiState.userTemplates[templateName]!;
    _uiNotifier.update(
      (state) => state.copyWith(
        category: data['category'] as String,
        complexity: data['complexity'] as String,
        effort: data['effort'] as String,
        motivation: data['motivation'] as String,
      ),
    );
    _timeController.text = data['time'] as String;
    _deadlineController.text = data['Hours to complete'] as String;
    _stepsController.text = data['steps'] as String;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(achievementReadyToastQueueProvider, (previous, next) {
      if (next.isEmpty) return;
      final wasEmpty = previous == null || previous.isEmpty;
      if (wasEmpty) _showNextAchievementToast();
    });

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
              controller: _listScrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CommonUtils.buildElevatedButton(
                          'Time-slot goals',
                          bundle.primaryColor,
                          bundle.secondaryColor,
                          bundle.textStyle,
                          8,
                          8,
                          () => ref.pushRoute(context, const TimeWindowHubRoute()),
                          borderColor: bundle.accentColor,
                        ),
                        Text(
                          'Scheduled time slots - goals that need to be done within a specific time slot (can also auto-repeat)',
                          style: bundle.textStyle.copyWith(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        GoalsCreateFormPanel(
                      formKey: _formKey,
                      titleController: _titleController,
                      timeController: _timeController,
                      deadlineController: _deadlineController,
                      stepsController: _stepsController,
                      categories: _categories,
                      levels: _levels,
                      templateNames: allTemplateNames,
                      templateDetails: _templateDetails,
                      uiState: uiState,
                      bundle: bundle,
                      onTemplateSelected: _onTemplateSelected,
                      onCategoryChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(category: val ?? 'Productivity'),
                      ),
                      onComplexityChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(complexity: val ?? 'Low'),
                      ),
                      onEffortChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(effort: val ?? 'Low'),
                      ),
                      onMotivationChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(motivation: val ?? 'Low'),
                      ),
                      onCreateGoal: _createGoal,
                      onClearGoals: _clearGoals,
                      onClearCompleteGoals: _clearCompleteGoals,
                      onOpenMultiTemplateManager: _openMultiTemplateManager,
                      onOpenTemplateManager: _openTemplateManager,
                      onCategoryFilterChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(
                          selectedCategoryFilter: val ?? 'All',
                        ),
                      ),
                      onComplexityFilterChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(
                          selectedComplexityFilter: val ?? 'All',
                        ),
                      ),
                      onStatusFilterChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(
                          selectedStatusFilter: val ?? 'Active',
                        ),
                      ),
                      onSortByChanged: (val) => _uiNotifier.update(
                        (state) => state.copyWith(sortBy: val ?? 'None'),
                      ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: GoalsListSectionHeader(bundle: bundle),
                ),
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
                      final emptyMessage = switch (filters.$4) {
                        'In slot now' =>
                          'No goals are in their time slot right now.',
                        'Time-slot only' => 'No time-slot goals yet.',
                        _ => filters.$1 == 'Active'
                            ? 'No active goals yet.'
                            : 'No completed goals yet.',
                      };
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              emptyMessage,
                              style: bundle.textStyle,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!_scrolledToHighlight && _highlightGoalId != null) {
                      final highlightIndex = filteredGoals.indexWhere(
                        (g) => g.goalId == _highlightGoalId,
                      );
                      if (highlightIndex >= 0) {
                        _scheduleScrollToHighlight(
                          highlightIndex: highlightIndex,
                        );
                      }
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = filteredGoals[index];
                          final isHighlight = _highlightGoalId == goal.goalId;
                          return GoalsGoalListTile(
                            key: isHighlight
                                ? _highlightTileKey
                                : ValueKey(
                                    'goal-list-${filters.$1}-${goal.goalId}',
                                  ),
                            bundle: bundle,
                            selectedStatusFilter: filters.$1,
                            goal: goal,
                            highlight: isHighlight,
                            onComplete: () => _completeGoal(goal.goalId),
                            onIncrementStep: () =>
                                _incrementStepProgress(goal.goalId),
                            onViewDetails: () => _viewGoalDetails(goal),
                            onRemove: () => _removeGoal(goal.goalId),
                          );
                        },
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
}
