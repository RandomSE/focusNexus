import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/debug/debug_consistency_seed.dart';
import 'package:focusNexus/debug/debug_points_credit.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/services/daily_open_reward_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Debug-only dashboard control: credit a typed amount once per streak day.
class DebugPointsCreditPanel extends ConsumerStatefulWidget {
  const DebugPointsCreditPanel({super.key, this.now, this.random});

  /// Injected clock for tests; defaults to [DateTime.now].
  final DateTime? now;

  /// Injected RNG for tests; defaults to [Random].
  final Random? random;

  @override
  ConsumerState<DebugPointsCreditPanel> createState() =>
      _DebugPointsCreditPanelState();
}

class _DebugPointsCreditPanelState
    extends ConsumerState<DebugPointsCreditPanel> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _loaded = false;
  bool _available = false;
  bool _busy = false;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAvailability());
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    final last = await ref
        .read(appRepositoriesProvider)
        .storage
        .read(key: StorageKeys.debugPointsCreditDate);
    if (!mounted) return;
    setState(() {
      _available = DebugPointsCredit.isAvailableOnDay(
        lastCreditDay: last,
        now: _now,
      );
      _loaded = true;
    });
  }

  Future<void> _credit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    final amount = DebugPointsCredit.parseAmount(_amountController.text);
    if (amount == null) return;

    setState(() => _busy = true);
    try {
      final repos = ref.read(appRepositoriesProvider);
      await repos.points.add(amount);
      await DebugConsistencySeed.replaceCurrentMonth(
        goals: repos.goals,
        now: _now,
        random: widget.random ?? Random(),
      );
      await repos.storage.write(
        key: StorageKeys.debugPointsCreditDate,
        value: DailyOpenRewardService.formatLocalDay(_now),
      );
      if (!mounted) return;
      await ref.read(pointsBalanceProvider.notifier).reload();
      if (!mounted) return;
      await ref.read(goalsProvider.notifier).load(now: _now);
      if (!mounted) return;
      final bundle = ref.read(themeBundleProvider);
      CommonUtils.showSnackBar(
        context,
        'Debug credit: +$amount points and seeded this month',
        bundle.textStyle,
        2500,
        12,
        backgroundColor: bundle.secondaryColor,
        labelColor: bundle.primaryColor,
      );
      setState(() => _available = false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_available) return const SizedBox.shrink();
    final bundle = ref.watch(themeBundleProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          CommonUtils.buildTextFormField(
            _amountController,
            'Debug points to credit',
            bundle.textStyle,
            bundle.secondaryColor,
            true,
            DebugPointsCredit.validateAmount,
            keyboardType: TextInputType.number,
          ),
          CommonUtils.buildCenteredButton(
            context,
            'Credit debug points',
            () {
              if (_busy) return;
              unawaited(_credit());
            },
            bundle.textStyle,
            bundle.secondaryColor,
            borderColor: bundle.primaryColor,
            semanticsHint:
                'Adds the typed points and seeds this month once today (debug only)',
          ),
        ],
      ),
    );
  }
}
