import 'package:flutter/material.dart';
import 'package:focusNexus/consistency/consistency_aggregator.dart';
import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/widgets/consistency_month_grid.dart';
import 'package:intl/intl.dart';

/// Month label, prev/next arrows, and [ConsistencyMonthGrid].
class ConsistencyCalendarPanel extends StatelessWidget {
  const ConsistencyCalendarPanel({
    super.key,
    required this.year,
    required this.month,
    required this.completedGoals,
    required this.today,
    required this.isDark,
    required this.textStyle,
    required this.primaryColor,
    required this.onMonthChanged,
    required this.onDaySelected,
    this.palette = ConsistencyPaletteId.coolTealDepth,
    this.density = ConsistencyCalendarDensity.comfortable,
    this.selectedDay,
    this.titleSuffix,
    this.onOpenExplorer,
  });

  final int year;
  final int month;
  final List<GoalSet> completedGoals;
  final DateTime today;
  final bool isDark;
  final TextStyle textStyle;
  final Color primaryColor;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final ConsistencyPaletteId palette;
  final ConsistencyCalendarDensity density;
  final DateTime? selectedDay;
  final String? titleSuffix;
  final VoidCallback? onOpenExplorer;

  TextStyle get _headingStyle {
    final base = textStyle.fontSize ?? 14;
    final capped = density == ConsistencyCalendarDensity.compact
        ? base.clamp(11.0, 14.0)
        : base.clamp(12.0, 18.0);
    return textStyle.copyWith(
      fontSize: capped,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
  }

  TextStyle get _dayNumberStyle {
    return textStyle.copyWith(
      fontSize: density == ConsistencyCalendarDensity.compact ? 8 : 11,
      height: textStyle.height ?? 1.2,
      fontWeight: FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = ConsistencyAggregator.countsForMonth(
      completedGoals,
      year,
      month,
    );
    final earliest = ConsistencyAggregator.earliestCompletionMonth(
      completedGoals,
    );
    final viewed = ConsistencyDate.monthStart(year, month);
    final currentMonth = ConsistencyDate.monthStart(today.year, today.month);
    final canGoPrev = earliest != null && viewed.isAfter(earliest);
    final canGoNext = viewed.isBefore(currentMonth);
    final monthLabel = DateFormat('MMMM yyyy').format(viewed);
    final heading = titleSuffix == null
        ? monthLabel
        : '$monthLabel ($titleSuffix)';
    final disabledColor = primaryColor.withValues(alpha: 0.28);
    final iconSize = density == ConsistencyCalendarDensity.compact ? 18.0 : 22.0;
    final openOnAreaTap = onOpenExplorer != null &&
        density == ConsistencyCalendarDensity.compact;

    final header = Row(
      children: [
        SizedBox(
          width: density == ConsistencyCalendarDensity.compact ? 32 : 40,
          height: density == ConsistencyCalendarDensity.compact ? 28 : 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: canGoPrev ? 'Previous month' : 'No previous month',
            onPressed: canGoPrev
                ? () => onMonthChanged(
                      ConsistencyDate.previousMonthStart(year, month),
                    )
                : null,
            icon: Icon(
              Icons.chevron_left,
              size: iconSize,
              color: canGoPrev ? primaryColor : disabledColor,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onOpenExplorer,
            child: Text(
              heading,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _headingStyle,
            ),
          ),
        ),
        SizedBox(
          width: density == ConsistencyCalendarDensity.compact ? 32 : 40,
          height: density == ConsistencyCalendarDensity.compact ? 28 : 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: canGoNext ? 'Next month' : 'No next month',
            onPressed: canGoNext
                ? () => onMonthChanged(
                      ConsistencyDate.nextMonthStart(year, month),
                    )
                : null,
            icon: Icon(
              Icons.chevron_right,
              size: iconSize,
              color: canGoNext ? primaryColor : disabledColor,
            ),
          ),
        ),
      ],
    );

    final grid = ConsistencyMonthGrid(
      year: year,
      month: month,
      counts: counts,
      today: today,
      isDark: isDark,
      palette: palette,
      density: density,
      dayNumberStyle: _dayNumberStyle,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (openOnAreaTap)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenExplorer,
            child: grid,
          )
        else
          grid,
      ],
    );
  }
}
