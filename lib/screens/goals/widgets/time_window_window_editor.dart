import 'package:flutter/material.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

class TimeWindowWindowEditor extends StatefulWidget {
  const TimeWindowWindowEditor({
    super.key,
    required this.bundle,
    required this.endAt,
    required this.duration,
    required this.onEndChanged,
    required this.onDurationChanged,
  });

  final ThemeBundle bundle;
  final DateTime endAt;
  final Duration duration;
  final ValueChanged<DateTime> onEndChanged;
  final ValueChanged<Duration> onDurationChanged;

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
        _durationController.text = text;
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
    if (widget.duration.inDays > 0 && widget.duration.inHours % 24 == 0) {
      _durationValue = widget.duration.inDays;
      _durationUnit = 'days';
    } else if (widget.duration.inHours > 0) {
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

  void _onDurationTextChanged() {
    final parsed = int.tryParse(_durationController.text);
    if (parsed == null || parsed == _durationValue) return;
    _durationValue = parsed;
    widget.onDurationChanged(_duration);
  }

  void _emitDuration() => widget.onDurationChanged(_duration);

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.endAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.endAt),
    );
    if (time == null) return;
    widget.onEndChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.bundle.textStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text('Slot ends', style: textStyle),
          subtitle: Text(
            formatActionWindowEndLabel(widget.endAt),
            style: textStyle,
          ),
          trailing: Icon(
            Icons.calendar_today,
            color: widget.bundle.primaryColor,
          ),
          onTap: _pickEnd,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                style: textStyle,
                decoration: InputDecoration(
                  labelText: 'Slot length',
                  labelStyle: textStyle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _durationUnit,
                dropdownColor: widget.bundle.secondaryColor,
                style: textStyle,
                items: const [
                  DropdownMenuItem(value: 'minutes', child: Text('minutes')),
                  DropdownMenuItem(value: 'hours', child: Text('hours')),
                  DropdownMenuItem(value: 'days', child: Text('days')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _durationUnit = v);
                  _emitDuration();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
