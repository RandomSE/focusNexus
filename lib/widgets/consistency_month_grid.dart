import 'package:flutter/material.dart';
import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:intl/intl.dart';

/// Month contribution grid (Mon-Sun) with day-of-month labels.
class ConsistencyMonthGrid extends StatelessWidget {
  const ConsistencyMonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.counts,
    required this.today,
    required this.isDark,
    required this.onDaySelected,
    required this.dayNumberStyle,
    this.palette = ConsistencyPaletteId.coolTealDepth,
    this.density = ConsistencyCalendarDensity.comfortable,
    this.selectedDay,
  });

  final int year;
  final int month;
  final Map<DateTime, int> counts;
  final DateTime today;
  final bool isDark;
  final ValueChanged<DateTime> onDaySelected;
  final TextStyle dayNumberStyle;
  final ConsistencyPaletteId palette;
  final ConsistencyCalendarDensity density;
  final DateTime? selectedDay;

  double get _cellHeight =>
      density == ConsistencyCalendarDensity.compact ? 16 : 30;

  double get _pad => density == ConsistencyCalendarDensity.compact ? 1 : 2;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = ConsistencyDate.daysInMonth(year, month);
    final first = ConsistencyDate.monthStart(year, month);
    final leading = ConsistencyDate.mondayBasedWeekdayIndex(first);
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final weekdayStyle = dayNumberStyle.copyWith(
      fontSize: density == ConsistencyCalendarDensity.compact ? 8 : 10,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(label, style: weekdayStyle),
                ),
              ),
          ],
        ),
        SizedBox(height: density == ConsistencyCalendarDensity.compact ? 2 : 4),
        for (var row = 0; row < rows; row++)
          Padding(
            padding: EdgeInsets.only(
              bottom: density == ConsistencyCalendarDensity.compact ? 2 : 3,
            ),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _buildCell(
                      context,
                      cellIndex: row * 7 + col,
                      leading: leading,
                      daysInMonth: daysInMonth,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required int cellIndex,
    required int leading,
    required int daysInMonth,
  }) {
    final dayNum = cellIndex - leading + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return SizedBox(height: _cellHeight);
    }
    final day = DateTime(year, month, dayNum);
    final count = counts[ConsistencyDate.dateOnly(day)] ?? 0;
    final kind = ConsistencyCellSemantics.kindFor(
      day: day,
      today: today,
      count: count,
    );
    final fill = ConsistencyCellSemantics.fillFor(
      kind: kind,
      count: count,
      isDark: isDark,
      palette: palette,
    );
    final border = ConsistencyCellSemantics.borderFor(
      kind: kind,
      isDark: isDark,
      palette: palette,
    );
    final isSelected = selectedDay != null &&
        ConsistencyDate.sameDay(selectedDay!, day);
    final label = _semanticsLabel(day, count, kind);
    // Day numbers: palette-derived contrast only (not theme text colour).
    final numberColor = kind == ConsistencyCellKind.futureEmpty
        ? ConsistencyHeatmapColors.dayNumberColor(
            ConsistencyHeatmapColors.zeroColor(
              isDark: isDark,
              palette: palette,
            ),
          ).withValues(alpha: 0.4)
        : ConsistencyHeatmapColors.dayNumberColor(fill);

    return Padding(
      padding: EdgeInsets.all(_pad),
      child: Semantics(
        button: true,
        label: label,
        selected: isSelected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDaySelected(day),
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: _cellHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : border,
                  width: isSelected ? 1.5 : 0.8,
                ),
              ),
              child: Text(
                '$dayNum',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: dayNumberStyle.copyWith(
                  color: numberColor,
                  fontSize: density == ConsistencyCalendarDensity.compact
                      ? 8
                      : 11,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(DateTime day, int count, ConsistencyCellKind kind) {
    final dateLabel = DateFormat('d MMMM yyyy').format(day);
    return switch (kind) {
      ConsistencyCellKind.futureEmpty when count == 0 =>
        '$dateLabel, no completions yet',
      ConsistencyCellKind.missed => '$dateLabel, missed',
      ConsistencyCellKind.active =>
        '$dateLabel, $count goal${count == 1 ? '' : 's'} completed',
      ConsistencyCellKind.futureEmpty => dateLabel,
    };
  }
}
