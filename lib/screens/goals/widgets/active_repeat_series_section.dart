import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/goal_repeat_series.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/widgets/edit_repeat_series_dialog.dart';
import 'package:focusNexus/utils/common_utils.dart';

class ActiveRepeatSeriesSection extends ConsumerStatefulWidget {
  const ActiveRepeatSeriesSection({
    super.key,
    required this.refreshGeneration,
    this.onSeriesChanged,
  });

  final int refreshGeneration;
  final VoidCallback? onSeriesChanged;

  @override
  ConsumerState<ActiveRepeatSeriesSection> createState() =>
      _ActiveRepeatSeriesSectionState();
}

class _ActiveRepeatSeriesSectionState
    extends ConsumerState<ActiveRepeatSeriesSection> {
  late Future<List<GoalRepeatSeries>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ActiveRepeatSeriesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshGeneration != widget.refreshGeneration) {
      _reload();
    }
  }

  void _reload() {
    _future = ref.read(goalsProvider.notifier).readActiveRepeatSeries();
  }

  Future<void> _editSeries(GoalRepeatSeries item) async {
    final saved = await showEditRepeatSeriesDialog(
      context: context,
      ref: ref,
      series: item,
    );
    if (!mounted || !saved) return;
    setState(_reload);
    widget.onSeriesChanged?.call();
  }

  Future<void> _stopSeries(int seriesId) async {
    await ref.read(goalsProvider.notifier).deactivateRepeatSeries(seriesId);
    if (!mounted) return;
    setState(_reload);
    widget.onSeriesChanged?.call();
  }

  Future<void> _clearAllRepeating() async {
    final bundle = ref.read(themeBundleProvider);
    final confirmed = await CommonUtils.showInteractableAlertDialog(
      context,
      'Clear all repeating goals?',
      'Stops every active repeating goal. Current active goals stay on your list.',
      bundle.textStyle,
      bundle.secondaryColor,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: bundle.textStyle),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Clear all', style: bundle.textStyle),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    await ref.read(goalsProvider.notifier).deactivateAllRepeatingSchedules();
    if (!mounted) return;
    setState(_reload);
    widget.onSeriesChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(themeBundleProvider);

    ref.listen(
      goalsProvider.select(
        (s) => s.activeGoals
            .where((g) => g.repeatSeriesId != 0)
            .map((g) => '${g.goalId}:${g.repeatSeriesId}')
            .join('|'),
      ),
      (previous, next) {
        if (previous != next && mounted) {
          setState(_reload);
        }
      },
    );

    return FutureBuilder<List<GoalRepeatSeries>>(
      future: _future,
      builder: (context, snapshot) {
        final series = snapshot.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active repeating goals',
                    style: bundle.textStyle,
                  ),
                ),
                if (series.isNotEmpty)
                  TextButton(
                    onPressed: _clearAllRepeating,
                    child: Text(
                      'Clear all',
                      style: bundle.textStyle.copyWith(
                        color: bundle.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting &&
                series.isEmpty)
              const LinearProgressIndicator(minHeight: 2),
            if (series.isEmpty &&
                snapshot.connectionState != ConnectionState.waiting)
              Text(
                'No active repeating goals.',
                style: bundle.textStyle,
              )
            else
              ...series.map((item) {
                return Card(
                  color: bundle.secondaryColor,
                  child: ListTile(
                    title: Text(item.title, style: bundle.textStyle),
                    subtitle: Text(
                      '${summarizeRepeatRule(item.repeatRule)}\n'
                      '${repeatSeriesSlotLabel(item)}',
                      style: bundle.textStyle.copyWith(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _editSeries(item),
                          child: Text(
                            'Edit',
                            style: bundle.textStyle.copyWith(
                              color: bundle.primaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _stopSeries(item.seriesId),
                          child: Text(
                            'Stop',
                            style: bundle.textStyle.copyWith(
                              color: bundle.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
