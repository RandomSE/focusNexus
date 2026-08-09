import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/consistency_palette_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/utils/screen_semantics.dart';
import 'package:focusNexus/widgets/consistency_calendar_panel.dart';

/// Live consistency calendar on the Dashboard (compact).
class DashboardConsistencySection extends ConsumerStatefulWidget {
  const DashboardConsistencySection({
    super.key,
    required this.bundle,
  });

  final ThemeBundle bundle;

  @override
  ConsumerState<DashboardConsistencySection> createState() =>
      _DashboardConsistencySectionState();
}

class _DashboardConsistencySectionState
    extends ConsumerState<DashboardConsistencySection> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _openExplorer({
    required int year,
    required int month,
    DateTime? selectedDay,
  }) {
    ref.pushRoute(
      context,
      ConsistencyExplorerRoute(
        year: year,
        month: month,
        selectedDay: selectedDay,
      ),
    );
  }

  TextStyle get _sectionStyle {
    final base = widget.bundle.textStyle.fontSize ?? 14;
    return widget.bundle.textStyle.copyWith(
      fontSize: base.clamp(12.0, 15.0),
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = ref.watch(goalsProvider).completedGoals;
    final isDark = ref.watch(appSettingsProvider).snapshot.isDark;
    final palette = ref.watch(consistencyPaletteProvider);
    final today = DateTime.now();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openExplorer(year: _year, month: _month),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenSemantics.sectionHeader('Consistency', _sectionStyle),
          ConsistencyCalendarPanel(
            year: _year,
            month: _month,
            completedGoals: completed,
            today: today,
            isDark: isDark,
            palette: palette,
            density: ConsistencyCalendarDensity.compact,
            textStyle: widget.bundle.textStyle,
            primaryColor: widget.bundle.primaryColor,
            onMonthChanged: (monthStart) {
              setState(() {
                _year = monthStart.year;
                _month = monthStart.month;
              });
            },
            onDaySelected: (day) {
              _openExplorer(
                year: day.year,
                month: day.month,
                selectedDay: ConsistencyDate.dateOnly(day),
              );
            },
            onOpenExplorer: () {
              _openExplorer(year: _year, month: _month);
            },
          ),
        ],
      ),
    );
  }
}
