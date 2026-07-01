import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Hub entry point for time-slot goals above the main goals create form.
class GoalsTimeSlotEntrySection extends StatelessWidget {
  const GoalsTimeSlotEntrySection({
    super.key,
    required this.bundle,
    required this.onOpenHub,
  });

  final ThemeBundle bundle;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommonUtils.buildElevatedButton(
          'Time-slot goals',
          bundle.primaryColor,
          bundle.secondaryColor,
          bundle.textStyle,
          8,
          8,
          onOpenHub,
          borderColor: bundle.accentColor,
        ),
        Text(
          'Scheduled time slots - goals that need to be done within a specific '
          'time slot (can also auto-repeat)',
          style: bundle.textStyle.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
