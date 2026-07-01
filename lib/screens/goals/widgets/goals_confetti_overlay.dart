import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'package:focusNexus/goals/goals_use_case.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Confetti burst + completion snackbar for goal completion.
class GoalsConfettiOverlay extends StatefulWidget {
  const GoalsConfettiOverlay({
    super.key,
    required this.bundle,
    required this.onPlayGoalCompletedSound,
    required this.child,
  });

  final ThemeBundle bundle;
  final Future<void> Function() onPlayGoalCompletedSound;
  final Widget child;

  @override
  State<GoalsConfettiOverlay> createState() => GoalsConfettiOverlayState();
}

class GoalsConfettiOverlayState extends State<GoalsConfettiOverlay> {
  late final ConfettiController _controller = ConfettiController(
    duration: const Duration(seconds: 1),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Repaint the list first, then confetti/snackbar/sound on the next frame.
  void celebrateCompletion(CompleteGoalResult result) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.play();
      CommonUtils.showSnackBar(
        context,
        '${result.goal.title} completed! +${result.pointsAwarded} points. '
        'Goals completed today: ${result.goalsCompletedToday}',
        widget.bundle.textStyle,
        2000,
        5,
        backgroundColor: widget.bundle.secondaryColor,
        labelColor: widget.bundle.primaryColor,
      );
      unawaited(widget.onPlayGoalCompletedSound());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}
