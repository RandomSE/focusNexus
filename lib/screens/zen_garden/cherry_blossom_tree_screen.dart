import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_path.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_stage_catalog.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_state.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_viewport.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_prestige_transition.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/progressive_visuals/garden_zen_spend.dart';
import 'package:focusNexus/progressive_visuals/progressive_visuals_balance_label.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/screens/zen_garden/bonsai_garden_screen.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/music_unlock.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/theme_styles.dart';

/// Cherry blossom tree growth screen (image-based stages).
class CherryBlossomTreeScreen extends ConsumerStatefulWidget {
  const CherryBlossomTreeScreen({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;

  @override
  ConsumerState<CherryBlossomTreeScreen> createState() =>
      _CherryBlossomTreeScreenState();
}

class _CherryBlossomTreeScreenState extends ConsumerState<CherryBlossomTreeScreen>
    with TickerProviderStateMixin {
  bool _prestigeBusy = false;
  bool _chromeVisible = true;
  bool _menuOpen = false;
  CherryBlossomTreeState? _prestigeOutgoing;
  CherryBlossomTreeState? _prestigeIncoming;
  SoundService? _sounds;
  SoundChannel? _activeMusic;

  late final AnimationController _pulseController;
  late final AnimationController _prestigeController;
  late final Animation<double> _pulseAnimation;

  ZenGardenSession get _session => ref.read(zenGardenSessionProvider.notifier);

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
  }

  void _hideChrome() {
    setState(() {
      _chromeVisible = false;
      _menuOpen = false;
    });
  }

  void _showChrome() {
    setState(() => _chromeVisible = true);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _prestigeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutCubic,
    );
    _prestigeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _prestigeOutgoing = null;
          _prestigeIncoming = null;
          // Controls already re-enabled when the next stage was committed.
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncCherryMusic());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sounds ??= ref.read(soundServiceProvider);
  }

  Future<void> _syncCherryMusic() async {
    final repo = ref.read(appRepositoriesProvider).ambientSoundscapes;
    final suppress = await repo.shouldSuppressFeatureBgm(
      AmbientAppSection.progressiveVisuals,
    );
    if (suppress) {
      _activeMusic = null;
      await ref.read(soundServiceProvider).stopMusic();
      return;
    }
    final tree = ref.read(zenGardenSessionProvider).garden.cherryBlossomTree;
    final channel = cherryBlossomMusicForTree(tree);
    final sounds = ref.read(soundServiceProvider);
    final audible = await sounds.isMusicChannelAudible(channel);
    // Sticky only while the intended output is already playing.
    if (_activeMusic == channel) {
      if (audible && sounds.activeFeatureMusic == channel) return;
      if (!audible && sounds.isAmbientRequested && !sounds.hasActiveFeatureMusic) {
        return;
      }
    }
    final coordinator = ref.read(ambientPlaybackCoordinatorProvider);
    final started = await startFeatureMusicOrAmbientFallback(
      sounds: sounds,
      repo: repo,
      coordinator: coordinator,
      featureChannel: channel,
    );
    // Only sticky on success so a disabled-channel miss can retry / fall back.
    _activeMusic = started ? channel : null;
  }

  @override
  void activate() {
    super.activate();
    // Re-evaluate after returning from Sound effects / settings overlays.
    unawaited(_syncCherryMusic());
  }

  @override
  void dispose() {
    final sounds = _sounds;
    final channel = _activeMusic;
    if (sounds != null && channel != null) {
      unawaited(sounds.stopMusicIfChannel(channel));
    }
    _pulseController.dispose();
    _prestigeController.dispose();
    super.dispose();
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _playGrowthPulse() {
    unawaited(_pulseController.forward(from: 0));
  }

  Future<void> _commitGardenState(
    CherryBlossomOpResult result, {
    bool animateGrow = true,
  }) async {
    if (!result.isSuccess) {
      _showError(result.error ?? 'Action failed');
      return;
    }

    if (result.prestiged &&
        result.fromStageIndex != null &&
        result.toStageIndex != null) {
      final garden = ref.read(zenGardenSessionProvider).garden;
      final outgoing = garden.cherryBlossomTree.copyWith(
        stageIndex: result.fromStageIndex!,
        growthStepsInStage: CherryBlossomStageCatalog.levelsPerStage - 1,
      ).normalized();
      final incoming = result.state!.cherryBlossomTree.normalized();
      setState(() {
        _prestigeBusy = true;
        _prestigeOutgoing = outgoing;
        _prestigeIncoming = incoming;
      });
      _session.setGarden(result.state!);
      ref.read(pointsBalanceProvider.notifier).adoptBalance(
            result.state!.pointsBalance,
          );
      unawaited(_session.persist(snapshot: result.state));
      // Re-enable Max tree / grow as soon as the next stage is committed,
      // not after the prestige transition finishes (~1s+ asset settle feel).
      if (mounted) {
        setState(() => _prestigeBusy = false);
      }
      await _prestigeController.forward(from: 0);
      unawaited(_syncCherryMusic());
      return;
    }

    _session.setGarden(result.state!);
    ref.read(pointsBalanceProvider.notifier).adoptBalance(
          result.state!.pointsBalance,
        );
    if (animateGrow) {
      _playGrowthPulse();
    }
    unawaited(_session.persist(snapshot: result.state));
    unawaited(_syncCherryMusic());
  }

  Future<CherryBlossomPrestigePath?> _askPrestigePath() async {
    final actionStyle = ThemeStyles.outlinedActionButtonStyle(
      primaryColor: widget.primaryColor,
      secondaryColor: widget.secondaryColor,
      borderColor: widget.primaryColor,
      verticalPadding: 10,
    );
    final labelStyle = ThemeStyles.buttonLabelStyle(
      widget.textStyle,
      widget.primaryColor,
    );
    return showDialog<CherryBlossomPrestigePath>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose your path', style: widget.textStyle),
        content: Text(
          'Your tree has reached its peak. Will you embrace Power or Peace?',
          style: widget.textStyle,
        ),
        actions: [
          TextButton(
            style: actionStyle,
            onPressed: () =>
                Navigator.pop(context, CherryBlossomPrestigePath.peace),
            child: Text('Peace', style: labelStyle),
          ),
          TextButton(
            style: actionStyle,
            onPressed: () =>
                Navigator.pop(context, CherryBlossomPrestigePath.power),
            child: Text('Power', style: labelStyle),
          ),
        ],
      ),
    );
  }

  Future<void> _onPrestige(
    CherryBlossomTreeEngine engine,
    GardenState garden,
  ) async {
    CherryBlossomPrestigePath? path;
    if (engine.tree.stageIndex == CherryBlossomStageCatalog.maxPlayableStage) {
      path = await _askPrestigePath();
      if (path == null || !mounted) return;
    }
    setState(() => _prestigeBusy = true);
    await _commitGardenState(
      engine.prestige(garden, path: path),
      animateGrow: false,
    );
  }

  Future<void> _onSwitchPath(
    CherryBlossomTreeEngine engine,
    GardenState garden,
    CherryBlossomPrestigePath path,
  ) async {
    await _commitGardenState(
      engine.switchFinalePath(garden, path),
      animateGrow: false,
    );
  }

  Future<void> _openBonsaiGarden() async {
    await ref.read(soundServiceProvider).stopMusic();
    _activeMusic = null;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BonsaiGardenScreen(
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          textStyle: widget.textStyle,
        ),
      ),
    );
    if (!mounted) return;
    await _syncCherryMusic();
  }

  Widget _buildTreeArea(
    CherryBlossomTreeState tree,
    Size viewportSize,
  ) {
    if (_prestigeOutgoing != null && _prestigeIncoming != null) {
      return CherryBlossomPrestigeTransition(
        animation: _prestigeController,
        outgoing: _prestigeOutgoing!,
        incoming: _prestigeIncoming!,
        size: viewportSize,
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return CherryBlossomTreeViewport(
          tree: tree,
          size: viewportSize,
          growPulseT: _pulseController.isAnimating ? _pulseAnimation.value : 1.0,
          animateEffects: !_prestigeBusy,
        );
      },
    );
  }

  Widget _buildControlContent({
    required CherryBlossomTreeState tree,
    required CherryBlossomTreeEngine engine,
    required GardenState garden,
    required int balance,
    required int? nextCost,
    required int? prestigeCost,
    required int maxCost,
    required bool canGrow,
    required bool canMax,
    required bool showPrestige,
    required bool canAffordPrestige,
  }) {
    final actionStyle = ThemeStyles.outlinedActionButtonStyle(
      primaryColor: widget.primaryColor,
      secondaryColor: widget.secondaryColor,
      borderColor: widget.primaryColor,
    );
    final labelStyle = ThemeStyles.buttonLabelStyle(
      widget.textStyle,
      widget.primaryColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tree.isFinale) ...[
          if (tree.unlockedFinalePaths.length < 2) ...[
            Text(
              'Change path (${CherryBlossomStageCatalog.pathSwitchCost} pts)',
              style: widget.textStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: actionStyle,
                  onPressed: _prestigeBusy ||
                          tree.prestigePath == CherryBlossomPrestigePath.peace ||
                          !engine.canAffordPathSwitch(
                            balance,
                            CherryBlossomPrestigePath.peace,
                          )
                      ? null
                      : () => _onSwitchPath(
                            engine,
                            garden,
                            CherryBlossomPrestigePath.peace,
                          ),
                  child: Text(
                    tree.isFinalePathUnlocked(CherryBlossomPrestigePath.peace)
                        ? 'Peace'
                        : 'Peace (${CherryBlossomStageCatalog.pathSwitchCost})',
                    style: labelStyle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: actionStyle,
                  onPressed: _prestigeBusy ||
                          tree.prestigePath == CherryBlossomPrestigePath.power ||
                          !engine.canAffordPathSwitch(
                            balance,
                            CherryBlossomPrestigePath.power,
                          )
                      ? null
                      : () => _onSwitchPath(
                            engine,
                            garden,
                            CherryBlossomPrestigePath.power,
                          ),
                  child: Text(
                    tree.isFinalePathUnlocked(CherryBlossomPrestigePath.power)
                        ? 'Power'
                        : 'Power (${CherryBlossomStageCatalog.pathSwitchCost})',
                    style: labelStyle,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            tree.hudLabel,
            style: widget.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (showPrestige)
            ElevatedButton(
              style: actionStyle,
              onPressed: _prestigeBusy || !canAffordPrestige
                  ? null
                  : () => _onPrestige(engine, garden),
              child: Text(
                prestigeCost == null
                    ? 'Prestige tree'
                    : 'Prestige tree ($prestigeCost pts)',
                style: labelStyle,
              ),
            )
          else ...[
            ElevatedButton(
              style: actionStyle,
              onPressed: canGrow && nextCost != null
                  ? () => _commitGardenState(engine.growOne(garden))
                  : null,
              child: Text(
                nextCost == null
                    ? 'Stage complete'
                    : 'Grow tree ($nextCost pts)',
                style: labelStyle,
              ),
            ),
            if (canMax) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                style: actionStyle,
                onPressed: canMax
                    ? () => _commitGardenState(
                          engine.growToAffordableMax(garden),
                        )
                    : null,
                child: Text(
                  'Max tree ($maxCost pts)',
                  style: labelStyle,
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildMenuOverlay({
    required CherryBlossomTreeState tree,
    required CherryBlossomTreeEngine engine,
    required GardenState garden,
    required int balance,
    required int? nextCost,
    required int? prestigeCost,
    required int maxCost,
    required bool canGrow,
    required bool canMax,
    required bool showPrestige,
    required bool canAffordPrestige,
  }) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: widget.secondaryColor.withValues(alpha: 0.97),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
              child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: _buildControlContent(
            tree: tree,
            engine: engine,
            garden: garden,
            balance: balance,
            nextCost: nextCost,
            prestigeCost: prestigeCost,
            maxCost: maxCost,
            canGrow: canGrow,
            canMax: canMax,
            showPrestige: showPrestige,
            canAffordPrestige: canAffordPrestige,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final garden = ref.watch(zenGardenSessionProvider).garden;
    final tree = garden.cherryBlossomTree.normalized();
    final engine = CherryBlossomTreeEngine(tree);
    final spendable = zenSpendableBalance(garden);
    final nextCost = engine.nextGrowCost();
    final prestigeCost = engine.prestigeCost();
    final maxCost = engine.maxGrowCost(spendable);
    final canGrow = engine.canGrow() && engine.canAffordGrow(spendable);
    final canMax = !_prestigeBusy && engine.canGrow() && maxCost > 0;
    final showPrestige =
        !_prestigeBusy && engine.canPrestige() && !tree.isFinale;
    final canAffordPrestige = engine.canAffordPrestige(spendable);
    final sceneColor = CherryBlossomStageCatalog.scaffoldColorFor(tree.stageIndex);

    return Scaffold(
      backgroundColor: sceneColor,
      appBar: _chromeVisible
          ? AppBar(
              title: Text(
                'Cherry Blossom Tree',
                style: widget.textStyle.copyWith(color: widget.primaryColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: widget.secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(widget.primaryColor),
              actions: [
                IconButton(
                  tooltip: 'View tree',
                  onPressed: _prestigeBusy ? null : _hideChrome,
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: widget.primaryColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Bonsai',
                  onPressed: _prestigeBusy ? null : _openBonsaiGarden,
                  icon: Icon(
                    Icons.park_outlined,
                    color: widget.primaryColor,
                  ),
                ),
              ],
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 2.5,
                    boundaryMargin: EdgeInsets.zero,
                    clipBehavior: Clip.hardEdge,
                    child: LayoutBuilder(
                      builder: (context, inner) {
                        final viewport =
                            Size(inner.maxWidth, inner.maxHeight);
                        return _buildTreeArea(tree, viewport);
                      },
                    ),
                  ),
                ),
              ),
              if (_chromeVisible)
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_menuOpen) ...[
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  progressiveVisualsBalanceLabel(garden),
                                  style: widget.textStyle.copyWith(
                                    color: widget.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        children: [
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: _prestigeBusy ? null : _toggleMenu,
                            icon: Icon(_menuOpen ? Icons.close : Icons.menu),
                            label: Text(_menuOpen ? 'Close' : 'Menu'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ],
                      ),
                      if (_menuOpen) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: _hideChrome,
                            icon: const Icon(Icons.visibility_off_outlined),
                            label: const Text('Hide menu'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMenuOverlay(
                          tree: tree,
                          engine: engine,
                          garden: garden,
                          balance: spendable,
                          nextCost: nextCost,
                          prestigeCost: prestigeCost,
                          maxCost: maxCost,
                          canGrow: canGrow,
                          canMax: canMax,
                          showPrestige: showPrestige,
                          canAffordPrestige: canAffordPrestige,
                        ),
                      ],
                    ],
                  ),
                ),
              if (!_chromeVisible)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'tree_exit_view',
                    onPressed: _showChrome,
                    child: const Icon(Icons.close),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
