import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_achievements.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_constants.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_engine.dart';
import 'package:focusNexus/mini_games/word_bloom/word_bloom_painter.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/widgets/mini_game_end_overlay.dart';
import 'package:focusNexus/widgets/mini_game_hud_chrome.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Word Bloom play session (Duration 90s or Endless).
class WordBloomPlayScreen extends ConsumerStatefulWidget {
  const WordBloomPlayScreen({
    super.key,
    required this.config,
    @visibleForTesting this.testEngine,
  });

  final MiniGameRoundConfig config;

  @visibleForTesting
  final WordBloomEngine? testEngine;

  @override
  ConsumerState<WordBloomPlayScreen> createState() =>
      _WordBloomPlayScreenState();
}

class _WordBloomPlayScreenState extends ConsumerState<WordBloomPlayScreen>
    with SingleTickerProviderStateMixin {
  static const Color _numberGlow = Color.fromRGBO(255, 183, 197, 0.25);

  late final Ticker _ticker;
  WordBloomEngine? _engine;
  bool _ownsEngine = false;
  Duration? _lastElapsed;
  bool _scoreRecorded = false;
  int _heardCollectEvents = 0;
  int _heardWordCollectedEvents = 0;

  /// Rasterized glyphs; survives painter rebuilds and bypasses Impeller text atlas.
  final Map<String, ui.Image> _glyphImageCache = <String, ui.Image>{};
  String? _glyphCacheKey;

  bool get _endless => widget.config.endless;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clearGlyphCache();
    if (_ownsEngine) {
      _engine?.dispose();
    }
    super.dispose();
  }

  void _clearGlyphCache() {
    for (final image in _glyphImageCache.values) {
      image.dispose();
    }
    _glyphImageCache.clear();
    _glyphCacheKey = null;
  }

  void _ensureEngine(Size size) {
    if (_engine != null) {
      if (_engine!.playSize != size) {
        _engine!.playSize = size;
        _engine!.reseatCurrentWordSlots();
      }
      return;
    }
    if (widget.testEngine != null) {
      _engine = widget.testEngine;
      _ownsEngine = false;
    } else {
      _engine = WordBloomEngine(
        playSize: size,
        endless: _endless,
        baseDifficulty: WordBloomConstants.baseDifficulty,
      );
      _ownsEngine = true;
    }
  }

  void _syncLetterLayoutFromBundle(TextStyle textStyle) {
    final engine = _engine;
    if (engine == null) return;
    final layout = WordBloomConstants.letterLayoutSizeForSettingsFont(
      textStyle.fontSize,
    );
    final cacheKey =
        '${textStyle.fontFamily}|${layout.toStringAsFixed(1)}|'
        '${textStyle.fontWeight}';
    if (_glyphCacheKey != cacheKey) {
      _clearGlyphCache();
      _glyphCacheKey = cacheKey;
    }
    engine.setLetterLayoutSize(layout);
  }

  TextStyle _glyphStyle(TextStyle bundleStyle, WordBloomEngine engine) {
    return TextStyle(
      inherit: false,
      fontFamily: bundleStyle.fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: engine.letterLayoutSize,
      height: 1.0,
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
    _pollCollectFeedback(engine);
    if (!wasFinished && engine.isFinished) {
      _onRoundComplete();
    }
    if (engine.isFinished && _ticker.isActive) {
      _ticker.stop();
    }
    // No setState: CustomPaint repaints via engine Listenable; HUD via hudRevision.
  }

  void _pollCollectFeedback(WordBloomEngine engine) {
    while (_heardCollectEvents < engine.collectEventCount) {
      _heardCollectEvents += 1;
      ref.read(soundServiceProvider).playWordBloomClick();
    }
    while (_heardWordCollectedEvents < engine.wordCollectedEventCount) {
      _heardWordCollectedEvents += 1;
      ref.read(soundServiceProvider).playWordCollected();
    }
  }

  Future<void> _onRoundComplete() async {
    if (_scoreRecorded) return;
    _scoreRecorded = true;
    final engine = _engine;
    if (engine == null) return;
    final repositories = ref.read(appRepositoriesProvider);
    await repositories.miniGames.recordScore(
      WordBloomConstants.gameId,
      engine.score,
      WordBloomConstants.baseDifficulty,
      endless: _endless,
    );
    await WordBloomAchievements.recordRound(
      storage: repositories.storage,
      achievements: ref.read(achievementServiceProvider),
      score: engine.score,
      bestStreak: engine.bestOrderStreak,
      endless: _endless,
    );
    if (!mounted) return;
    // End overlay listens to hudRevision (isFinished).
    engine.hudRevision.value++;
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
    engine.tapAt(details.localPosition);
    _pollCollectFeedback(engine);
  }

  String _timerLabel(WordBloomEngine engine) {
    if (_endless) {
      return '${engine.elapsedSeconds.floor()}s';
    }
    return '${engine.remainingSeconds}s';
  }

  Widget _buildHudChrome({
    required WordBloomEngine engine,
    required MiniGameThemedHud hud,
    required ColorScheme scheme,
    required VoidCallback dismiss,
  }) {
    return Stack(
      children: [
        MiniGameHudChrome.topBar(
          hud: hud,
          onBack: () async {
            if (!engine.isFinished) {
              engine.endRound();
              await _onRoundComplete();
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          center: MiniGameHudChrome.scoreColumn(
            hud: hud,
            label: 'Score',
            value: '${engine.score}',
            streakLabel: 'Streak',
            streakValue: '${engine.orderStreak}',
            numberGlow: _numberGlow,
          ),
          timerLabel: _timerLabel(engine),
          onEnd: (_endless && !engine.isFinished) ? _endEndless : null,
        ),
        if (engine.isFinished)
          MiniGameEndOverlay(
            backgroundColor: scheme.scrim.withValues(alpha: 0.54),
            onDismiss: dismiss,
            child: MiniGameHudChrome.endScoreBody(
              hud: hud,
              title: 'Score',
              value: '${engine.score}',
              secondaryLabel: 'Streak',
              secondaryValue: '${engine.bestOrderStreak}',
              onDone: dismiss,
              numberGlow: _numberGlow,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final hud = MiniGameThemedHud(bundle);
        final scheme = bundle.themeData.colorScheme;
        // Keep play chrome on compact styles; do not inherit Accessibility
        // fontSize 24 OpenDyslexic TextTheme into Material widgets each frame.
        final playTheme = bundle.themeData.copyWith(
          textTheme: TextTheme(
            bodyMedium: hud.compact(fontSize: 14),
            labelLarge: hud.compact(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        );
        return Theme(
          data: playTheme,
          child: Scaffold(
            backgroundColor: WordBloomConstants.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  _ensureEngine(size);
                  _syncLetterLayoutFromBundle(bundle.textStyle);
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
                            painter: WordBloomPainter(
                              engine: engine,
                              glyphStyle: _glyphStyle(
                                bundle.textStyle,
                                engine,
                              ),
                              glyphImageCache: _glyphImageCache,
                            ),
                            size: size,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: ValueListenableBuilder<int>(
                          valueListenable: engine.hudRevision,
                          builder: (context, _, _) {
                            return _buildHudChrome(
                              engine: engine,
                              hud: hud,
                              scheme: scheme,
                              dismiss: dismiss,
                            );
                          },
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
