import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:focusNexus/goals/goals_filter_sort.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/screens/goals/goals_highlight_scroll.dart';
import 'package:focusNexus/screens/goals/widgets/goals_goal_list_tile.dart';

/// Filtered, sorted goals list as a [CustomScrollView] sliver.
class GoalsFilteredListSliver extends ConsumerStatefulWidget {
  const GoalsFilteredListSliver({
    super.key,
    required this.bundle,
    required this.dateFormat,
    required this.highlightScroll,
    required this.highlightTileKey,
    required this.onComplete,
    required this.onIncrementStep,
    required this.onViewDetails,
    required this.onRemove,
  });

  final ThemeBundle bundle;
  final DateFormat dateFormat;
  final GoalsHighlightScrollCoordinator highlightScroll;
  final GlobalKey highlightTileKey;
  final void Function(int goalId) onComplete;
  final Future<void> Function(int goalId) onIncrementStep;
  final void Function(GoalSet goal) onViewDetails;
  final Future<void> Function(int goalId) onRemove;

  @override
  ConsumerState<GoalsFilteredListSliver> createState() =>
      _GoalsFilteredListSliverState();
}

class _GoalsFilteredListSliverState
    extends ConsumerState<GoalsFilteredListSliver> {
  @override
  Widget build(BuildContext context) {
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
        (s) => filters.$1 == 'Active' ? s.activeGoals : s.completedGoals,
      ),
    );
    final filteredGoals = filterAndSortGoals(
      source: goalsList,
      categoryFilter: filters.$2,
      complexityFilter: filters.$3,
      sortBy: filters.$4,
      deadlineFormat: widget.dateFormat,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.highlightScroll.notifyFilteredGoals(filteredGoals);
    });

    if (filteredGoals.isEmpty) {
      final emptyMessage = switch (filters.$4) {
        'In slot now' => 'No goals are in their time slot right now.',
        'Time-slot only' => 'No time-slot goals yet.',
        _ =>
          filters.$1 == 'Active'
              ? 'No active goals yet.'
              : 'No completed goals yet.',
      };
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(emptyMessage, style: widget.bundle.textStyle),
          ),
        ),
      );
    }

    final seriesById =
        ref.watch(activeRepeatSeriesProvider).valueOrNull ?? const {};

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final goal = filteredGoals[index];
          final isHighlight =
              widget.highlightScroll.highlightGoalId == goal.goalId;
          final series = seriesById[goal.repeatSeriesId];
          return GoalsGoalListTile(
            key:
                isHighlight
                    ? widget.highlightTileKey
                    : ValueKey('goal-list-${filters.$1}-${goal.goalId}'),
            bundle: widget.bundle,
            selectedStatusFilter: filters.$1,
            goal: goal,
            highlight: isHighlight,
            repeatRule: series?.repeatRule,
            onComplete: () => widget.onComplete(goal.goalId),
            onIncrementStep: () => widget.onIncrementStep(goal.goalId),
            onViewDetails: () => widget.onViewDetails(goal),
            onRemove: () => widget.onRemove(goal.goalId),
          );
        },
        childCount: filteredGoals.length,
      ),
    );
  }
}
