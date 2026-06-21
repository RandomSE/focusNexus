import 'package:flutter/material.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/decor_item.dart';
import 'package:focusNexus/progressive_visuals/garden_item.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:intl/intl.dart';

import 'zen_garden_stage_labels.dart';

class ZenGardenBottomActions extends StatelessWidget {
  const ZenGardenBottomActions({
    required this.textStyle,
    required this.primary,
    required this.secondary,
    required this.garden,
    required this.plant,
    required this.decor,
    required this.growCost,
    required this.growCostDecor,
    required this.isFirstPlantFree,
    required this.onGrow,
    required this.onGrowDecor,
    required this.onSkip,
    required this.onSkipDecor,
    required this.onRemoveMutation,
    required this.onRemoveDecorMutation,
    required this.onRestart,
    required this.onRestartDecor,
    required this.onRemovePlant,
    required this.onRemoveDecor,
  });

  final TextStyle textStyle;
  final Color primary;
  final Color secondary;
  final GardenState garden;
  final GardenItem? plant;
  final DecorItem? decor;
  final int? growCost;
  final int? growCostDecor;
  final bool isFirstPlantFree;
  final VoidCallback? onGrow;
  final VoidCallback? onGrowDecor;
  final VoidCallback? onSkip;
  final VoidCallback? onSkipDecor;
  final VoidCallback? onRemoveMutation;
  final VoidCallback? onRemoveDecorMutation;
  final VoidCallback? onRestart;
  final VoidCallback? onRestartDecor;
  final VoidCallback? onRemovePlant;
  final VoidCallback? onRemoveDecor;

  static String _growPlantLabel(int? cost, bool firstPlantFree) {
    if (cost == null) return 'Grow next';
    if (firstPlantFree && cost == 0) return 'Grow next (free, first plant)';
    if (cost == 0) return 'Grow next (no points)';
    return 'Grow next ($cost pts)';
  }

  static String _growPlantSemanticsLabel(int? cost, bool firstPlantFree) {
    if (cost == null) return 'Grow to next stage';
    if (firstPlantFree && cost == 0) {
      return 'Grow to next stage, free for your first plant only';
    }
    if (cost == 0) return 'Grow to next stage, no points cost';
    return 'Grow to next stage, costs $cost points';
  }

  @override
  Widget build(BuildContext context) {
    if (plant == null && decor == null) {
      return const SizedBox.shrink();
    }

    if (decor != null) {
      final d = decor!;
      final label = decorEntryByKind(d.kind)?.label ?? d.kind;
      final now = DateTime.now();
      final waiting = d.nextAdvanceAllowedAt != null && now.isBefore(d.nextAdvanceAllowedAt!);
      final remaining = waiting ? d.nextAdvanceAllowedAt!.difference(now) : Duration.zero;
      final skipCost = d.pendingSkipWaitCost;
      final waitTotal = zenWaitAfterAdvancingFrom(d.stageIndex - 1);
      final mutLabel = d.mutation == null
          ? ''
          : ', rare inverted-color variant active. Remove variant button available.';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label:
                'Selected decoration $label, stage ${d.stageIndex + 1} of five.$mutLabel Balance ${garden.pointsBalance} points.',
            child: Text(
              '$label · Stage ${d.stageIndex + 1} of 5'
              '${d.mutation != null ? ' · variant on' : ''}',
              style: textStyle,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Move this decoration to inventory',
            child: OutlinedButton(
              onPressed: onRemoveDecor,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: const Text('To inventory'),
            ),
          ),
          if (waiting && skipCost != null) ...[
            const SizedBox(height: 8),
            ZenGardenCountdownRow(
              remaining: remaining,
              waitTotal: waitTotal,
              skipCost: skipCost,
              balance: garden.pointsBalance,
              textStyle: textStyle,
              primary: primary,
              onSkip: onSkipDecor,
            ),
          ],
          const SizedBox(height: 12),
          if (!waiting && d.stageIndex < DecorItem.maxStageIndex)
            Semantics(
              button: true,
              enabled:
                  growCostDecor != null && garden.pointsBalance >= (growCostDecor ?? 0),
              label: growCostDecor == 0
                  ? 'Grow decoration to next stage, no points cost'
                  : 'Grow decoration to next stage, costs $growCostDecor points',
              child: FilledButton(
                onPressed: (growCostDecor != null &&
                        garden.pointsBalance >= growCostDecor!)
                    ? onGrowDecor
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: primary,
                  foregroundColor:
                      ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1C1B1A),
                ),
                child: Text(
                  growCostDecor == 0
                      ? 'Grow next (no points)'
                      : 'Grow next ($growCostDecor pts)',
                ),
              ),
            ),
          if (d.stageIndex >= DecorItem.maxStageIndex) ...[
            Text(
              'This decoration is fully grown.',
              style: textStyle.copyWith(fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Restart growth from first stage for a new rare variant chance',
              child: OutlinedButton(
                onPressed: onRestartDecor,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Restart growth'),
              ),
            ),
          ],
          if (d.mutation != null) ...[
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Remove special color variant',
              child: TextButton(
                onPressed: onRemoveDecorMutation,
                child: const Text('Remove special variant'),
              ),
            ),
          ],
        ],
      );
    }

    final i = plant!;
    final stageLabel = zenGardenStageLabel(i.stageIndex);
    final now = DateTime.now();
    final waiting = i.nextAdvanceAllowedAt != null && now.isBefore(i.nextAdvanceAllowedAt!);
    final remaining = waiting ? i.nextAdvanceAllowedAt!.difference(now) : Duration.zero;
    final skipCost = i.pendingSkipWaitCost;
    final waitTotal = zenWaitAfterAdvancingFrom(i.stageIndex - 1);
    final mutLabel = i.mutation == null
        ? ''
        : ', rare inverted-color variant active. Remove variant button available.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          label:
              'Selected plant, stage $stageLabel of five.$mutLabel Balance ${garden.pointsBalance} points.',
          child: Text(
            'Stage: $stageLabel (${i.stageIndex + 1} of 5)'
            '${i.mutation != null ? ' · variant on' : ''}',
            style: textStyle,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Move this plant to inventory',
          child: OutlinedButton(
            onPressed: onRemovePlant,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: const Text('To inventory'),
          ),
        ),
        if (waiting && skipCost != null) ...[
          const SizedBox(height: 8),
          ZenGardenCountdownRow(
            remaining: remaining,
            waitTotal: waitTotal,
            skipCost: skipCost,
            balance: garden.pointsBalance,
            textStyle: textStyle,
            primary: primary,
            onSkip: onSkip,
          ),
        ],
        const SizedBox(height: 12),
        if (!waiting && i.stageIndex < GardenItem.maxStageIndex)
          Semantics(
            button: true,
            enabled: growCost != null && garden.pointsBalance >= (growCost ?? 0),
            label: _growPlantSemanticsLabel(growCost, isFirstPlantFree),
            child: FilledButton(
              onPressed: (growCost != null && garden.pointsBalance >= growCost!)
                  ? onGrow
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: primary,
                foregroundColor:
                    ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1C1B1A),
              ),
              child: Text(_growPlantLabel(growCost, isFirstPlantFree)),
            ),
          ),
        if (i.stageIndex >= GardenItem.maxStageIndex) ...[
          Text(
            'This plant is fully grown.',
            style: textStyle.copyWith(fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Restart growth from seed for a new rare variant chance',
            child: OutlinedButton(
              onPressed: onRestart,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Restart growth from seed'),
            ),
          ),
        ],
        if (i.mutation != null) ...[
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Remove special color variant, keeps mature plant',
            child: TextButton(
              onPressed: onRemoveMutation,
              child: const Text('Remove special variant'),
            ),
          ),
        ],
      ],
    );
  }
}

class ZenGardenCountdownRow extends StatelessWidget {
  const ZenGardenCountdownRow({
    required this.remaining,
    required this.skipCost,
    required this.balance,
    required this.textStyle,
    required this.primary,
    required this.onSkip,
    required this.waitTotal,
  });

  final Duration remaining;
  final Duration waitTotal;
  final int skipCost;
  final int balance;
  final TextStyle textStyle;
  final Color primary;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('mm:ss').format(DateTime(0).add(remaining));
    final canSkip = balance >= skipCost;
    final denom = waitTotal.inMilliseconds <= 0 ? 1 : waitTotal.inMilliseconds;
    final progress = 1.0 - (remaining.inMilliseconds / denom).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                  color: primary.withValues(alpha: 0.55),
                  backgroundColor: primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(fmt, style: textStyle.copyWith(fontFeatures: const [])),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label:
              'Pause before next growth. About $fmt remaining. Or skip for $skipCost points.',
          child: Text(
            'Pause before next growth · $fmt left',
            style: textStyle.copyWith(fontWeight: FontWeight.normal),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          enabled: canSkip,
          label: 'Skip wait for $skipCost points',
          child: FilledButton.tonal(
            onPressed: canSkip ? onSkip : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text('Skip wait ($skipCost pts)'),
          ),
        ),
      ],
    );
  }
}
