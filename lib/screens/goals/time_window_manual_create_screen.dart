import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/widgets/time_slot_goal_create_panel.dart';

/// Full-screen route wrapper for the inline time-slot create form.
class TimeWindowManualCreateScreen extends ConsumerWidget {
  const TimeWindowManualCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(themeBundleProvider);
    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        backgroundColor: bundle.secondaryColor,
        appBar: AppBar(
          title: Text('Create time-slot goal', style: bundle.textStyle),
          backgroundColor: bundle.secondaryColor,
          iconTheme: IconThemeData(color: bundle.primaryColor),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TimeSlotGoalCreatePanel(
              onGoalCreated: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}
