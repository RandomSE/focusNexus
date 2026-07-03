import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:focusNexus/progressive_visuals/cherry_blossom_bonsai_ref.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_bonsai_tile.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_tree_engine.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';

/// Custom 5×5 bonsai garden — trees fill slots; letterbox gets a calm backdrop.
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

  @override
  ConsumerState<BonsaiGardenScreen> createState() => _BonsaiGardenScreenState();
}

class _BonsaiGardenScreenState extends ConsumerState<BonsaiGardenScreen> {
  bool _viewMode = false;

  ZenGardenSession get _session => ref.read(zenGardenSessionProvider.notifier);

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
              final ref = CherryBlossomBonsaiRef.parse(key)!;
              final count = ref.countFor(tree);
              return ListTile(
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: CherryBlossomBonsaiTile(
                    bonsaiKey: key,
                    countLabel: '×$count',
                  ),
                ),
                title: Text(ref.stageLabel, style: widget.textStyle),
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
          if (!_viewMode)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _viewMode = true),
                  icon: Icon(Icons.visibility_outlined, color: widget.primaryColor),
                  label: Text(
                    'View garden',
                    style: TextStyle(color: widget.primaryColor),
                  ),
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 4.0;
              const dim = CherryBlossomBonsaiRef.gridDimension;
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final cellFromWidth = (w - spacing * (dim - 1)) / dim;
              final cellFromHeight = (h - spacing * (dim - 1)) / dim;
              final cell = math.min(cellFromWidth, cellFromHeight);
              final gridW = cell * dim + spacing * (dim - 1);

              return Center(
                child: SizedBox(
                  width: gridW,
                  height: gridW,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: dim,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1,
                    ),
                    itemCount: CherryBlossomBonsaiRef.gardenSlotCount,
                    itemBuilder: (context, index) {
                      final key = slots[index];
                      final ref = CherryBlossomBonsaiRef.parse(key);
                      return CherryBlossomBonsaiTile(
                        bonsaiKey: key,
                        empty: key == null,
                        countLabel: ref == null ? null : '×${ref.countFor(tree)}',
                        onTap: _viewMode ? null : () => _pickBonsai(index),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (_viewMode)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
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
