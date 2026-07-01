// lib/screens/goals_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/goals/goals_notification_navigation.dart';
import 'package:focusNexus/goals/goal_categories.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/achievement_ready_toast_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/goals_achievement_toast.dart';
import 'package:focusNexus/screens/goals/goals_form_actions.dart';
import 'package:focusNexus/screens/goals/goals_goal_details_dialog.dart';
import 'package:focusNexus/screens/goals/goals_highlight_scroll.dart';
import 'package:focusNexus/screens/goals/goals_template_controller.dart';
import 'package:focusNexus/screens/goals/widgets/goals_confetti_overlay.dart';
import 'package:focusNexus/screens/goals/widgets/goals_create_form_panel.dart';
import 'package:focusNexus/screens/goals/widgets/goals_filtered_list_sliver.dart';
import 'package:focusNexus/screens/goals/widgets/goals_list_section_header.dart';
import 'package:focusNexus/screens/goals/widgets/goals_time_slot_entry_section.dart';
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
  final _confettiKey = GlobalKey<GoalsConfettiOverlayState>();
  late final GoalsHighlightScrollCoordinator _highlightScroll;
  late final GoalsAchievementToastCoordinator _achievementToasts;
  late final GoalsTemplateController _templates;
  late final GoalsFormActions _formActions;
  late final Map<String, Map<String, dynamic>> _templateDetails;

  GoalsNotifier get _goalsNotifier => ref.read(goalsProvider.notifier);
  GoalsScreenUiNotifier get _uiNotifier => ref.read(goalsScreenUiProvider.notifier);
  ThemeBundle get _themeBundle => ref.read(themeBundleProvider);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _stepsController = TextEditingController();
  final _templateName = TextEditingController();
  final _templateTime = TextEditingController();
  final _templateSteps = TextEditingController();
  final _templateDeadline = TextEditingController();
  final _categories = kGoalCategories;
  final _levels = ['Low', 'Medium', 'High'];
  final _currentDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    DateTime.now().hour,
    DateTime.now().minute,
  );
  final _formatter = DateFormat('dd MMMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _templateDetails = createBuiltinTemplateDetails();
    _highlightScroll = GoalsHighlightScrollCoordinator(
      scrollController: _listScrollController,
      highlightTileKey: _highlightTileKey,
    );
    _highlightScroll.highlightGoalId =
        widget.highlightGoalId ?? takePendingGoalsNotificationGoalId();
    _achievementToasts = GoalsAchievementToastCoordinator();
    _templates = GoalsTemplateController(
      repos: ref.read(appRepositoriesProvider),
      uiNotifier: ref.read(goalsScreenUiProvider.notifier),
      goalsNotifier: ref.read(goalsProvider.notifier),
      templateDetails: _templateDetails,
      categories: _categories,
      levels: _levels,
      anchorDate: _currentDate,
      templateNameController: _templateName,
      templateTimeController: _templateTime,
      templateStepsController: _templateSteps,
      templateDeadlineController: _templateDeadline,
      titleController: _titleController,
      timeController: _timeController,
      deadlineController: _deadlineController,
      stepsController: _stepsController,
      getUiState: () => ref.read(goalsScreenUiProvider),
      isMounted: () => mounted,
    );
    _formActions = GoalsFormActions(
      goalsNotifier: ref.read(goalsProvider.notifier),
      getUiState: () => ref.read(goalsScreenUiProvider),
      anchorDate: _currentDate,
      formKey: _formKey,
      titleController: _titleController,
      timeController: _timeController,
      deadlineController: _deadlineController,
      stepsController: _stepsController,
      resetControllers: _resetControllers,
    );

    if (_highlightScroll.highlightGoalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _uiNotifier.update(
          (state) => state.copyWith(selectedStatusFilter: 'Active'),
        );
      });
    }
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
    super.dispose();
  }

  Future<void> _loadGoalsPage() async {
    _stepsController.text = '1';
    _templateSteps.text = '1';
    await _goalsNotifier.load(now: _currentDate);
    await _templates.loadTemplates();
    await _templates.loadTemplateGroups();
    _syncGoalsCompletedToday();
    unawaited(ref.read(soundServiceProvider).warmPlaybackCache());
    _highlightScroll.schedule();
  }

  void _syncGoalsCompletedToday() {
    _uiNotifier.update(
      (state) => state.copyWith(
        goalsCompletedToday: ref.read(goalsProvider).goalsCompletedToday,
      ),
    );
  }

  void _dismissDialog(BuildContext dialogContext) {
    CommonUtils.dismissKeyboard();
    Navigator.pop(dialogContext);
  }

  Future<void> _clearGoals() => _formActions.clearGoals(
        context: context,
        bundle: _themeBundle,
        isMounted: () => mounted,
      );

  Future<void> _createGoal() => _formActions.createGoal(
        context: context,
        bundle: _themeBundle,
        soundService: ref.read(soundServiceProvider),
        syncGoalsCompletedToday: _syncGoalsCompletedToday,
        isMounted: () => mounted,
      );

  void _resetControllers() {
    _titleController.clear();
    _timeController.clear();
    _deadlineController.clear();
    _stepsController.text = '1';
  }

  Future<void> _incrementStepProgress(int goalId) async {
    final result = await _goalsNotifier.incrementStepProgress(goalId);
    if (result?.completed != null) {
      _confettiKey.currentState?.celebrateCompletion(result!.completed!);
    }
  }

  void _completeGoal(int goalId) {
    final result = _goalsNotifier.completeGoalOptimistic(goalId);
    if (result == null || !mounted) return;
    _confettiKey.currentState?.celebrateCompletion(result);
  }

  Future<void> _removeGoal(int goalId) => _goalsNotifier.removeGoal(goalId);

  void _viewGoalDetails(GoalSet goal) {
    unawaited(_showGoalDetails(goal));
  }

  Future<void> _showGoalDetails(GoalSet goal) async {
    final bundle = _themeBundle;
    final isCompleted = ref
        .read(goalsProvider)
        .completedGoals
        .any((g) => g.goalId == goal.goalId);
    RepeatRule? repeatRule;
    if (goal.repeatSeriesId != 0) {
      final seriesById = await ref.read(activeRepeatSeriesProvider.future);
      repeatRule = seriesById[goal.repeatSeriesId]?.repeatRule;
    }
    if (!mounted) return;
    await showGoalsGoalDetailsDialog(
      context: context,
      bundle: bundle,
      goal: goal,
      isCompleted: isCompleted,
      repeatRule: repeatRule,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(achievementReadyToastQueueProvider, (previous, next) {
      _achievementToasts.onQueueChanged(
        ref: ref,
        context: context,
        bundle: ref.read(themeBundleProvider),
        previous: previous,
        next: next,
        isMounted: () => mounted,
      );
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
          (context, _) => _buildGoalsScaffold(context, bundle, uiState),
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
        body: GoalsConfettiOverlay(
          key: _confettiKey,
          bundle: bundle,
          onPlayGoalCompletedSound:
              () => ref.read(soundServiceProvider).playGoalCompleted(),
          child: CustomScrollView(
            controller: _listScrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GoalsTimeSlotEntrySection(
                        bundle: bundle,
                        onOpenHub: () => ref.pushRoute(
                          context,
                          const TimeWindowHubRoute(),
                        ),
                      ),
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
                        onTemplateSelected: _templates.onTemplateSelected,
                        onCategoryChanged:
                            (val) => _uiNotifier.update(
                              (state) =>
                                  state.copyWith(category: val ?? 'Productivity'),
                            ),
                        onComplexityChanged:
                            (val) => _uiNotifier.update(
                              (state) =>
                                  state.copyWith(complexity: val ?? 'Low'),
                            ),
                        onEffortChanged:
                            (val) => _uiNotifier.update(
                              (state) => state.copyWith(effort: val ?? 'Low'),
                            ),
                        onMotivationChanged:
                            (val) => _uiNotifier.update(
                              (state) =>
                                  state.copyWith(motivation: val ?? 'Low'),
                            ),
                        onCreateGoal: _createGoal,
                        onClearGoals: _clearGoals,
                        onClearCompleteGoals:
                            _goalsNotifier.clearCompletedGoals,
                        onOpenMultiTemplateManager:
                            () => _templates.openMultiTemplateManager(
                              context: context,
                              bundle: bundle,
                              onPlayGoalCreated:
                                  () =>
                                      ref.read(soundServiceProvider).playGoalCreated(),
                              syncGoalsCompletedToday: _syncGoalsCompletedToday,
                              onDismiss: _dismissDialog,
                            ),
                        onOpenTemplateManager:
                            () => _templates.openTemplateManager(
                              context: context,
                              bundle: bundle,
                              onDismiss: _dismissDialog,
                            ),
                        onCategoryFilterChanged:
                            (val) => _uiNotifier.update(
                              (state) => state.copyWith(
                                selectedCategoryFilter: val ?? 'All',
                              ),
                            ),
                        onComplexityFilterChanged:
                            (val) => _uiNotifier.update(
                              (state) => state.copyWith(
                                selectedComplexityFilter: val ?? 'All',
                              ),
                            ),
                        onStatusFilterChanged:
                            (val) => _uiNotifier.update(
                              (state) => state.copyWith(
                                selectedStatusFilter: val ?? 'Active',
                              ),
                            ),
                        onSortByChanged:
                            (val) => _uiNotifier.update(
                              (state) => state.copyWith(sortBy: val ?? 'None'),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: GoalsListSectionHeader(bundle: bundle)),
              GoalsFilteredListSliver(
                bundle: bundle,
                dateFormat: _formatter,
                highlightScroll: _highlightScroll,
                highlightTileKey: _highlightTileKey,
                onComplete: _completeGoal,
                onIncrementStep: _incrementStepProgress,
                onViewDetails: _viewGoalDetails,
                onRemove: _removeGoal,
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
