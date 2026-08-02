import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_constants.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_engine.dart';

void main() {
  BreathPacerEngine engine({bool endless = false, int seed = 1}) {
    return BreathPacerEngine(
      playSize: const Size(400, 700),
      endless: endless,
      random: math.Random(seed),
    );
  }

  test('phase progression follows 4-4-6-2 Inhale Hold Exhale Hold', () {
    final e = engine();
    expect(e.phase, BreathPhase.inhale);
    e.update(3.5);
    expect(e.phase, BreathPhase.inhale);
    e.update(0.6);
    expect(e.phase, BreathPhase.holdIn);
    e.update(3.5);
    expect(e.phase, BreathPhase.holdIn);
    e.update(0.6);
    expect(e.phase, BreathPhase.exhale);
    e.update(5.5);
    expect(e.phase, BreathPhase.exhale);
    e.update(0.6);
    expect(e.phase, BreathPhase.holdOut);
    e.update(2.1);
    expect(e.phase, BreathPhase.inhale);
    expect(e.completedCycles, 1);
  });

  test('duration mode ends after configured seconds', () {
    final e = engine();
    e.update(BreathPacerConstants.durationSeconds.toDouble());
    expect(e.isFinished, isTrue);
    expect(e.remainingSeconds, 0);
  });

  test('endless mode does not auto-finish', () {
    final e = engine(endless: true);
    e.update(BreathPacerConstants.durationSeconds.toDouble() * 2);
    expect(e.isFinished, isFalse);
    expect(e.remainingSeconds, 0);
  });

  test('score starts at zero', () {
    final e = engine();
    e.update(20);
    expect(e.calmScore, 0);
  });

  test('score can exceed 100 across distinct transitions', () {
    final e = engine();
    e.update(BreathPacerConstants.inhaleSeconds);
    expect(e.recordTap(), TapGrade.perfect);
    e.update(BreathPacerConstants.holdInSeconds);
    expect(e.recordTap(), TapGrade.perfect);
    expect(e.calmScore, greaterThan(100));
  });

  test('only first qualifying tap counts for a transition', () {
    final e = engine();
    e.update(BreathPacerConstants.inhaleSeconds);

    expect(e.recordTap(), TapGrade.perfect);
    e.update(0.2);
    expect(e.recordTap(), TapGrade.miss);

    expect(e.perfectTaps, 1);
    expect(e.goodTaps, 0);
  });

  test('rapid taps are penalized instead of increasing score', () {
    final e = engine();
    e.update(BreathPacerConstants.inhaleSeconds);
    expect(e.recordTap(), TapGrade.perfect);
    final scoreAfterPerfect = e.calmScore;

    for (var i = 0; i < 10; i++) {
      e.update(0.01);
      expect(e.recordTap(), TapGrade.miss);
    }

    expect(e.perfectTaps, 1);
    expect(e.calmScore, lessThan(scoreAfterPerfect));
  });

  test('round high score keeps the maximum before later penalties', () {
    final e = engine();
    e.update(BreathPacerConstants.inhaleSeconds);
    e.recordTap();
    e.update(BreathPacerConstants.holdInSeconds);
    e.recordTap();
    expect(e.calmScore, 200);
    expect(e.roundHighScore, 200);

    e.update(0.5);
    e.recordTap();
    expect(e.calmScore, lessThan(200));
    expect(e.roundHighScore, 200);
  });

  test('penalties at zero do not create hidden score debt', () {
    final e = engine();
    for (var i = 0; i < 6; i++) {
      e.update(0.5);
      expect(e.recordTap(), TapGrade.miss);
    }
    expect(e.calmScore, 0);

    e.update(1);
    expect(e.recordTap(), TapGrade.perfect);
    expect(e.calmScore, BreathPacerConstants.perfectTapPoints);
  });

  test('score tier progress follows configured inclusive boundaries', () {
    final e = engine();
    expect(e.scoreTierIndex, 0);
    expect(e.scoreTierProgress, 0);

    e.update(BreathPacerConstants.inhaleSeconds);
    e.recordTap();
    e.update(BreathPacerConstants.holdInSeconds);
    e.recordTap();
    expect(e.calmScore, 200);
    expect(e.scoreTierIndex, 0);
    expect(e.scoreTierProgress, 1);

    e.update(BreathPacerConstants.exhaleSeconds);
    e.recordTap();
    expect(e.calmScore, 300);
    expect(e.scoreTierIndex, 1);
    expect(e.scoreTierProgress, closeTo(100 / 300, 0.001));
  });

  test('endless mode halves windows and doubles penalties after duration', () {
    final e = engine(endless: true);
    expect(e.perfectTapWindow, BreathPacerConstants.perfectTapSeconds);
    expect(e.missPenalty, BreathPacerConstants.missPenaltyPoints);

    e.update(BreathPacerConstants.durationSeconds.toDouble());

    expect(e.perfectTapWindow, BreathPacerConstants.perfectTapSeconds / 2);
    expect(e.goodTapWindow, BreathPacerConstants.goodTapSeconds / 2);
    expect(e.missPenalty, BreathPacerConstants.missPenaltyPoints * 2);
    expect(e.rapidTapPenalty, BreathPacerConstants.rapidTapPenaltyPoints * 2);
  });

  test('incoming transition cue contracts before perfect window begins', () {
    final e = engine();
    e.update(3.0);
    expect(e.incomingTransitionCueProgress, closeTo(0, 0.01));

    e.update(0.8);
    expect(e.incomingTransitionCueProgress, greaterThan(0.8));

    e.update(0.06);
    expect(e.incomingTransitionCueProgress, isNull);
  });

  test('miss tap dims without ripple text grade', () {
    final e = engine();
    e.update(1.0);
    expect(e.recordTap(), TapGrade.miss);
    expect(e.ripples, isEmpty);
    expect(e.floatingCues, isEmpty);
    expect(e.circleOpacity, lessThan(1.0));
  });

  test('endless pattern evolves every 3 cycles', () {
    final e = engine(endless: true);
    expect(e.pattern.holdIn, 4);
    // One cycle is 16s for 4-4-6-2.
    e.update(16 * 3);
    expect(e.completedCycles, greaterThanOrEqualTo(3));
    expect(e.pattern.holdIn, 7);
    expect(e.pattern.holdOut, 0);
  });

  test('dawn strength rises in last 60 seconds of duration', () {
    final e = engine();
    e.update(20);
    expect(e.dawnStrength, 0);
    e.update(20); // 40s elapsed => 50s remaining => dawn active
    expect(e.dawnStrength, greaterThan(0));
  });
}
