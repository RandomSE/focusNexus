import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/consistency/consistency_aggregator.dart';
import 'package:focusNexus/consistency/consistency_date.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:focusNexus/consistency/consistency_mock_july.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/consistency_palette_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/utils/screen_semantics.dart';
import 'package:focusNexus/widgets/consistency_calendar_panel.dart';
import 'package:focusNexus/widgets/consistency_palette_picker.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';
import 'package:intl/intl.dart';

/// Detail explorer: month grid, palette picker + Preview, and day goal list.
class ConsistencyExplorerScreen extends ConsumerStatefulWidget {
  const ConsistencyExplorerScreen({
    super.key,
    this.initialYear,
    this.initialMonth,
    this.initialSelectedDay,
    this.useMockData = false,
  });

  final int? initialYear;
  final int? initialMonth;
  final DateTime? initialSelectedDay;

  /// Legacy route arg; Preview toggle is preferred. When true, starts in Preview.
  final bool useMockData;

  @override
  ConsumerState<ConsistencyExplorerScreen> createState() =>
      _ConsistencyExplorerScreenState();
}

class _ConsistencyExplorerScreenState
    extends ConsumerState<ConsistencyExplorerScreen> {
  late int _year;
  late int _month;
  DateTime? _selectedDay;
  late final List<GoalSet> _mockGoals;
  late bool _palettePreview;
  int? _savedYear;
  int? _savedMonth;
  DateTime? _savedSelectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mockGoals = ConsistencyMockJuly.buildCompletedGoals();
    _palettePreview = widget.useMockData;
    if (_palettePreview) {
      _year = ConsistencyMockJuly.defaultYear;
      _month = 7;
      _selectedDay = widget.initialSelectedDay;
    } else {
      _year = widget.initialYear ?? now.year;
      _month = widget.initialMonth ?? now.month;
      _selectedDay = widget.initialSelectedDay;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsProvider.notifier).load();
    });
  }

  void _togglePreview() {
    setState(() {
      if (_palettePreview) {
        _palettePreview = false;
        _year = _savedYear ?? DateTime.now().year;
        _month = _savedMonth ?? DateTime.now().month;
        _selectedDay = _savedSelectedDay;
      } else {
        _savedYear = _year;
        _savedMonth = _month;
        _savedSelectedDay = _selectedDay;
        _palettePreview = true;
        _year = ConsistencyMockJuly.defaultYear;
        _month = 7;
        _selectedDay = null;
      }
    });
  }

  List<GoalSet> _completed(List<GoalSet> live) =>
      _palettePreview ? _mockGoals : live;

  TextStyle _capped(TextStyle style, {double max = 18}) {
    final size = style.fontSize ?? 14;
    return style.copyWith(
      fontSize: size.clamp(12.0, max),
      height: 1.25,
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(goalsProvider).completedGoals;
    final completed = _completed(live);
    final isDark = ref.watch(appSettingsProvider).snapshot.isDark;
    final palette = ref.watch(consistencyPaletteProvider);
    final today = _palettePreview
        ? DateTime(ConsistencyMockJuly.defaultYear, 7, 31)
        : DateTime.now();

    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final bodyStyle = _capped(bundle.textStyle);
        final dayGoals = _selectedDay == null
            ? const <GoalSet>[]
            : ConsistencyAggregator.goalsOnDay(completed, _selectedDay!);
        final dayLabel = _selectedDay == null
            ? 'Select a day'
            : DateFormat('d MMMM yyyy').format(_selectedDay!);
        final countLabel = _selectedDay == null
            ? ''
            : '${dayGoals.length} goal${dayGoals.length == 1 ? '' : 's'}';

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _palettePreview ? 'Consistency (preview)' : 'Consistency',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _capped(bundle.textStyle, max: 20),
              ),
              backgroundColor: bundle.secondaryColor,
            ),
            backgroundColor: bundle.secondaryColor,
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ConsistencyCalendarPanel(
                  year: _year,
                  month: _month,
                  completedGoals: completed,
                  today: today,
                  isDark: isDark,
                  palette: palette,
                  density: ConsistencyCalendarDensity.comfortable,
                  textStyle: bundle.textStyle,
                  primaryColor: bundle.primaryColor,
                  selectedDay: _selectedDay,
                  titleSuffix: _palettePreview ? 'preview' : null,
                  onMonthChanged: (monthStart) {
                    setState(() {
                      _year = monthStart.year;
                      _month = monthStart.month;
                      if (_selectedDay != null &&
                          (_selectedDay!.year != _year ||
                              _selectedDay!.month != _month)) {
                        _selectedDay = null;
                      }
                    });
                  },
                  onDaySelected: (day) {
                    setState(
                      () => _selectedDay = ConsistencyDate.dateOnly(day),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ConsistencyPalettePicker(
                  selected: palette,
                  textStyle: bundle.textStyle,
                  primaryColor: bundle.primaryColor,
                  secondaryColor: bundle.secondaryColor,
                  previewEnabled: _palettePreview,
                  onPreviewToggled: _togglePreview,
                  onSelected: (id) {
                    ref.read(consistencyPaletteProvider.notifier).select(id);
                  },
                ),
                const SizedBox(height: 16),
                ScreenSemantics.sectionHeader(dayLabel, bodyStyle),
                if (_selectedDay != null) ...[
                  Text(countLabel, style: bodyStyle),
                  const SizedBox(height: 8),
                  if (dayGoals.isEmpty)
                    Text(
                      'No goals completed this day.',
                      style: bodyStyle,
                    )
                  else
                    ...dayGoals.map(
                      (goal) => ExpansionTile(
                        key: ValueKey('goal-${goal.goalId}'),
                        title: Text(
                          goal.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle,
                        ),
                        subtitle: Text(
                          goal.completedAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle.copyWith(fontSize: 12),
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              'Category: ${goal.category.isEmpty ? '-' : goal.category}',
                              style: bodyStyle,
                            ),
                            subtitle: Text(
                              'Points: ${goal.points}',
                              style: bodyStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Navigation arguments for [ConsistencyExplorerRoute].
class ConsistencyExplorerArgs {
  const ConsistencyExplorerArgs({
    this.year,
    this.month,
    this.selectedDay,
    this.useMockData = false,
  });

  final int? year;
  final int? month;
  final DateTime? selectedDay;
  final bool useMockData;

  static ConsistencyExplorerArgs fromArguments(Object? arguments) {
    if (arguments is ConsistencyExplorerArgs) return arguments;
    if (arguments is Map) {
      final y = arguments['year'];
      final m = arguments['month'];
      final day = arguments['selectedDay'];
      final mock = arguments['useMockData'] == true;
      return ConsistencyExplorerArgs(
        year: y is int ? y : int.tryParse('$y'),
        month: m is int ? m : int.tryParse('$m'),
        selectedDay: day is DateTime ? day : null,
        useMockData: mock,
      );
    }
    return const ConsistencyExplorerArgs();
  }

  Map<String, Object?> toMap() => {
        'year': year,
        'month': month,
        'selectedDay': selectedDay,
        'useMockData': useMockData,
      };
}
