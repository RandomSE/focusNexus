import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/achievement_ready_toast_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Serializes achievement-ready snackbars on the goals screen.
class GoalsAchievementToastCoordinator {
  bool _showing = false;

  void onQueueChanged({
    required WidgetRef ref,
    required BuildContext context,
    required ThemeBundle bundle,
    required List<AchievementReadyToast>? previous,
    required List<AchievementReadyToast> next,
    required bool Function() isMounted,
  }) {
    if (next.isEmpty) return;
    final wasEmpty = previous == null || previous.isEmpty;
    if (wasEmpty) {
      _showNext(
        ref: ref,
        context: context,
        bundle: bundle,
        isMounted: isMounted,
      );
    }
  }

  void _showNext({
    required WidgetRef ref,
    required BuildContext context,
    required ThemeBundle bundle,
    required bool Function() isMounted,
  }) {
    if (_showing || !isMounted()) return;
    final queue = ref.read(achievementReadyToastQueueProvider);
    if (queue.isEmpty) return;

    _showing = true;
    final toast = queue.first;
    CommonUtils.showSnackBar(
      context,
      'Achievement ready: ${toast.title}',
      bundle.textStyle,
      toast.durationMs,
      5,
      backgroundColor: bundle.secondaryColor,
      labelColor: bundle.primaryColor,
    );
    Future<void>.delayed(Duration(milliseconds: toast.durationMs + 50), () {
      if (!isMounted() || !context.mounted) return;
      ref.read(achievementReadyToastQueueProvider.notifier).consumeHead();
      _showing = false;
      _showNext(
        ref: ref,
        context: context,
        bundle: bundle,
        isMounted: isMounted,
      );
    });
  }
}
