import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/progressive_visuals/cherry_blossom_bonsai_ref.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_bonsai_tile.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';

/// Custom 5x5 bonsai garden spanning the full body under an AppBar.
class BonsaiGardenScreen extends ConsumerStatefulWidget {
  const BonsaiGardenScreen({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;

  /// Uniform gap between pots (logical px).
  static const double potSpacing = 6.0;

  @override
  ConsumerState<BonsaiGardenScreen> createState() => _BonsaiGardenScreenState();
}

class _BonsaiGardenScreenState extends ConsumerState<BonsaiGardenScreen> {
  bool _viewMode = false;
  SoundService? _sounds;
  SoundChannel? _startedFeatureChannel;

  ZenGardenSession get _session => ref.read(zenGardenSessionProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startBonsaiMusicIfAllowed());
    });
  }

  Future<void> _startBonsaiMusicIfAllowed() async {
    final repo = ref.read(appRepositoriesProvider).ambientSoundscapes;
    final suppress = await repo.shouldSuppressFeatureBgm(
      AmbientAppSection.progressiveVisuals,
    );
    if (suppress) {
      _startedFeatureChannel = null;
      await ref.read(soundServiceProvider).stopMusic();
      return;
    }
    final sounds = ref.read(soundServiceProvider);
    final coordinator = ref.read(ambientPlaybackCoordinatorProvider);
    final started = await startFeatureMusicOrAmbientFallback(
      sounds: sounds,
      repo: repo,
      coordinator: coordinator,
      featureChannel: SoundChannel.bonsaiMusic,
    );
    _startedFeatureChannel = started ? SoundChannel.bonsaiMusic : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sounds ??= ref.read(soundServiceProvider);
  }

  @override
  void dispose() {
    final sounds = _sounds;
    final channel = _startedFeatureChannel;
    if (sounds != null && channel != null) {
      unawaited(sounds.stopMusicIfChannel(channel));
    }
    super.dispose();
  }

  Future<void> _applySlot(int slotIndex, String? key) async {
    final garden = ref.read(zenGardenSessionProvider).garden;
    final engine = CherryBlossomTreeEngine(garden.cherryBlossomTree);
    final result = engine.setGardenSlot(
      garden: garden,
      slotIndex: slotIndex,
      bonsaiKey: key,
    );
    if (!result.isSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not update garden')),
      );
      return;
    }
    _session.setGarden(result.state!);
    ref.read(pointsBalanceProvider.notifier).adoptBalance(
          result.state!.pointsBalance,
        );
    unawaited(_session.persist(snapshot: result.state));
  }

  Future<void> _pickBonsai(int slotIndex) async {
    final tree = ref.read(zenGardenSessionProvider).garden.cherryBlossomTree;
    final keys = tree.unlockedBonsaiKeys;
    if (keys.isEmpty) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final key = keys[index];
              final bonsai = CherryBlossomBonsaiRef.parse(key)!;
              final count = bonsai.countFor(tree);
              return ListTile(
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: CherryBlossomBonsaiTile(
                    bonsaiKey: key,
                    animateEffects: false,
                  ),
                ),
                title: Text(bonsai.stageLabel, style: widget.textStyle),
                subtitle: Text('$count collected', style: widget.textStyle),
                onTap: () => Navigator.pop(context, key),
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      await _applySlot(slotIndex, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(zenGardenSessionProvider).garden.cherryBlossomTree;
    final slots = tree.gardenSlots;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Bonsai garden', style: widget.textStyle),
        actions: [
          if (!_viewMode)
            TextButton.icon(
              onPressed: () => setState(() => _viewMode = true),
              icon: Icon(Icons.visibility_outlined, color: widget.primaryColor),
              label: Text(
                'View garden',
                style: TextStyle(color: widget.primaryColor),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD8E8E0),
                  Color(0xFFE8F0E8),
                  Color(0xFFD0DCE8),
                  Color(0xFFC8D8E0),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.all(BonsaiGardenScreen.potSpacing),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const dim = CherryBlossomBonsaiRef.gridDimension;
                const spacing = BonsaiGardenScreen.potSpacing;
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final cellW = (w - spacing * (dim - 1)) / dim;
                final cellH = (h - spacing * (dim - 1)) / dim;
                final aspect = cellW / cellH;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: dim,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspect,
                  ),
                  itemCount: CherryBlossomBonsaiRef.gardenSlotCount,
                  itemBuilder: (context, index) {
                    final key = slots[index];
                    return CherryBlossomBonsaiTile(
                      bonsaiKey: key,
                      empty: key == null,
                      onTap: _viewMode ? null : () => _pickBonsai(index),
                    );
                  },
                );
              },
            ),
          ),
          if (_viewMode)
            Positioned(
              top: 8,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'bonsai_exit_view',
                onPressed: () => setState(() => _viewMode = false),
                child: const Icon(Icons.close),
              ),
            ),
        ],
      ),
    );
  }
}
