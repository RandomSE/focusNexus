import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_achievements.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_constants.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_engine.dart';
import 'package:focusNexus/mini_games/rain_catcher/rain_catcher_painter.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/mini_game_catalog_provider.dart';
import 'package:focusNexus/widgets/mini_game_end_overlay.dart';
import 'package:focusNexus/widgets/mini_game_hud_chrome.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Play session for Rain Catcher (Duration 120s or Endless).
class RainCatcherPlayScreen extends ConsumerStatefulWidget {
  const RainCatcherPlayScreen({
    super.key,
    required this.config,
    @visibleForTesting this.testEngine,
  });

  final MiniGameRoundConfig config;

  @visibleForTesting
  final RainCatcherEngine? testEngine;

  @override
  ConsumerState<RainCatcherPlayScreen> createState() =>
      _RainCatcherPlayScreenState();
}

class _RainCatcherPlayScreenState extends ConsumerState<RainCatcherPlayScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  RainCatcherEngine? _engine;
  Duration? _lastElapsed;
  bool _scoreRecorded = false;

  bool get _endless => widget.config.endless;

  double get _baseDifficulty {
    final catalog = ref.read(miniGameCatalogProvider);
    for (final game in catalog) {
      if (game.id == RainCatcherConstants.gameId) {
        return game.baseDifficulty;
      }
    }
    return RainCatcherConstants.baseDifficulty;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _ensureEngine(Size size) {
    if (_engine != null) {
      if (_engine!.playSize != size) {
        _engine!.playSize = size;
      }
      return;
    }
    if (widget.testEngine != null) {
      _engine = widget.testEngine;
      return;
    }
    _engine = RainCatcherEngine(
      playSize: size,
      endless: _endless,
      baseDifficulty: _baseDifficulty,
    );
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
    _handleEngineEvents(engine);
    if (!wasFinished && engine.isFinished) {
      _onRoundComplete();
    }
    if (mounted) setState(() {});
  }

  void _handleEngineEvents(RainCatcherEngine engine) {
    final sound = ref.read(soundServiceProvider);
    if (engine.consumeJustCatch()) {
      sound.playRainCatchClick();
    }
    if (engine.consumeJustMiss()) {
      sound.playRainMiss();
    }
    if (engine.consumeJustFailed()) {
      sound.playGameFailed();
    }
  }

  Future<void> _onRoundComplete() async {
    if (_scoreRecorded) return;
    _scoreRecorded = true;
    _ticker.stop();
    final engine = _engine;
    if (engine == null) return;
    final repositories = ref.read(appRepositoriesProvider);
    await repositories.miniGames.recordScore(
      RainCatcherConstants.gameId,
      engine.score,
      _baseDifficulty,
      endless: _endless,
    );
    await RainCatcherAchievements.recordRound(
      storage: repositories.storage,
      achievements: ref.read(achievementServiceProvider),
      score: engine.score,
      bestStreak: engine.bestStreak,
      endless: _endless,
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

  void _onDragUpdate(DragUpdateDetails details) {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    engine.setPadX(details.localPosition.dx);
  }

  void _onTapDown(TapDownDetails details) {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    engine.setPadX(details.localPosition.dx);
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
            backgroundColor: RainCatcherPainter.skyBottom,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
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
                          onPanUpdate: _onDragUpdate,
                          onTapDown: _onTapDown,
                          child: CustomPaint(
                            painter: RainCatcherPainter(engine: engine),
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
                        center: MiniGameHudChrome.scoreColumn(
                          hud: hud,
                          label: 'Water',
                          value: '${engine.score}',
                          streakLabel: 'Streak',
                          streakValue: '${engine.streak}',
                        ),
                        timerLabel: _endless
                            ? '${engine.elapsedSeconds.floor()}s'
                            : '${engine.remainingSeconds}s',
                        onEnd: (_endless && !engine.isFinished)
                            ? _endEndless
                            : null,
                      ),
                      if (!engine.isFinished &&
                          engine.elapsedSeconds <
                              RainCatcherConstants.padHintVisibleSeconds)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 28,
                          child: Text(
                            RainCatcherConstants.padHint,
                            textAlign: TextAlign.center,
                            style: hud.compact(
                              fontSize: 13,
                              color: hud.foreground.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      if (engine.isFinished)
                        MiniGameEndOverlay(
                          backgroundColor: scheme.scrim.withValues(
                            alpha: 0.54,
                          ),
                          onDismiss: dismiss,
                          child: MiniGameHudChrome.endScoreBody(
                            hud: hud,
                            title: engine.failed ? 'Failed' : 'Time',
                            value: '${engine.score}',
                            secondaryLabel: 'Best streak',
                            secondaryValue: '${engine.bestStreak}',
                            onDone: dismiss,
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
