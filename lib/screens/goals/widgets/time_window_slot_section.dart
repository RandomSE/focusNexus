import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

/// Bordered group for one slot boundary (ends / starts) with nested date & time rows.
class TimeWindowSlotSection extends StatelessWidget {
  const TimeWindowSlotSection({
    super.key,
    required this.bundle,
    required this.title,
    required this.icon,
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
  });

  final ThemeBundle bundle;
  final String title;
  final IconData icon;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final textStyle = bundle.textStyle;
    final borderColor = bundle.primaryColor.withValues(alpha: 0.55);
    final headerBg = bundle.accentColor.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: bundle.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: textStyle.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _PickerRow(
              bundle: bundle,
              rowTitle: 'Date',
              value: dateLabel,
              trailingIcon: Icons.calendar_today,
              onTap: onPickDate,
            ),
            Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
            _PickerRow(
              bundle: bundle,
              rowTitle: 'Time',
              value: timeLabel,
              trailingIcon: Icons.access_time,
              onTap: onPickTime,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.bundle,
    required this.rowTitle,
    required this.value,
    required this.trailingIcon,
    required this.onTap,
  });

  final ThemeBundle bundle;
  final String rowTitle;
  final String value;
  final IconData trailingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = bundle.textStyle;
    final captionStyle = textStyle.copyWith(
      fontSize: (textStyle.fontSize ?? 14) - 2,
      fontWeight: FontWeight.w600,
      color: bundle.primaryColor.withValues(alpha: 0.75),
    );
    return Material(
      color: bundle.secondaryColor.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rowTitle, style: captionStyle),
                    const SizedBox(height: 2),
                    Text(value, style: textStyle),
                  ],
                ),
              ),
              Icon(trailingIcon, color: bundle.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
