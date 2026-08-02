import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/mini_games/mini_game_definition.dart';
import 'package:focusNexus/mini_games/mini_game_lobby_scores.dart';
import 'package:focusNexus/mini_games/mini_game_progress.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/mini_game_catalog_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

class MiniGameLobbyScreen extends ConsumerStatefulWidget {
  const MiniGameLobbyScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<MiniGameLobbyScreen> createState() =>
      _MiniGameLobbyScreenState();
}

class _MiniGameLobbyScreenState extends ConsumerState<MiniGameLobbyScreen> {
  bool _endless = false;
  bool _busy = false;
  MiniGameProgress? _progress;
  bool? _unlocked;

  MiniGameDefinition? get _definition {
    final catalog = ref.read(miniGameCatalogProvider);
    for (final game in catalog) {
      if (game.id == widget.gameId) return game;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadProgress());
  }

  Future<void> _reloadProgress() async {
    final definition = _definition;
    if (definition == null) return;
    final repos = ref.read(appRepositoriesProvider);
    if (definition.isFreeUnlock) {
      await repos.miniGames.ensureWelcomeUnlock(definition);
    }
    final progress = await repos.miniGames.progressFor(definition.id);
    final unlocked = await repos.miniGames.isUnlocked(definition);
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _unlocked = unlocked;
    });
  }

  String _highScoreLabel(MiniGameProgress? progress) {
    return MiniGameLobbyScores.format(progress);
  }

  Future<void> _onUnlock(MiniGameDefinition game, TextStyle textStyle) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final points = ref.read(appRepositoriesProvider).points;
      final spent = await points.trySpend(game.unlockCost);
      if (!mounted) return;
      if (spent == null) {
        CommonUtils.showSnackBar(
          context,
          'Not enough points! Need ${game.unlockCost}.',
          textStyle,
          2000,
          12,
        );
        return;
      }
      await ref.read(appRepositoriesProvider).miniGames.unlock(game.id);
      ref.read(pointsBalanceProvider.notifier).adoptBalance(spent);
      await _reloadProgress();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onStart(MiniGameDefinition game, TextStyle textStyle) async {
    if (_busy || !game.implemented) return;
    final unlocked = _unlocked ?? game.isFreeUnlock;
    if (!unlocked) return;
    setState(() => _busy = true);
    try {
      final repos = ref.read(appRepositoriesProvider);
      final usedFree = await repos.miniGames.tryConsumeFreeEntry(
        game.id,
        endless: _endless,
      );
      if (!usedFree) {
        final cost = game.startCost(endless: _endless);
        final spent = await repos.points.trySpend(cost);
        if (!mounted) return;
        if (spent == null) {
          CommonUtils.showSnackBar(
            context,
            'Not enough points! Need $cost.',
            textStyle,
            2000,
            12,
          );
          return;
        }
        ref.read(pointsBalanceProvider.notifier).adoptBalance(spent);
      } else if (mounted) {
        await _reloadProgress();
      }
      if (!mounted) return;
      await repos.miniGames.markLastPlayed(game.id);
      await ref.pushRoute(
        context,
        MiniGamePlayRoute(gameId: game.id, endless: _endless),
      );
      await _reloadProgress();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _startLabel(MiniGameDefinition game) {
    if (!game.implemented) return 'Coming soon';
    final unlocked = _unlocked ?? game.isFreeUnlock;
    if (!unlocked) return 'Start';
    final freeLeft = _progress?.freeEntriesFor(endless: _endless) ?? 0;
    if (freeLeft > 0) return 'Start (free)';
    return 'Start (${game.startCost(endless: _endless)})';
  }

  @override
  Widget build(BuildContext context) {
    final game = _definition;
    final balanceAsync = ref.watch(pointsBalanceProvider);

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final textStyle = bundle.textStyle;
        if (game == null) {
          return Theme(
            data: bundle.themeData,
            child: Scaffold(
              backgroundColor: bundle.secondaryColor,
              appBar: AppBar(
                title: Text(
                  'Lobby',
                  style: TextStyle(color: bundle.primaryColor),
                ),
                backgroundColor: bundle.secondaryColor,
                iconTheme: ThemeStyles.iconThemeFor(bundle.primaryColor),
              ),
              body: Center(
                child: CommonUtils.buildText('Game not found', textStyle),
              ),
            ),
          );
        }

        final unlocked = _unlocked ?? game.isFreeUnlock;
        final canStart = unlocked && game.implemented && !_busy;
        final showUnlock = !unlocked && !game.isFreeUnlock;
        final balance = balanceAsync.valueOrNull;
        final freeDuration = _progress?.freeDurationEntries ?? 0;
        final freeEndless = _progress?.freeEndlessEntries ?? 0;

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: bundle.secondaryColor,
            appBar: AppBar(
              title: Text(
                game.title,
                style: TextStyle(color: bundle.primaryColor),
              ),
              backgroundColor: bundle.secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(bundle.primaryColor),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              children: [
                CommonUtils.buildText(game.description, textStyle),
                const SizedBox(height: 16),
                CommonUtils.buildText(
                  unlocked
                      ? 'Unlocked'
                      : 'Locked - unlock cost: ${game.unlockCost}',
                  textStyle,
                ),
                const SizedBox(height: 8),
                CommonUtils.buildText(
                  'Play cost: ${game.playCost}'
                  '${_endless ? ' + endless ${game.endlessCost}' : ''}',
                  textStyle,
                ),
                if (freeDuration > 0 || freeEndless > 0) ...[
                  const SizedBox(height: 8),
                  CommonUtils.buildText(
                    'Free entries - Duration: $freeDuration, '
                    'Endless: $freeEndless',
                    textStyle,
                  ),
                ],
                const SizedBox(height: 8),
                CommonUtils.buildText(
                  _highScoreLabel(_progress),
                  textStyle,
                ),
                const SizedBox(height: 8),
                CommonUtils.buildText(
                  'Points: ${balance ?? '...'}',
                  textStyle,
                ),
                const SizedBox(height: 16),
                CommonUtils.buildText('Mode', textStyle),
                RadioGroup<bool>(
                  groupValue: _endless,
                  onChanged: _busy
                      ? (_) {}
                      : (value) {
                          if (value == null) return;
                          setState(() => _endless = value);
                        },
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: Text('Duration', style: textStyle),
                        value: false,
                        enabled: !_busy,
                      ),
                      RadioListTile<bool>(
                        title: Text(
                          'Endless (+${game.endlessCost} pts this round)',
                          style: textStyle,
                        ),
                        value: true,
                        enabled: !_busy,
                      ),
                    ],
                  ),
                ),
                if (!game.implemented) ...[
                  const SizedBox(height: 8),
                  CommonUtils.buildText('Coming soon', textStyle),
                ],
                const SizedBox(height: 16),
                if (showUnlock)
                  CommonUtils.buildTextButton(
                    _busy ? null : () => _onUnlock(game, textStyle),
                    'Unlock (${game.unlockCost})',
                    textStyle,
                  ),
                const SizedBox(height: 8),
                CommonUtils.buildTextButton(
                  canStart ? () => _onStart(game, textStyle) : null,
                  _startLabel(game),
                  textStyle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
