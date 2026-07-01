import 'dart:async';

import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/goal_set.dart';

/// Scrolls the goals list until a notification-highlighted goal tile is visible.
class GoalsHighlightScrollCoordinator {
  GoalsHighlightScrollCoordinator({
    required ScrollController scrollController,
    required GlobalKey highlightTileKey,
  })  : _scrollController = scrollController,
        _highlightTileKey = highlightTileKey;

  final ScrollController _scrollController;
  final GlobalKey _highlightTileKey;

  int? highlightGoalId;
  bool scrolledToHighlight = false;

  /// Schedules scroll once [filteredGoals] contains [highlightGoalId].
  void notifyFilteredGoals(List<GoalSet> filteredGoals) {
    if (highlightGoalId == null || scrolledToHighlight) return;
    final highlightIndex = filteredGoals.indexWhere(
      (g) => g.goalId == highlightGoalId,
    );
    if (highlightIndex < 0) return;
    schedule(highlightIndex: highlightIndex);
  }

  void schedule({int? highlightIndex}) {
    if (highlightGoalId == null || scrolledToHighlight) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_scrollToHighlightedGoal(highlightIndex: highlightIndex)),
    );
  }

  Future<void> _scrollToHighlightedGoal({
    int? highlightIndex,
    int attempt = 0,
  }) async {
    if (highlightGoalId == null || scrolledToHighlight || attempt > 12) {
      return;
    }
    final tileContext = _highlightTileKey.currentContext;
    if (tileContext == null) {
      if (highlightIndex != null &&
          highlightIndex > 0 &&
          _scrollController.hasClients) {
        const headerEstimate = 980.0;
        const tileHeight = 76.0;
        final targetOffset = (headerEstimate + highlightIndex * tileHeight).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        await _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else if (_scrollController.hasClients && attempt > 0) {
        final nudge = (attempt * 140.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        await _scrollController.animateTo(
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
    scrolledToHighlight = true;
  }
}
