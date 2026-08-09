import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/achievements/notify_achievement_progress.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/mini_games/meteor_catch/meteor_catch_achievements.dart';
import 'package:focusNexus/mini_games/meteor_catch/meteor_catch_engine.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/mini_game_catalog_provider.dart';
import 'package:focusNexus/widgets/mini_game_end_overlay.dart';
import 'package:focusNexus/widgets/mini_game_hud_chrome.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Breath-pacer-aligned streak tier colors (mint → near-white).
const _meteorStreakTierColors = [
  Color(0xFF64FFC8),
  Color(0xFF64C8FF),
  Color(0xFFB8A4FF),
  Color(0xFFFFD166),
  Color(0xFFFF8A7A),
  Color(0xFFE56BFF),
  Color(0xFFF4F7FF),
];

int _meteorStreakTierIndex(int streak) {
  if (streak >= 50) return 5;
  if (streak >= 40) return 4;
  if (streak >= 30) return 3;
  if (streak >= 20) return 2;
  if (streak >= 10) return 1;
  return 0;
}

/// Night sky, tapered meteors, swipe trails, and catch FX (no drag cursor).
class MeteorCatchPainter extends CustomPainter {
  MeteorCatchPainter({required this.engine});

  final MeteorCatchEngine engine;

  static const Color skyEdge = Color(0xFF03060F);
  static const Color skyMid = Color(0xFF0A1228);
  static const Color skyCenter = Color(0xFF121C3A);
  static const Color meteorCore = Color(0xFFFFFAEE);
  static const Color meteorGlow = Color(0x66FFE566);
  static const Color standardTailHot = Color(0xFFFFE566);
  static const Color standardTailCool = Color(0xFFFF9A2C);
  static const Color iceCore = Color(0xFFC8E8FF);
  static const Color iceGlow = Color(0x6696DCFF);
  static const Color iceTailCool = Color(0xFF6AB4FF);
  static const Color fireCore = Color(0xFFFFFFFF);
  static const Color fireGlow = Color(0x99FF7832);
  static const Color fireTailWarm = Color(0xFFFF6420);
  static const Color fireTailHot = Color(0xFFFF2200);
  static const Color goldenCore = Color(0xFFFFF4A8);
  static const Color goldenGlow = Color(0x99FFD54A);
  static const Color decoyCore = Color(0xFFE8E8F0);
  static const Color decoyGlow = Color(0x668888B0);
  static const Color innerTail = Color(0x99FFFFFF);

  static const Color sky = skyEdge;

  /// Calm mint chrome on navy - readable, not confused with meteor cores.
  static const Color approachCore = Color(0xFF7DFFD8);
  static const Color approachGlow = Color(0x667DFFD8);
  static const Color approachStem = Color(0xCCB8FFF0);

  /// Decoy / trick meteor warnings: clear danger red on the night sky.
  static const Color decoyApproachCore = Color(0xFFFF5A5A);
  static const Color decoyApproachGlow = Color(0x66FF5A5A);
  static const Color decoyApproachStem = Color(0xCCFFB0B0);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintStars(canvas, size);

    for (final spark in engine.fireSparks) {
      _paintFireSpark(canvas, spark);
    }

    for (final warning in engine.approachWarnings) {
      _paintApproachWarning(canvas, warning);
    }

    for (final meteor in engine.meteors) {
      if (meteor.hasLeftPlayPath(size)) continue;
      _paintMeteor(canvas, size, meteor);
    }

    for (final trail in engine.swipeTrails) {
      _paintSwipeTrail(canvas, trail);
    }

    _paintSwipePreview(canvas);

    for (final burst in engine.catchBursts) {
      _paintCatchBurst(canvas, size, burst);
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: const [skyCenter, skyMid, skyEdge],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.45, size.height * 0.35),
              radius: size.longestSide * 0.9,
            ),
          );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintStars(Canvas canvas, Size size) {
    if (engine.starfieldRotationRadians.abs() > 0.0001) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(engine.starfieldRotationRadians);
      canvas.translate(-size.width / 2, -size.height / 2);
    }
    for (final star in engine.stars) {
      canvas.drawCircle(
        Offset(star.nx * size.width, star.ny * size.height),
        star.radius,
        Paint()..color = Colors.white.withValues(alpha: star.opacity),
      );
    }
    if (engine.starfieldRotationRadians.abs() > 0.0001) {
      canvas.restore();
    }
  }

  (Color core, Color glow) _colorsFor(MeteorKind kind) {
    return switch (kind) {
      MeteorKind.ice => (iceCore, iceGlow),
      MeteorKind.fire => (fireCore, fireGlow),
      MeteorKind.golden => (goldenCore, goldenGlow),
      MeteorKind.decoy => (decoyCore, decoyGlow),
      MeteorKind.standard => (meteorCore, meteorGlow),
    };
  }

  void _paintApproachWarning(Canvas canvas, ApproachWarning warning) {
    final alpha = warning.opacity;
    if (alpha <= 0.02) return;
    final dir = warning.direction;
    if (dir == Offset.zero) return;
    final decoy = warning.kind == MeteorKind.decoy;
    final core = decoy ? decoyApproachCore : approachCore;
    final glow = decoy ? decoyApproachGlow : approachGlow;
    final stem = decoy ? decoyApproachStem : approachStem;
    final scale = warning.arrowLengthScale;
    final perp = Offset(-dir.dy, dir.dx);
    final tip = warning.anchor + dir * (14 * scale);
    final base = warning.anchor - dir * (4 * scale);
    final wing = 9 * scale;
    final left = base + perp * wing;
    final right = base - perp * wing;

    canvas.drawCircle(
      warning.anchor,
      11,
      Paint()
        ..color = glow.withValues(alpha: alpha * 0.55)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      warning.anchor,
      5.5,
      Paint()
        ..color = core.withValues(alpha: alpha * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final chevron = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(
      chevron,
      Paint()
        ..color = core.withValues(alpha: alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      warning.anchor - dir * (10 * scale),
      warning.anchor + dir * (2 * scale),
      Paint()
        ..color = stem.withValues(alpha: alpha * 0.85)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintMeteor(Canvas canvas, Size size, Meteor meteor) {
    final colors = _colorsFor(meteor.kind);
    final head = meteor.head;
    final tail = meteor.trailEndFor(size);
    final unit = meteor.velocityUnit;
    if (unit == Offset.zero) return;

    final perpendicular = Offset(-unit.dy, unit.dx);
    final tailHalfWidth = 3.0 * meteor.headScale;
    final taperedTail = Path()
      ..moveTo(tail.dx, tail.dy)
      ..lineTo(
        head.dx + perpendicular.dx * tailHalfWidth,
        head.dy + perpendicular.dy * tailHalfWidth,
      )
      ..lineTo(
        head.dx - perpendicular.dx * tailHalfWidth,
        head.dy - perpendicular.dy * tailHalfWidth,
      )
      ..close();
    canvas.drawPath(
      taperedTail,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: _tailColorsTipToHead(meteor.kind),
          stops: _tailStops(meteor.kind),
        ).createShader(Rect.fromPoints(tail, head)),
    );

    final innerEnd = Offset.lerp(head, tail, 0.4)!;
    canvas.drawLine(
      head,
      innerEnd,
      Paint()
        ..color = innerTail
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    if (meteor.kind == MeteorKind.fire) {
      _paintActiveFireSparks(canvas, meteor, tail, perpendicular);
    }

    var headRadius = MeteorCatchConstants.meteorHeadRadius * meteor.headScale;
    if (meteor.glowPulse) {
      final pulse = 0.75 + 0.25 * math.sin(engine.elapsedSeconds * 8);
      headRadius *= pulse;
    }

    canvas.drawCircle(
      head,
      headRadius * 1.9,
      Paint()
        ..color = colors.$2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(head, headRadius, Paint()..color = colors.$1);
  }

  List<Color> _tailColorsTipToHead(MeteorKind kind) {
    return switch (kind) {
      MeteorKind.standard => const [
        Color(0x00FF9A2C),
        standardTailCool,
        standardTailHot,
      ],
      MeteorKind.ice => const [Color(0x006AB4FF), iceTailCool, iceCore],
      MeteorKind.fire => const [
        Color(0x00FF2200),
        fireTailHot,
        fireTailWarm,
        fireCore,
      ],
      MeteorKind.golden => const [
        Color(0x00FFD54A),
        Color(0xFFFFD54A),
        goldenCore,
      ],
      MeteorKind.decoy => const [
        Color(0x008888B0),
        Color(0xFF8888B0),
        decoyCore,
      ],
    };
  }

  List<double> _tailStops(MeteorKind kind) {
    if (kind == MeteorKind.fire) {
      return const [0, 0.35, 0.68, 1];
    }
    return const [0, 0.55, 1];
  }

  void _paintActiveFireSparks(
    Canvas canvas,
    Meteor meteor,
    Offset tail,
    Offset perpendicular,
  ) {
    final sparkCount = 3 + (meteor.id & 1);
    for (var i = 0; i < sparkCount; i++) {
      final phase =
          ((engine.elapsedSeconds +
                  meteor.id * 0.071 +
                  i * (MeteorCatchConstants.sparkLife / sparkCount)) %
              MeteorCatchConstants.sparkLife) /
          MeteorCatchConstants.sparkLife;
      final along = 0.18 + 0.68 * ((i + 1) / (sparkCount + 1));
      final base = Offset.lerp(meteor.head, tail, along)!;
      final direction = i.isEven ? 1.0 : -1.0;
      final drift = perpendicular * direction * (3 + 10 * phase);
      final alpha = (1 - phase) * 0.85;
      canvas.drawCircle(
        base + drift,
        1.2 + (1 - phase) * 1.2,
        Paint()..color = fireTailWarm.withValues(alpha: alpha),
      );
    }
  }

  void _paintSwipeTrail(Canvas canvas, SwipeTrailSegment trail) {
    final life = MeteorCatchConstants.swipeTrailLife;
    final t = (trail.age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 0.35;
    if (alpha <= 0.01) return;
    final pts = trail.points;
    if (pts.length < 2) return;
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, alpha)
      ..strokeWidth = MeteorCatchConstants.barrierStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintSwipePreview(Canvas canvas) {
    final points = engine.swipePreview;
    if (points.length < 2) return;
    final paint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.22)
      ..strokeWidth = MeteorCatchConstants.barrierStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintCatchBurst(Canvas canvas, Size size, CatchBurst burst) {
    final opacity = burst.opacity;
    if (opacity <= 0) return;
    final colors = _colorsFor(burst.kind);
    final flare = burst.headFlare;
    final headR = MeteorCatchConstants.meteorHeadRadius * flare;

    final tailLen = burst.elongatedTailLength(size.width);
    final tailTip = burst.origin - burst.travelUnit * tailLen;
    canvas.drawLine(
      burst.origin,
      tailTip,
      Paint()
        ..color = colors.$1.withValues(alpha: opacity * 0.7)
        ..strokeWidth = headR * 0.8
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      burst.origin,
      headR * 1.6,
      Paint()
        ..color = colors.$2.withValues(alpha: opacity * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      burst.origin,
      headR,
      Paint()..color = colors.$1.withValues(alpha: opacity),
    );

    final len = 8.0 + 22.0 * (1.0 - opacity);
    final paint = Paint()
      ..color = MeteorCatchConstants.starburstColor.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final angle in burst.particleAngles) {
      final tip =
          burst.origin + Offset(math.cos(angle) * len, math.sin(angle) * len);
      canvas.drawLine(burst.origin, tip, paint);
    }
  }

  void _paintFireSpark(Canvas canvas, FireSpark spark) {
    final t = (spark.age / MeteorCatchConstants.sparkLife).clamp(0.0, 1.0);
    final alpha = 1.0 - t;
    canvas.drawCircle(
      spark.offset,
      2.5 * (1.0 - t * 0.5),
      Paint()..color = fireGlow.withValues(alpha: alpha * 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant MeteorCatchPainter oldDelegate) => true;
}

/// Play session for Meteor Catch (duration or endless).
class MeteorCatchPlayScreen extends ConsumerStatefulWidget {
  const MeteorCatchPlayScreen({
    super.key,
    required this.config,
    @visibleForTesting this.testEngine,
  });

  final MiniGameRoundConfig config;

  /// When set, the screen uses this engine instead of creating one (tests only).
  @visibleForTesting
  final MeteorCatchEngine? testEngine;

  @override
  ConsumerState<MeteorCatchPlayScreen> createState() =>
      _MeteorCatchPlayScreenState();
}

class _MeteorCatchPlayScreenState extends ConsumerState<MeteorCatchPlayScreen>
    with SingleTickerProviderStateMixin {
  static const Color _numberGlow = Color.fromRGBO(120, 180, 255, 0.2);

  late final Ticker _ticker;
  MeteorCatchEngine? _engine;
  Duration? _lastElapsed;
  bool _scoreRecorded = false;
  int _heardCatchEvents = 0;

  bool get _endless => widget.config.endless;

  double get _baseDifficulty {
    final catalog = ref.read(miniGameCatalogProvider);
    for (final game in catalog) {
      if (game.id == MeteorCatchConstants.gameId) {
        return game.baseDifficulty;
      }
    }
    return MeteorCatchConstants.baseDifficulty;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(soundServiceProvider).warmPlaybackCache();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureEngine(Size size) {
    if (_engine == null) {
      _engine =
          widget.testEngine ??
          MeteorCatchEngine(
            playSize: size,
            endless: _endless,
            baseDifficulty: _baseDifficulty,
          );
      _engine!.playSize = size;
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
    final dt = rawDt > 0.1 ? 0.1 : rawDt;
    final wasFinished = engine.isFinished;
    engine.update(dt);
    _pollCatchFeedback(engine);
    if (!wasFinished && engine.isFinished) {
      _onRoundComplete();
    }
    if (mounted) setState(() {});
  }

  Future<void> _onRoundComplete() async {
    if (_scoreRecorded) return;
    _scoreRecorded = true;
    _ticker.stop();
    final engine = _engine;
    if (engine == null) return;
    final repos = ref.read(appRepositoriesProvider);
    await repos.miniGames.recordScore(
      MeteorCatchConstants.gameId,
      engine.score,
      engine.currentDifficulty,
      endless: _endless,
    );
    final newlyReady = await MeteorCatchAchievements.recordRound(
      storage: repos.storage,
      achievements: ref.read(achievementServiceProvider),
      score: engine.score,
      bestStreak: engine.bestCatchStreak,
      endless: _endless,
    );
    notifyAchievementProgressUpdated(
      ref,
      newlyReady.whereType<Achievement>(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _endEndless() async {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    engine.endRound();
    await _onRoundComplete();
  }

  void _onPanStart(DragStartDetails details) {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    engine.beginSwipePreview(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    final to = details.localPosition;
    engine.extendSwipePreview(to);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    final engine = _engine;
    if (engine == null || engine.isFinished) {
      engine?.clearSwipePreview();
      return;
    }
    engine.commitTangiblePreview();
    _pollCatchFeedback(engine);
    setState(() {});
  }

  /// Plays meteor_click (and golden haptic) for each new catch event.
  ///
  /// Catches can resolve on finger-lift commit or on a later tick; polling a
  /// monotonic counter covers both without missing lift-time hits.
  void _pollCatchFeedback(MeteorCatchEngine engine) {
    while (_heardCatchEvents < engine.catchEventCount) {
      final kind = engine.catchEventKinds[_heardCatchEvents];
      _heardCatchEvents += 1;
      ref.read(soundServiceProvider).playMeteorClick();
      if (kind == MeteorKind.golden) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  String _timerLabel(MeteorCatchEngine engine) {
    if (_endless) {
      return '${engine.elapsedSeconds.floor()}s';
    }
    return '${engine.remainingSeconds.ceil()}s';
  }

  Widget _buildScoreColumn(MeteorCatchEngine engine, MiniGameThemedHud hud) {
    final streakColor =
        _meteorStreakTierColors[_meteorStreakTierIndex(engine.catchStreak)];
    return MiniGameHudChrome.scoreColumn(
      hud: hud,
      label: 'Score',
      value: '${engine.score}',
      valueScale: engine.scorePopScale,
      streakLabel: 'Streak',
      streakValue: '${engine.catchStreak}',
      streakColor: streakColor,
      numberGlow: _numberGlow,
      belowValue: engine.scorePops.isEmpty
          ? null
          : Text(
              engine.scorePops.last.delta >= 0
                  ? '+${engine.scorePops.last.delta}'
                  : '${engine.scorePops.last.delta}',
              style: hud.compact(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: engine.scorePops.last.delta >= 0
                    ? const Color(0xFFB8FFC8)
                    : const Color(0xFFFFB0A8),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final hud = MiniGameThemedHud(bundle);
        final scheme = bundle.themeData.colorScheme;
        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: MeteorCatchPainter.sky,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  _ensureEngine(size);
                  final engine = _engine!;
                  void dismiss() {
                    if (context.mounted) Navigator.of(context).pop();
                  }
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            painter: MeteorCatchPainter(engine: engine),
                            size: size,
                          ),
                        ),
                      ),
                      MiniGameHudChrome.topBar(
                        hud: hud,
                        onBack: () async {
                          if (!engine.isFinished) {
                            engine.endRound();
                            await _onRoundComplete();
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        center: _buildScoreColumn(engine, hud),
                        timerLabel: _timerLabel(engine),
                        onEnd: (_endless && !engine.isFinished)
                            ? _endEndless
                            : null,
                      ),
                      if (engine.isFinished)
                        MiniGameEndOverlay(
                          backgroundColor: scheme.scrim.withValues(alpha: 0.54),
                          onDismiss: dismiss,
                          child: MiniGameHudChrome.endScoreBody(
                            hud: hud,
                            title: 'Score',
                            value: '${engine.score}',
                            secondaryLabel: _endless ? 'Best streak' : null,
                            secondaryValue: _endless
                                ? '${engine.bestCatchStreak}'
                                : null,
                            secondaryColor: _endless
                                ? _meteorStreakTierColors[
                                    _meteorStreakTierIndex(
                                      engine.bestCatchStreak,
                                    )]
                                : null,
                            onDone: dismiss,
                            numberGlow: _numberGlow,
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
