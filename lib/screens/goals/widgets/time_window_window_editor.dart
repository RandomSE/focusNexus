import 'package:flutter/material.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_slot_section.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

class TimeWindowWindowEditor extends StatefulWidget {
  const TimeWindowWindowEditor({
    super.key,
    required this.bundle,
    required this.endAt,
    required this.startAt,
    required this.duration,
    required this.onEndChanged,
    required this.onStartChanged,
    required this.onDurationChanged,
    this.fullDaysOnly = false,
  });

  final ThemeBundle bundle;
  final DateTime endAt;
  final DateTime startAt;
  final Duration duration;
  final ValueChanged<DateTime> onEndChanged;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<Duration> onDurationChanged;
  final bool fullDaysOnly;

  @override
  State<TimeWindowWindowEditor> createState() => _TimeWindowWindowEditorState();
}

class _TimeWindowWindowEditorState extends State<TimeWindowWindowEditor> {
  late final TextEditingController _durationController;
  late int _durationValue;
  String _durationUnit = 'hours';

  @override
  void initState() {
    super.initState();
    _syncDurationFromWidget();
    _durationController = TextEditingController(text: '$_durationValue');
    _durationController.addListener(_onDurationTextChanged);
  }

  @override
  void didUpdateWidget(covariant TimeWindowWindowEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _syncDurationFromWidget();
      final text = '$_durationValue';
      if (_durationController.text != text) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_durationController.text != text) {
            _durationController.text = text;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _durationController
      ..removeListener(_onDurationTextChanged)
      ..dispose();
    super.dispose();
  }

  void _syncDurationFromWidget() {
    if (widget.fullDaysOnly ||
        (widget.duration.inDays > 0 && widget.duration.inHours % 24 == 0)) {
      _durationValue = widget.fullDaysOnly
          ? widget.duration.inDays.clamp(1, 9999)
          : widget.duration.inDays;
      _durationUnit = 'days';
    } else if (widget.duration.inHours > 0 &&
        widget.duration.inMinutes % 60 == 0) {
      _durationValue = widget.duration.inHours;
      _durationUnit = 'hours';
    } else {
      _durationValue = widget.duration.inMinutes;
      _durationUnit = 'minutes';
    }
  }

  Duration get _duration => switch (_durationUnit) {
    'days' => Duration(days: _durationValue),
    'minutes' => Duration(minutes: _durationValue),
    _ => Duration(hours: _durationValue),
  };

  DateTime _dayEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59);

  void _onDurationTextChanged() {
    final parsed = int.tryParse(_durationController.text);
    if (parsed == null || parsed == _durationValue) return;
    _durationValue = parsed;
    _applyDuration(_duration);
  }

  void _applyDuration(Duration duration) {
    if (duration <= Duration.zero) return;
    final now = DateTime.now();
    final start = clampActionWindowStart(
      start: widget.endAt.subtract(duration),
      end: widget.endAt,
      now: now,
    );
    widget.onStartChanged(start);
    // Keep the requested duration intact; only the displayed start clamps to
    // now. Recomputing from the clamped start would silently shrink the
    // series windowDuration whenever start falls before now (bug).
    widget.onDurationChanged(duration);
  }

  void _emitDuration() => _applyDuration(_duration);

  void _applyStart(DateTime start) {
    final now = DateTime.now();
    final ideal = DateTime(
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute,
    );
    final requestedDuration = widget.duration > Duration.zero
        ? widget.duration
        : defaultTimeWindowDuration;
    var end = resolveWindowEndAfterStart(
      start: ideal,
      end: widget.endAt,
      fallbackDuration: requestedDuration,
    );
    if (!end.isAtSameMomentAs(widget.endAt)) {
      widget.onEndChanged(end);
    }
    final clamped = clampActionWindowStart(
      start: ideal,
      end: end,
      now: now,
    );
    widget.onStartChanged(clamped);
    widget.onDurationChanged(requestedDuration);
  }

  void _nudgeStart(Duration delta) {
    _applyStart(widget.startAt.add(delta));
  }

  DateTime _withDate(DateTime base, DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
    base.hour,
    base.minute,
  );

  DateTime _withTime(DateTime base, TimeOfDay time) => DateTime(
    base.year,
    base.month,
    base.day,
    time.hour,
    time.minute,
  );

  void _applyEnd(DateTime end) {
    final resolved = widget.fullDaysOnly ? _dayEnd(end) : end;
    final now = DateTime.now();
    final requestedDuration = widget.duration;
    final start = clampActionWindowStart(
      start: resolved.subtract(requestedDuration),
      end: resolved,
      now: now,
    );
    widget.onEndChanged(resolved);
    widget.onStartChanged(start);
    // Moving the end date/time must not silently shrink the requested
    // duration just because the display-only start clamps to now; the
    // occurrence's actual start still clamps separately via computeActionWindow.
    widget.onDurationChanged(requestedDuration);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.endAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    _applyEnd(_withDate(widget.endAt, date));
  }

  Future<void> _pickEndTime() async {
    if (widget.fullDaysOnly) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.endAt),
    );
    if (time == null) return;
    _applyEnd(_withTime(widget.endAt, time));
  }

  Future<void> _pickStartDate() async {
    final range = actionWindowStartDatePickerRange(
      startAt: widget.startAt,
      endAt: widget.endAt,
    );
    final date = await showDatePicker(
      context: context,
      initialDate: range.initialDate,
      firstDate: range.firstDate,
      lastDate: range.lastDate,
    );
    if (date == null || !mounted) return;
    _applyStart(_withDate(widget.startAt, date));
  }

  Future<void> _pickStartTime() async {
    if (widget.fullDaysOnly) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.startAt),
    );
    if (time == null) return;
    _applyStart(_withTime(widget.startAt, time));
  }

  Widget _nudgeButton(String label, Duration delta) {
    return OutlinedButton(
      onPressed: () => _nudgeStart(delta),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: widget.bundle.textStyle.copyWith(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.bundle.textStyle;
    final startBeforeNow = widget.startAt.isBefore(
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimeWindowSlotSection(
          bundle: widget.bundle,
          title: 'Slot ends',
          icon: Icons.flag_outlined,
          dateLabel: formatActionWindowDateLabel(widget.endAt),
          timeLabel: widget.fullDaysOnly
              ? 'End of day'
              : formatActionWindowTimeLabel(widget.endAt),
          onPickDate: _pickEndDate,
          onPickTime: _pickEndTime,
          showTimeRow: !widget.fullDaysOnly,
        ),
        TimeWindowSlotSection(
          bundle: widget.bundle,
          title: 'Slot starts',
          icon: Icons.play_circle_outline,
          dateLabel: formatActionWindowDateLabel(widget.startAt),
          timeLabel: widget.fullDaysOnly
              ? 'Start of day'
              : formatActionWindowTimeLabel(widget.startAt),
          onPickDate: _pickStartDate,
          onPickTime: _pickStartTime,
          showTimeRow: !widget.fullDaysOnly,
        ),
        if (startBeforeNow)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              'Start is adjusted to now when the slot begins in the past.',
              style: textStyle.copyWith(
                fontSize: (textStyle.fontSize ?? 14) - 2,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (!widget.fullDaysOnly)
          outlinedFormRow(
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Adjust start (nudge)',
                    style: textStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _nudgeButton('-1d', const Duration(days: -1)),
                      _nudgeButton('-1h', const Duration(hours: -1)),
                      _nudgeButton('-5m', const Duration(minutes: -5)),
                      _nudgeButton('+5m', const Duration(minutes: 5)),
                      _nudgeButton('+1h', const Duration(hours: 1)),
                      _nudgeButton('+1d', const Duration(days: 1)),
                    ],
                  ),
                ],
              ),
            ),
            textStyle,
          )
        else
          outlinedFormRow(
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Adjust start (nudge)',
                    style: textStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _nudgeButton('-1d', const Duration(days: -1)),
                      _nudgeButton('+1d', const Duration(days: 1)),
                    ],
                  ),
                ],
              ),
            ),
            textStyle,
          ),
        outlinedFormRow(
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Slot length',
                  style: textStyle.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 360;
                    final amountField = TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: textStyle,
                      decoration: InputDecoration(
                        labelText: widget.fullDaysOnly ? 'Days' : 'Amount',
                        labelStyle: textStyle,
                      ),
                    );
                    final unitField = widget.fullDaysOnly
                        ? null
                        : DropdownButtonFormField<String>(
                            key: ValueKey(_durationUnit),
                            initialValue: _durationUnit,
                            isExpanded: true,
                            dropdownColor: widget.bundle.secondaryColor,
                            style: textStyle,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              labelStyle: textStyle,
                            ),
                            selectedItemBuilder: (context) => [
                              Text('min', style: textStyle),
                              Text('hr', style: textStyle),
                              Text('days', style: textStyle),
                            ],
                            items: const [
                              DropdownMenuItem(
                                value: 'minutes',
                                child: Text('minutes'),
                              ),
                              DropdownMenuItem(
                                value: 'hours',
                                child: Text('hours'),
                              ),
                              DropdownMenuItem(
                                value: 'days',
                                child: Text('days'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _durationUnit = v);
                              _emitDuration();
                            },
                          );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          amountField,
                          if (unitField != null) ...[
                            const SizedBox(height: 8),
                            unitField,
                          ],
                        ],
                      );
                    }
                    if (unitField == null) {
                      return amountField;
                    }
                    return Row(
                      children: [
                        Expanded(child: amountField),
                        const SizedBox(width: 8),
                        Expanded(child: unitField),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          textStyle,
        ),
      ],
    );
  }
}
