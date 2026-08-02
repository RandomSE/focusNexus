import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_achievements.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_engine.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_painter.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/mini_game_catalog_provider.dart';
import 'package:focusNexus/widgets/mini_game_end_overlay.dart';
import 'package:focusNexus/widgets/mini_game_hud_chrome.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Play session for Stone Balance (duration or endless).
class StoneBalancePlayScreen extends ConsumerStatefulWidget {
  const StoneBalancePlayScreen({super.key, required this.config});

  final MiniGameRoundConfig config;

  @override
  ConsumerState<StoneBalancePlayScreen> createState() =>
      _StoneBalancePlayScreenState();
}

class _StoneBalancePlayScreenState extends ConsumerState<StoneBalancePlayScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  StoneBalanceEngine? _engine;
  Duration? _lastElapsed;
  bool _scoreRecorded = false;
  bool _dragging = false;

  bool get _endless => widget.config.endless;

  double get _baseDifficulty {
    final catalog = ref.read(miniGameCatalogProvider);
    for (final game in catalog) {
      if (game.id == StoneBalanceConstants.gameId) {
        return game.baseDifficulty;
      }
    }
    return StoneBalanceConstants.baseDifficulty;
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
    if (_engine == null) {
      _engine = StoneBalanceEngine(
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
    _handleEngineEvents(engine);
    if (!wasFinished && engine.isFinished) {
      _onRoundComplete();
    }
    if (mounted) setState(() {});
  }

  void _handleEngineEvents(StoneBalanceEngine engine) {
    final sound = ref.read(soundServiceProvider);
    if (engine.consumeJustLanded()) {
      sound.playRockFalling();
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
    await ref.read(appRepositoriesProvider).miniGames.recordScore(
          StoneBalanceConstants.gameId,
          engine.score,
          engine.currentDifficulty,
          endless: _endless,
        );
    final repos = ref.read(appRepositoriesProvider);
    await StoneBalanceAchievements.recordRound(
      storage: repos.storage,
      achievements: ref.read(achievementServiceProvider),
      height: engine.score,
      endless: _endless,
      finishedByTimeout: engine.finishedByTimeout,
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
    if (engine == null || !engine.canAim) return;
    _dragging = true;
    engine.setAimScreenX(details.localPosition.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    final engine = _engine;
    if (engine == null) return;
    if (_dragging && engine.canAim) {
      engine.releaseDrop();
    }
    _dragging = false;
  }

  void _onDragCancel() {
    _dragging = false;
  }

  void _onTapDown(TapDownDetails details) {
    final engine = _engine;
    if (engine == null || !engine.canAim) return;
    engine.setAimScreenX(details.localPosition.dx);
  }

  void _onTapUp(TapUpDetails details) {
    final engine = _engine;
    if (engine == null || !engine.canAim) return;
    engine.setAimScreenX(details.localPosition.dx);
    engine.releaseDrop();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final hud = MiniGameThemedHud(bundle);
        final scheme = bundle.themeData.colorScheme;
        final titleStyle = hud.compact(fontSize: 16, fontWeight: FontWeight.w600);
        final hintStyle = hud.compact(
          fontSize: 13,
          color: hud.foreground.withValues(alpha: 0.72),
        );

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: StoneBalancePainter.skyBottom,
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
                          onPanUpdate: engine.canAim ? _onDragUpdate : null,
                          onPanEnd: engine.canAim ? _onDragEnd : null,
                          onPanCancel: engine.canAim ? _onDragCancel : null,
                          onTapDown: engine.canAim ? _onTapDown : null,
                          onTapUp: engine.canAim ? _onTapUp : null,
                          child: CustomPaint(
                            painter: StoneBalancePainter(engine: engine),
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
                        center: Text(
                          'Height ${engine.score}',
                          textAlign: TextAlign.center,
                          style: titleStyle,
                        ),
                        timerLabel: _endless
                            ? '${engine.elapsedSeconds.floor()}s'
                            : '${engine.remainingSeconds}s',
                        onEnd: (_endless && !engine.isFinished)
                            ? _endEndless
                            : null,
                      ),
                      if (engine.showAimHint)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 28,
                          child: Text(
                            StoneBalanceConstants.aimHint,
                            textAlign: TextAlign.center,
                            style: hintStyle,
                          ),
                        ),
                      if (engine.isFinished)
                        MiniGameEndOverlay(
                          backgroundColor: scheme.scrim.withValues(alpha: 0.54),
                          onDismiss: dismiss,
                          child: MiniGameHudChrome.endScoreBody(
                            hud: hud,
                            title: engine.toppled ? 'Toppled' : 'Time',
                            value: '${engine.score}',
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
