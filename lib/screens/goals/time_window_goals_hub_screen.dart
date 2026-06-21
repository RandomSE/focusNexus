import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/widgets/active_repeat_series_section.dart';
import 'package:focusNexus/screens/goals/widgets/time_slot_goal_create_panel.dart';
import 'package:focusNexus/utils/common_utils.dart';

class TimeWindowGoalsHubScreen extends ConsumerStatefulWidget {
  const TimeWindowGoalsHubScreen({super.key});

  @override
  ConsumerState<TimeWindowGoalsHubScreen> createState() =>
      _TimeWindowGoalsHubScreenState();
}

class _TimeWindowGoalsHubScreenState
    extends ConsumerState<TimeWindowGoalsHubScreen> {
  int _repeatRefreshGeneration = 0;

  void _bumpRepeatRefresh() => setState(() => _repeatRefreshGeneration++);

  Future<void> _openBulkCreate() async {
    final created = await ref.pushRoute(
      context,
      const TimeWindowBulkCreateRoute(),
    );
    if (created == true) {
      _bumpRepeatRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(themeBundleProvider);
    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        backgroundColor: bundle.secondaryColor,
        appBar: AppBar(
          title: Text('Time-slot goals', style: bundle.textStyle),
          backgroundColor: bundle.secondaryColor,
          iconTheme: IconThemeData(color: bundle.primaryColor),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Do tasks during a set time slot. Progress is only available while the slot is open.',
              style: bundle.textStyle,
            ),
            const SizedBox(height: 20),
            Text(
              'Create a time-slot goal',
              style: bundle.textStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TimeSlotGoalCreatePanel(onGoalCreated: _bumpRepeatRefresh),
            const SizedBox(height: 28),
            CommonUtils.buildElevatedButton(
              'Create multiple goals',
              bundle.primaryColor,
              bundle.secondaryColor,
              bundle.textStyle,
              8,
              8,
              _openBulkCreate,
              borderColor: bundle.accentColor,
            ),
            const SizedBox(height: 24),
            ActiveRepeatSeriesSection(
              refreshGeneration: _repeatRefreshGeneration,
              onSeriesChanged: _bumpRepeatRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
