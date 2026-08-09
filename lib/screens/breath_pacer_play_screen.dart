import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/achievements/notify_achievement_progress.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_achievements.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_constants.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_engine.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_painter.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/widgets/mini_game_end_overlay.dart';
import 'package:focusNexus/widgets/mini_game_hud_chrome.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

const _scoreTierColors = [
  Color(0xFF64FFC8),
  Color(0xFF64C8FF),
  Color(0xFFB8A4FF),
  Color(0xFFFFD166),
  Color(0xFFFF8A7A),
  Color(0xFFE56BFF),
  Color(0xFFF4F7FF),
];

class BreathPacerPlayScreen extends ConsumerStatefulWidget {
  const BreathPacerPlayScreen({super.key, required this.config});

  final MiniGameRoundConfig config;

  @override
  ConsumerState<BreathPacerPlayScreen> createState() =>
      _BreathPacerPlayScreenState();
}

class _BreathPacerPlayScreenState extends ConsumerState<BreathPacerPlayScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  BreathPacerEngine? _engine;
  Duration? _lastElapsed;
  bool _scoreRecorded = false;
  bool _bgmStarted = false;
  SoundService? _sounds;

  bool get _endless => widget.config.endless;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBgm());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sounds ??= ref.read(soundServiceProvider);
  }

  @override
  void dispose() {
    _ticker.dispose();
    final sounds = _sounds;
    if (sounds != null && _bgmStarted) {
      unawaited(sounds.stopMusicIfChannel(SoundChannel.breathBackground));
    }
    super.dispose();
  }

  Future<void> _startBgm() async {
    if (_bgmStarted || !mounted) return;
    _bgmStarted = true;
    final sounds = ref.read(soundServiceProvider);
    _sounds = sounds;
    final repo = ref.read(appRepositoriesProvider).ambientSoundscapes;
    final coordinator = ref.read(ambientPlaybackCoordinatorProvider);
    final started = await startFeatureMusicOrAmbientFallback(
      sounds: sounds,
      repo: repo,
      coordinator: coordinator,
      featureChannel: SoundChannel.breathBackground,
      section: AmbientAppSection.miniGames,
      loop: _endless,
    );
    if (!started) {
      _bgmStarted = false;
    }
  }

  void _ensureEngine(Size size) {
    if (_engine == null) {
      _engine = BreathPacerEngine(playSize: size, endless: _endless);
      return;
    }
    if (_engine!.playSize != size) {
      _engine!.playSize = size;
    }
  }

  void _onTick(Duration elapsed) {
    final engine = _engine;
    if (engine == null) return;
    final rawDt = _lastElapsed == null
        ? 0.016
        : (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (rawDt <= 0) return;
    final dt = engine.isFinished
        ? rawDt.clamp(0.0, 1.1)
        : (rawDt > 0.1 ? 0.1 : rawDt);
    final wasFinished = engine.isFinished;
    engine.update(dt);
    if (!wasFinished && engine.isFinished) {
      _onRoundComplete();
    }
    if (engine.isFinished && engine.endExpandT >= 1 && _ticker.isActive) {
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  Future<void> _onRoundComplete() async {
    if (_scoreRecorded) return;
    _scoreRecorded = true;
    await _sounds?.stopBreathBackground();
    final engine = _engine;
    if (engine == null) return;
    final repositories = ref.read(appRepositoriesProvider);
    await repositories.miniGames.recordScore(
      BreathPacerConstants.gameId,
      engine.roundHighScore,
      BreathPacerConstants.baseDifficulty,
      endless: _endless,
    );
    final newlyReady = await BreathPacerAchievements.recordRound(
      storage: repositories.storage,
      achievements: ref.read(achievementServiceProvider),
      score: engine.roundHighScore,
      endless: _endless,
    );
    notifyAchievementProgressUpdated(ref, newlyReady);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _endEndless() async {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    engine.endRound();
    await _onRoundComplete();
  }

  Future<void> _onTap() async {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    engine.recordTap();
    await _sounds?.playBreathClick();
  }

  Future<void> _exit() async {
    final engine = _engine;
    if (engine != null && !engine.isFinished) {
      engine.endRound();
      await _onRoundComplete();
    } else {
      await _sounds?.stopBreathBackground();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final hud = MiniGameThemedHud(bundle);
        final scheme = bundle.themeData.colorScheme;
        final titleStyle = hud.compact(fontSize: 16, fontWeight: FontWeight.w600);
        final bodyStyle = hud.compact(fontSize: 14);
        final onSurface = hud.foreground;

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: BreathPacerPainter.skyBottom,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  _ensureEngine(size);
                  final engine = _engine!;
                  final timerLabel = _endless
                      ? '${engine.elapsedSeconds.floor()}s'
                      : '${engine.remainingSeconds}s';
                  void dismiss() {
                    if (context.mounted) Navigator.of(context).pop();
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => _onTap(),
                          child: CustomPaint(
                            painter: BreathPacerPainter(engine: engine),
                            size: size,
                          ),
                        ),
                      ),
                      MiniGameHudChrome.topBar(
                        hud: hud,
                        onBack: _exit,
                        center: Text(
                          'Score',
                          style: hud.compact(fontSize: 12),
                        ),
                        timerLabel: timerLabel,
                        onEnd: (_endless && !engine.isFinished)
                            ? _endEndless
                            : null,
                      ),
                      if (!engine.isFinished || engine.endExpandT < 0.85)
                        Positioned(
                          top: 56,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _CalmScoreArc(
                              fraction: engine.scoreTierProgress,
                              color: _scoreTierColors[engine.scoreTierIndex],
                              score: engine.calmScore,
                              streak: engine.perfectStreak,
                              showStreak: _endless,
                              streakBreaking: engine.streakJustBroke,
                              burst: engine.isFinished,
                              sessionSeconds: engine.elapsedSeconds.floor(),
                              showSessionTime: _endless && engine.isFinished,
                              sessionStyle: bodyStyle,
                            ),
                          ),
                        ),
                      if (!engine.isFinished)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 48,
                          child: _PhaseLabelCrossfade(
                            previous: engine.previousPhaseLabel,
                            current: engine.phaseLabel,
                            blend: engine.phaseLabelBlend,
                            style: titleStyle,
                          ),
                        ),
                      if (engine.isFinished)
                        MiniGameEndOverlay(
                          backgroundColor: scheme.scrim.withValues(
                            alpha: 0.35 * engine.endExpandT,
                          ),
                          onDismiss: dismiss,
                          child: Opacity(
                            key: const ValueKey('breath_completion_opacity'),
                            opacity: engine.endExpandT.clamp(0.0, 1.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CalmScoreArc(
                                  fraction: engine.scoreTierProgress,
                                  color:
                                      _scoreTierColors[engine.scoreTierIndex],
                                  score: engine.calmScore,
                                  streak: engine.bestPerfectStreak,
                                  showStreak: _endless,
                                  streakBreaking: false,
                                  burst: true,
                                  sessionSeconds: engine.elapsedSeconds.floor(),
                                  showSessionTime: _endless,
                                  large: true,
                                  sessionStyle: bodyStyle,
                                ),
                                const SizedBox(height: 16),
                                Text(engine.calmReflection, style: titleStyle),
                                const SizedBox(height: 8),
                                Text(
                                  _endless
                                      ? 'Session complete'
                                      : 'Breath complete',
                                  style: bodyStyle.copyWith(
                                    color: onSurface.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextButton(
                                  onPressed: dismiss,
                                  child: Text(
                                    'Done',
                                    style: bodyStyle.copyWith(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhaseLabelCrossfade extends StatelessWidget {
  const _PhaseLabelCrossfade({
    required this.previous,
    required this.current,
    required this.blend,
    required this.style,
  });

  final String previous;
  final String current;
  final double blend;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final t = blend.clamp(0.0, 1.0);
    if (previous == current || t >= 1) {
      return SizedBox(
        height: 40,
        child: Center(child: Text(current, style: style)),
      );
    }
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 1 - t,
            child: Transform.translate(
              offset: Offset(0, -8 * t),
              child: Text(previous, style: style),
            ),
          ),
          Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - t)),
              child: Text(current, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalmScoreArc extends StatelessWidget {
  const _CalmScoreArc({
    required this.fraction,
    required this.color,
    required this.score,
    required this.streak,
    required this.showStreak,
    required this.streakBreaking,
    required this.burst,
    required this.sessionSeconds,
    required this.showSessionTime,
    this.large = false,
    this.sessionStyle,
  });

  final double fraction;
  final Color color;
  final int score;
  final int streak;
  final bool showStreak;
  final bool streakBreaking;
  final bool burst;
  final int sessionSeconds;
  final bool showSessionTime;
  final bool large;
  final TextStyle? sessionStyle;

  @override
  Widget build(BuildContext context) {
    final size = large ? 120.0 : 72.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CalmArcPainter(
              fraction: fraction.clamp(0.0, 1.0),
              color: color,
              streak: streak,
              showStreak: showStreak,
              streakBreaking: streakBreaking,
              burst: burst,
            ),
            child: Center(
              child: Text(
                '$score',
                style: (sessionStyle ?? const TextStyle()).copyWith(
                  color: color,
                  fontSize: large ? 28 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        if (showSessionTime) ...[
          const SizedBox(height: 6),
          Text(
            '${sessionSeconds}s',
            style: (sessionStyle ?? const TextStyle()).copyWith(
              color: sessionStyle?.color?.withValues(alpha: 0.75) ??
                  const Color(0xFFA8C8C0),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _CalmArcPainter extends CustomPainter {
  _CalmArcPainter({
    required this.fraction,
    required this.color,
    required this.streak,
    required this.showStreak,
    required this.streakBreaking,
    required this.burst,
  });

  final double fraction;
  final Color color;
  final int streak;
  final bool showStreak;
  final bool streakBreaking;
  final bool burst;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.42;
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, fill);

    if (burst) {
      final burstPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius * 1.25, burstPaint);
      canvas.drawCircle(center, radius * 1.45, burstPaint);
    }

    if (showStreak && streak > 0 && !streakBreaking) {
      final dots = streak.clamp(0, 24);
      final innerR = radius * 0.72;
      for (var i = 0; i < dots; i++) {
        final ang = -math.pi / 2 + (i / 24) * math.pi * 2;
        final p = Offset(
          center.dx + math.cos(ang) * innerR,
          center.dy + math.sin(ang) * innerR,
        );
        canvas.drawCircle(p, 2.2, Paint()..color = const Color(0xFFE8C86A));
      }
    } else if (showStreak && streakBreaking) {
      final innerR = radius * 0.85;
      for (var i = 0; i < 8; i++) {
        final ang = i * math.pi / 4;
        final p = Offset(
          center.dx + math.cos(ang) * innerR,
          center.dy + math.sin(ang) * innerR,
        );
        canvas.drawCircle(
          p,
          1.6,
          Paint()..color = const Color(0xFFE8C86A).withValues(alpha: 0.35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalmArcPainter oldDelegate) => true;
}
