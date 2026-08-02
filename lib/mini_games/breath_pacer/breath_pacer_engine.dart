import 'dart:math' as math;
import 'dart:ui';

import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_constants.dart';

enum BreathPhase { inhale, holdIn, exhale, holdOut }

enum TapGrade { perfect, good, miss }

class _TapEvaluation {
  const _TapEvaluation(this.grade, this.opportunityId);

  final TapGrade grade;
  final int? opportunityId;
}

class BreathPattern {
  const BreathPattern({
    required this.inhale,
    required this.holdIn,
    required this.exhale,
    required this.holdOut,
  });

  final double inhale;
  final double holdIn;
  final double exhale;
  final double holdOut;

  double get cycleSeconds => inhale + holdIn + exhale + holdOut;
}

class OuterBreathParticle {
  OuterBreathParticle({
    required this.angle,
    required this.seed,
    required this.size,
  });

  double angle;
  final double seed;
  final double size;
}

class InnerBreathParticle {
  InnerBreathParticle({
    required this.baseAngle,
    required this.seed,
    required this.size,
  });

  final double baseAngle;
  final double seed;
  final double size;
}

class RippleFx {
  RippleFx({required this.grade, required this.bornAt});

  final TapGrade grade;
  final double bornAt;
  static const double life = 0.4;

  double age(double now) => now - bornAt;
  bool isDone(double now) => age(now) >= life;
}

class FloatingCueFx {
  FloatingCueFx({required this.label, required this.bornAt});

  final String label;
  final double bornAt;
  static const double life = 0.6;

  double age(double now) => now - bornAt;
  bool isDone(double now) => age(now) >= life;
}

class TransitionWaveFx {
  TransitionWaveFx({required this.bornAt});

  final double bornAt;
  static const double life = 0.55;

  double age(double now) => now - bornAt;
  bool isDone(double now) => age(now) >= life;
}

/// Pure playfield simulation for Breath Pacer.
class BreathPacerEngine {
  BreathPacerEngine({
    required this.playSize,
    required this.endless,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    _patternIndex = 0;
    _pattern = endlessPatterns[_patternIndex];
    _seedParticles();
  }

  static const List<BreathPattern> endlessPatterns = <BreathPattern>[
    BreathPattern(inhale: 4, holdIn: 4, exhale: 6, holdOut: 2),
    BreathPattern(inhale: 4, holdIn: 7, exhale: 8, holdOut: 0),
    BreathPattern(inhale: 5, holdIn: 5, exhale: 7, holdOut: 3),
  ];

  static const BreathPattern durationPattern = BreathPattern(
    inhale: BreathPacerConstants.inhaleSeconds,
    holdIn: BreathPacerConstants.holdInSeconds,
    exhale: BreathPacerConstants.exhaleSeconds,
    holdOut: BreathPacerConstants.holdOutSeconds,
  );

  Size playSize;
  final bool endless;
  final math.Random _random;

  final List<OuterBreathParticle> outerParticles = <OuterBreathParticle>[];
  final List<InnerBreathParticle> innerParticles = <InnerBreathParticle>[];
  final List<double> _transitionTargets = <double>[];
  final Set<int> _claimedOpportunityIds = <int>{};
  final List<RippleFx> ripples = <RippleFx>[];
  final List<FloatingCueFx> floatingCues = <FloatingCueFx>[];
  final List<TransitionWaveFx> transitionWaves = <TransitionWaveFx>[];

  double elapsedSeconds = 0;
  double phaseTime = 0;
  bool isFinished = false;
  double endExpandT = 0;

  BreathPhase phase = BreathPhase.inhale;
  BreathPhase? previousPhase;
  double phaseLabelBlend = 1;
  int completedCycles = 0;
  int _patternIndex = 0;
  late BreathPattern _pattern;

  int perfectTaps = 0;
  int goodTaps = 0;
  int missTaps = 0;
  int _earnedPoints = 0;
  int _penaltyPoints = 0;
  int _roundHighScore = 0;
  double _lastTapAt = double.negativeInfinity;
  int perfectStreak = 0;
  int bestPerfectStreak = 0;
  bool streakJustBroke = false;
  double streakBreakAge = 0;
  double particleFlashUntil = -1;
  double missDimUntil = -1;
  TapGrade? lastTapGrade;

  BreathPattern get pattern => endless ? _pattern : durationPattern;

  int get remainingSeconds {
    if (endless) return 0;
    final left = BreathPacerConstants.durationSeconds - elapsedSeconds;
    return left <= 0 ? 0 : left.ceil();
  }

  String get phaseLabel => switch (phase) {
    BreathPhase.inhale => 'Inhale',
    BreathPhase.holdIn || BreathPhase.holdOut => 'Hold',
    BreathPhase.exhale => 'Exhale',
  };

  String get previousPhaseLabel {
    final prior = previousPhase;
    if (prior == null) return phaseLabel;
    return switch (prior) {
      BreathPhase.inhale => 'Inhale',
      BreathPhase.holdIn || BreathPhase.holdOut => 'Hold',
      BreathPhase.exhale => 'Exhale',
    };
  }

  double get phaseProgress {
    final duration = _phaseDuration(phase);
    if (duration <= 0) return 1;
    return (phaseTime / duration).clamp(0.0, 1.0);
  }

  double get orbitSpeedScale {
    if (endless) return 1;
    if (remainingSeconds <= BreathPacerConstants.windDownSeconds) {
      return 0.55;
    }
    return 1;
  }

  double get windDownGrow {
    if (endless) return 1;
    if (remainingSeconds > BreathPacerConstants.windDownSeconds) return 1;
    final t =
        1 -
        (remainingSeconds / BreathPacerConstants.windDownSeconds).clamp(
          0.0,
          1.0,
        );
    return 1 + 0.10 * t;
  }

  /// Dawn wash strength for Duration (0-1 in last 60s).
  double get dawnStrength {
    if (endless) return 0;
    if (remainingSeconds > BreathPacerConstants.dawnStartRemainingSeconds) {
      return 0;
    }
    final consumed =
        BreathPacerConstants.dawnStartRemainingSeconds -
        remainingSeconds.toDouble();
    return (consumed / BreathPacerConstants.dawnStartRemainingSeconds).clamp(
      0.0,
      1.0,
    );
  }

  /// Endless day-cycle phase: 0 night, ~0.35 dawn, ~0.5 midday, ~0.75 dusk, 1 twilight.
  double get endlessDayCycle {
    if (!endless) return 0;
    final minutes = elapsedSeconds / 60.0;
    if (minutes <= 5) return (minutes / 5.0) * 0.5;
    if (minutes <= 10) return 0.5 + ((minutes - 5) / 5.0) * 0.35;
    return (0.85 + ((minutes - 10) / 10.0) * 0.15).clamp(0.0, 1.0);
  }

  double get holdPulse {
    if (phase != BreathPhase.holdIn && phase != BreathPhase.holdOut) {
      return 0;
    }
    final wave =
        0.5 +
        0.5 *
            math.sin(
              (elapsedSeconds * math.pi * 2) /
                  BreathPacerConstants.holdPulseSeconds,
            );
    return wave;
  }

  double get baseRadiusFraction {
    final minR = BreathPacerConstants.minRadiusFraction;
    final maxR = BreathPacerConstants.maxRadiusFraction;
    final p = phaseProgress;
    final core = switch (phase) {
      BreathPhase.inhale => minR + (maxR - minR) * _easeOut(p),
      BreathPhase.holdIn => maxR,
      BreathPhase.exhale => maxR - (maxR - minR) * _easeInOut(p),
      BreathPhase.holdOut => minR,
    };
    return core * windDownGrow;
  }

  double get circleRadiusPx {
    final base = playSize.shortestSide * baseRadiusFraction;
    final pulsePx = holdPulse * BreathPacerConstants.holdPulseRadiusPx;
    final expand = isFinished ? 1 + endExpandT * 2.4 : 1.0;
    return (base + pulsePx) * expand;
  }

  double get circleOpacity {
    var opacity = 1.0;
    if (elapsedSeconds < missDimUntil) {
      opacity *= 0.70;
    }
    if (phase == BreathPhase.holdIn || phase == BreathPhase.holdOut) {
      opacity *= 1 - BreathPacerConstants.holdPulseOpacity * holdPulse;
    }
    if (isFinished) {
      opacity *= (1 - endExpandT).clamp(0.0, 1.0);
    }
    return opacity.clamp(0.0, 1.0);
  }

  bool get particlesFlashing => elapsedSeconds < particleFlashUntil;

  int get transitionOpportunities => _transitionTargets.length;

  /// Unbounded round score. Duration and Endless high scores remain meaningful.
  int get calmScore => math.max(0, _earnedPoints - _penaltyPoints);

  /// Highest score reached at any point, unaffected by later penalties.
  int get roundHighScore => _roundHighScore;

  bool get isEndlessHardMode =>
      endless && elapsedSeconds >= BreathPacerConstants.durationSeconds;

  double get perfectTapWindow =>
      BreathPacerConstants.perfectTapSeconds *
      (isEndlessHardMode ? BreathPacerConstants.endlessHardModeWindowScale : 1);

  double get goodTapWindow =>
      BreathPacerConstants.goodTapSeconds *
      (isEndlessHardMode ? BreathPacerConstants.endlessHardModeWindowScale : 1);

  int get missPenalty =>
      BreathPacerConstants.missPenaltyPoints *
      (isEndlessHardMode
          ? BreathPacerConstants.endlessHardModePenaltyMultiplier
          : 1);

  int get rapidTapPenalty =>
      BreathPacerConstants.rapidTapPenaltyPoints *
      (isEndlessHardMode
          ? BreathPacerConstants.endlessHardModePenaltyMultiplier
          : 1);

  int get scoreTierIndex {
    final score = calmScore;
    for (var i = 0; i < BreathPacerConstants.scoreTierUpperBounds.length; i++) {
      if (score <= BreathPacerConstants.scoreTierUpperBounds[i]) return i;
    }
    return BreathPacerConstants.scoreTierUpperBounds.length;
  }

  /// Progress from the previous tier ceiling to this tier's ceiling.
  /// The final 5001+ tier is complete because it has no upper target.
  double get scoreTierProgress {
    final tier = scoreTierIndex;
    final upperBounds = BreathPacerConstants.scoreTierUpperBounds;
    if (tier >= upperBounds.length) return 1;
    final lower = tier == 0 ? 0 : upperBounds[tier - 1];
    return ((calmScore - lower) / (upperBounds[tier] - lower)).clamp(0.0, 1.0);
  }

  String get calmReflection {
    final accepted = perfectTaps + goodTaps;
    final total = accepted + missTaps;
    final quality = total == 0 ? 0.0 : (perfectTaps + goodTaps * 0.6) / total;
    if (quality >= 0.85) return 'Settled';
    if (quality >= 0.60) return 'Steady';
    return 'Warming up';
  }

  /// 0 at the outer edge, 1 at the core. Null once the perfect window starts.
  double? get incomingTransitionCueProgress {
    final remaining = _phaseDuration(phase) - phaseTime;
    final lead = BreathPacerConstants.transitionCueLeadSeconds;
    final perfect = perfectTapWindow;
    if (remaining > lead + 1e-6 || remaining <= perfect) return null;
    return ((lead - remaining) / (lead - perfect)).clamp(0.0, 1.0);
  }

  Color circleCenterColor() {
    return switch (phase) {
      BreathPhase.inhale => Color.lerp(
        const Color(0xFF2A6B8A),
        const Color(0xFF3A8AAA),
        phaseProgress,
      )!,
      BreathPhase.holdIn => const Color(0xFF3A8AAA),
      BreathPhase.exhale => Color.lerp(
        const Color(0xFF3A8AAA),
        const Color(0xFF1A3A5A),
        phaseProgress,
      )!,
      BreathPhase.holdOut => const Color(0xFF1A3A5A),
    };
  }

  Color circleEdgeColor() {
    return switch (phase) {
      BreathPhase.inhale => Color.lerp(
        const Color(0xFF1A4A6A),
        const Color(0xFF2A6B8A),
        phaseProgress,
      )!,
      BreathPhase.holdIn => const Color(0xFF2A6B8A),
      BreathPhase.exhale => Color.lerp(
        const Color(0xFF2A6B8A),
        const Color(0xFF1A3A5A),
        phaseProgress,
      )!,
      BreathPhase.holdOut => const Color(0xFF14283A),
    };
  }

  void update(double dt) {
    if (dt <= 0) return;
    if (isFinished) {
      endExpandT = (endExpandT + dt / 1.1).clamp(0.0, 1.0);
      _pruneFx();
      return;
    }

    var remaining = dt;
    while (remaining > 0 && !isFinished) {
      final simDt = remaining > 0.1 ? 0.1 : remaining;
      remaining -= simDt;

      elapsedSeconds += simDt;
      phaseTime += simDt;
      if (phaseLabelBlend < 1) {
        phaseLabelBlend = (phaseLabelBlend + simDt / 0.3).clamp(0.0, 1.0);
      }
      if (streakJustBroke) {
        streakBreakAge += simDt;
        if (streakBreakAge > 0.8) {
          streakJustBroke = false;
        }
      }

      _orbitOuter(simDt);

      while (phaseTime >= _phaseDuration(phase) - 1e-9) {
        final over = phaseTime - _phaseDuration(phase);
        phaseTime = over < 0 ? 0 : over;
        _advancePhase();
        if (isFinished) break;
      }

      if (!endless && elapsedSeconds >= BreathPacerConstants.durationSeconds) {
        elapsedSeconds = BreathPacerConstants.durationSeconds.toDouble();
        isFinished = true;
      }
    }
    _pruneFx();
  }

  TapGrade recordTap() {
    if (isFinished) return TapGrade.miss;
    final now = elapsedSeconds;
    final rapid =
        now - _lastTapAt < BreathPacerConstants.rapidTapIntervalSeconds;
    _lastTapAt = now;
    if (rapid) {
      _recordMiss(now, rapid: true);
      return TapGrade.miss;
    }

    final evaluation = _evaluateTap(now);
    var grade = evaluation.grade;
    final opportunityId = evaluation.opportunityId;
    if (grade != TapGrade.miss &&
        (opportunityId == null ||
            _claimedOpportunityIds.contains(opportunityId))) {
      grade = TapGrade.miss;
    }
    lastTapGrade = grade;

    switch (grade) {
      case TapGrade.perfect:
        _claimedOpportunityIds.add(opportunityId!);
        perfectTaps += 1;
        _earnedPoints += BreathPacerConstants.perfectTapPoints;
        _roundHighScore = math.max(_roundHighScore, calmScore);
        perfectStreak += 1;
        if (perfectStreak > bestPerfectStreak) {
          bestPerfectStreak = perfectStreak;
        }
        ripples.add(RippleFx(grade: grade, bornAt: now));
        floatingCues.add(FloatingCueFx(label: 'Perfect', bornAt: now));
        particleFlashUntil = now + 0.15;
      case TapGrade.good:
        _claimedOpportunityIds.add(opportunityId!);
        goodTaps += 1;
        _earnedPoints += BreathPacerConstants.goodTapPoints;
        _roundHighScore = math.max(_roundHighScore, calmScore);
        _breakStreak();
        ripples.add(RippleFx(grade: grade, bornAt: now));
        floatingCues.add(FloatingCueFx(label: 'Good', bornAt: now));
      case TapGrade.miss:
        _recordMiss(now);
    }
    return grade;
  }

  void endRound() {
    if (isFinished) return;
    isFinished = true;
  }

  void _breakStreak() {
    if (perfectStreak > 0) {
      streakJustBroke = true;
      streakBreakAge = 0;
    }
    perfectStreak = 0;
  }

  void _recordMiss(double now, {bool rapid = false}) {
    lastTapGrade = TapGrade.miss;
    missTaps += 1;
    final penalty = rapid ? rapidTapPenalty : missPenalty;
    // Keep zero as a true floor: misses cannot create invisible debt that
    // future successful taps must repay.
    _penaltyPoints = math.min(_earnedPoints, _penaltyPoints + penalty);
    _breakStreak();
    missDimUntil = now + 0.2;
  }

  _TapEvaluation _evaluateTap(double now) {
    var best = _phaseDuration(phase) - phaseTime;
    var opportunityId = _transitionTargets.length;

    for (var i = 0; i < _transitionTargets.length; i++) {
      final target = _transitionTargets[i];
      final d = (now - target).abs();
      if (d < best) {
        best = d;
        opportunityId = i;
      }
    }

    if (best <= perfectTapWindow) {
      return _TapEvaluation(TapGrade.perfect, opportunityId);
    }
    if (best <= goodTapWindow) {
      return _TapEvaluation(TapGrade.good, opportunityId);
    }
    return const _TapEvaluation(TapGrade.miss, null);
  }

  void _advancePhase() {
    previousPhase = phase;
    phaseLabelBlend = 0;
    _transitionTargets.add(elapsedSeconds);
    transitionWaves.add(TransitionWaveFx(bornAt: elapsedSeconds));

    if (phase == BreathPhase.inhale) {
      phase = BreathPhase.holdIn;
      return;
    }
    if (phase == BreathPhase.holdIn) {
      phase = BreathPhase.exhale;
      return;
    }
    if (phase == BreathPhase.exhale) {
      if (pattern.holdOut > 0) {
        phase = BreathPhase.holdOut;
      } else {
        _completeCycle();
        phase = BreathPhase.inhale;
      }
      return;
    }
    _completeCycle();
    phase = BreathPhase.inhale;
  }

  void _completeCycle() {
    completedCycles += 1;
    if (!endless) return;
    if (completedCycles % 3 == 0) {
      _patternIndex = (_patternIndex + 1) % endlessPatterns.length;
      _pattern = endlessPatterns[_patternIndex];
    }
  }

  double _phaseDuration(BreathPhase target) {
    final p = pattern;
    return switch (target) {
      BreathPhase.inhale => p.inhale,
      BreathPhase.holdIn => p.holdIn,
      BreathPhase.exhale => p.exhale,
      BreathPhase.holdOut => p.holdOut <= 0 ? 0.0001 : p.holdOut,
    };
  }

  /// Angle of the outer-ring active marker (comet head).
  double get outerMarkerAngle =>
      (elapsedSeconds * 0.35 * orbitSpeedScale) % (math.pi * 2);

  void _orbitOuter(double dt) {
    final speed = 0.35 * orbitSpeedScale;
    for (final p in outerParticles) {
      p.angle += speed * dt;
    }
  }

  void _seedParticles() {
    outerParticles.clear();
    innerParticles.clear();
    for (var i = 0; i < BreathPacerConstants.outerParticleCount; i++) {
      outerParticles.add(
        OuterBreathParticle(
          angle: (i / BreathPacerConstants.outerParticleCount) * math.pi * 2,
          seed: _random.nextDouble(),
          size: 4 + _random.nextDouble() * 2,
        ),
      );
    }
    for (var i = 0; i < BreathPacerConstants.innerParticleCount; i++) {
      innerParticles.add(
        InnerBreathParticle(
          baseAngle:
              (i / BreathPacerConstants.innerParticleCount) * math.pi * 2,
          seed: _random.nextDouble(),
          size: 2 + _random.nextDouble(),
        ),
      );
    }
  }

  /// Inner ring angles: cluster near expected transition points.
  double innerAngle(InnerBreathParticle particle) {
    final clustered = _transitionClusterBias();
    return particle.baseAngle +
        math.sin(particle.baseAngle * 3 + particle.seed) * clustered;
  }

  double _transitionClusterBias() {
    if (phase == BreathPhase.holdIn || phase == BreathPhase.holdOut) {
      return 0.55;
    }
    final nearEnd = phaseProgress > 0.75;
    return nearEnd ? 0.12 : 0.35;
  }

  void _pruneFx() {
    final now = elapsedSeconds;
    ripples.removeWhere((r) => r.isDone(now));
    floatingCues.removeWhere((c) => c.isDone(now));
    transitionWaves.removeWhere((w) => w.isDone(now));
  }

  double _easeOut(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final u = 1 - clamped;
    return 1 - (u * u * u);
  }

  double _easeInOut(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return 0.5 - 0.5 * math.cos(math.pi * clamped);
  }
}
