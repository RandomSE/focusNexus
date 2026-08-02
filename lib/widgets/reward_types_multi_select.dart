import 'package:flutter/material.dart';
import 'package:focusNexus/rewards/reward_type_selection.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Multi-select for the three reward types (caller enforces min 1 on save).
class RewardTypesMultiSelect extends StatelessWidget {
  const RewardTypesMultiSelect({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.textStyle,
    required this.activeColor,
    this.title = 'Reward types',
    this.subtitle = 'Select at least one.',
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final TextStyle textStyle;
  final Color activeColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final selectedSet = selected.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonUtils.buildText(title, textStyle),
        const SizedBox(height: 4),
        CommonUtils.buildText(
          subtitle,
          textStyle.copyWith(
            fontWeight: FontWeight.normal,
            fontSize: (textStyle.fontSize ?? 14) * 0.85,
          ),
        ),
        const SizedBox(height: 8),
        for (final value in RewardTypeSelection.orderedStorageValues)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(value, style: textStyle),
            value: selectedSet.contains(value),
            activeColor: activeColor,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (checked) {
              final next = Set<String>.from(selectedSet);
              if (checked == true) {
                next.add(value);
              } else {
                next.remove(value);
              }
              onChanged(RewardTypeSelection.orderKnown(next));
            },
          ),
      ],
    );
  }
}
