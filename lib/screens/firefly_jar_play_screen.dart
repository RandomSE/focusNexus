import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/achievements/notify_achievement_progress.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_achievements.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_engine.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_painter.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/mini_game_catalog_provider.dart';
import 'package:focusNexus/widgets/mini_game_end_overlay.dart';
import 'package:focusNexus/widgets/mini_game_hud_chrome.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Play session for Firefly Jar (duration or endless).
class FireflyJarPlayScreen extends ConsumerStatefulWidget {
  const FireflyJarPlayScreen({super.key, required this.config});

  final MiniGameRoundConfig config;

  @override
  ConsumerState<FireflyJarPlayScreen> createState() =>
      _FireflyJarPlayScreenState();
}

class _FireflyJarPlayScreenState extends ConsumerState<FireflyJarPlayScreen>
    with SingleTickerProviderStateMixin {
  static const Color _numberGlow = Color.fromRGBO(255, 220, 100, 0.15);

  late final Ticker _ticker;
  FireflyJarEngine? _engine;
  Duration? _lastElapsed;
  bool _scoreRecorded = false;

  bool get _endless => widget.config.endless;

  double get _baseDifficulty {
    final catalog = ref.read(miniGameCatalogProvider);
    for (final game in catalog) {
      if (game.id == FireflyJarConstants.gameId) {
        return game.baseDifficulty;
      }
    }
    return FireflyJarConstants.baseDifficulty;
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
      _engine = FireflyJarEngine(
        playSize: size,
        endless: _endless,
        baseDifficulty: _baseDifficulty,
      );
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
      FireflyJarConstants.gameId,
      engine.catchCount,
      engine.currentDifficulty,
      endless: _endless,
    );
    final newlyReady = await FireflyJarAchievements.recordRound(
      storage: repos.storage,
      achievements: ref.read(achievementServiceProvider),
      catchCount: engine.catchCount,
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

  void _onTapDown(TapDownDetails details) {
    final engine = _engine;
    if (engine == null || engine.isFinished) return;
    if (engine.tryCatch(details.localPosition)) {
      ref.read(soundServiceProvider).playFireflyClick();
      setState(() {});
    }
  }

  String _timerLabel(FireflyJarEngine engine) {
    if (_endless) {
      return '${engine.elapsedSeconds.floor()}s';
    }
    return '${engine.remainingSeconds.ceil()}s';
  }

  Widget _buildScoreColumn(FireflyJarEngine engine, MiniGameThemedHud hud) {
    return MiniGameHudChrome.scoreColumn(
      hud: hud,
      label: 'Fireflies',
      value: '${engine.catchCount}',
      numberGlow: _numberGlow,
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
            backgroundColor: FireflyJarPainter.sky,
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
                          onTapDown: _onTapDown,
                          child: CustomPaint(
                            painter: FireflyJarPainter(engine: engine),
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
                            title: 'Fireflies',
                            value: '${engine.catchCount}',
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
