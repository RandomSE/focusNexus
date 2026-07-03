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
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/screens/zen_garden/bonsai_garden_screen.dart';
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
  bool _viewTreeMode = false;
  CherryBlossomTreeState? _prestigeOutgoing;
  CherryBlossomTreeState? _prestigeIncoming;

  late final AnimationController _pulseController;
  late final AnimationController _prestigeController;
  late final Animation<double> _pulseAnimation;

  ZenGardenSession get _session => ref.read(zenGardenSessionProvider.notifier);

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
          _prestigeBusy = false;
        });
      }
    });
  }

  @override
  void dispose() {
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
      await _prestigeController.forward(from: 0);
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
  }

  Future<CherryBlossomPrestigePath?> _askPrestigePath() async {
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
            onPressed: () =>
                Navigator.pop(context, CherryBlossomPrestigePath.peace),
            child: Text('Peace → Serenity', style: widget.textStyle),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, CherryBlossomPrestigePath.power),
            child: const Text('Power'),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BonsaiGardenScreen(
          primaryColor: widget.primaryColor,
          secondaryColor: widget.secondaryColor,
          textStyle: widget.textStyle,
        ),
      ),
    );
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

  Widget _buildControlPanel({
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
      elevation: 8,
      color: widget.secondaryColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tree.hudLabel,
                style: widget.textStyle.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Invested: ${tree.totalTreePointsInvested} pts · Wallet: $balance pts',
                style: widget.textStyle,
              ),
              if (tree.isFinale) ...[
                const SizedBox(height: 10),
                Text(
                  tree.unlockedFinalePaths.length >= 2
                      ? 'Change path (free)'
                      : 'Unlock alternate path (${CherryBlossomStageCatalog.pathSwitchCost} pts)',
                  style: widget.textStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prestigeBusy ||
                                tree.prestigePath ==
                                    CherryBlossomPrestigePath.peace ||
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
                          tree.isFinalePathUnlocked(
                            CherryBlossomPrestigePath.peace,
                          )
                              ? 'Peace'
                              : 'Peace (${CherryBlossomStageCatalog.pathSwitchCost})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prestigeBusy ||
                                tree.prestigePath ==
                                    CherryBlossomPrestigePath.power ||
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
                          tree.isFinalePathUnlocked(
                            CherryBlossomPrestigePath.power,
                          )
                              ? 'Power'
                              : 'Power (${CherryBlossomStageCatalog.pathSwitchCost})',
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                if (showPrestige)
                  FilledButton(
                    onPressed: _prestigeBusy || !canAffordPrestige
                        ? null
                        : () => _onPrestige(engine, garden),
                    child: Text(
                      prestigeCost == null
                          ? 'Prestige tree'
                          : 'Prestige tree ($prestigeCost pts)',
                    ),
                  )
                else ...[
                  FilledButton(
                    onPressed: canGrow && nextCost != null
                        ? () => _commitGardenState(engine.growOne(garden))
                        : null,
                    child: Text(
                      nextCost == null
                          ? 'Stage complete'
                          : 'Grow tree ($nextCost pts)',
                    ),
                  ),
                  if (canMax) ...[
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: canMax
                          ? () => _commitGardenState(
                                engine.growToAffordableMax(garden),
                              )
                          : null,
                      child: Text('Max tree ($maxCost pts)'),
                    ),
                  ],
                ],
              ],
            ],
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
    final balance =
        ref.watch(pointsBalanceProvider).valueOrNull ?? garden.pointsBalance;
    final nextCost = engine.nextGrowCost();
    final prestigeCost = engine.prestigeCost();
    final maxCost = engine.maxGrowCost(balance);
    final canGrow = engine.canGrow() && engine.canAffordGrow(balance);
    final canMax = !_prestigeBusy && engine.canGrow() && maxCost > 0;
    final showPrestige =
        !_prestigeBusy && engine.canPrestige() && !tree.isFinale;
    final canAffordPrestige = engine.canAffordPrestige(balance);
    final sceneColor = CherryBlossomStageCatalog.scaffoldColorFor(tree.stageIndex);

    return Scaffold(
      backgroundColor: sceneColor,
      appBar: _viewTreeMode
          ? null
          : AppBar(
              title: Text(
                'Cherry Blossom Tree',
                style: TextStyle(color: widget.primaryColor),
              ),
              backgroundColor: widget.secondaryColor,
              iconTheme: ThemeStyles.iconThemeFor(widget.primaryColor),
              actions: [
                TextButton.icon(
                  onPressed: _prestigeBusy
                      ? null
                      : () => setState(() => _viewTreeMode = true),
                  icon: Icon(Icons.visibility_outlined, color: widget.primaryColor),
                  label: Text(
                    'View tree',
                    style: TextStyle(color: widget.primaryColor),
                  ),
                ),
                TextButton.icon(
                  onPressed: _prestigeBusy ? null : _openBonsaiGarden,
                  icon: Icon(Icons.park_outlined, color: widget.primaryColor),
                  label: Text('Bonsai', style: TextStyle(color: widget.primaryColor)),
                ),
              ],
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final treeHeight =
              _viewTreeMode ? constraints.maxHeight : constraints.maxHeight * 0.78;
          return Column(
            children: [
              SizedBox(
                height: treeHeight,
                width: constraints.maxWidth,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
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
                    if (_viewTreeMode)
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 8,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'tree_exit_view',
                          onPressed: () => setState(() => _viewTreeMode = false),
                          child: const Icon(Icons.close),
                        ),
                      ),
                  ],
                ),
              ),
              if (!_viewTreeMode)
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildControlPanel(
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
            ],
          );
        },
      ),
    );
  }
}
