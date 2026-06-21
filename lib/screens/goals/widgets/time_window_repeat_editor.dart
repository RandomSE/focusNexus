import 'package:flutter/material.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_goal.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

class TimeWindowRepeatEditor extends StatefulWidget {
  const TimeWindowRepeatEditor({
    super.key,
    required this.bundle,
    required this.rule,
    required this.onChanged,
  });

  final ThemeBundle bundle;
  final RepeatRule rule;
  final ValueChanged<RepeatRule> onChanged;

  @override
  State<TimeWindowRepeatEditor> createState() => _TimeWindowRepeatEditorState();
}

class _TimeWindowRepeatEditorState extends State<TimeWindowRepeatEditor> {
  late RepeatRule _rule;
  late final TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _rule = widget.rule;
    _intervalController = TextEditingController(text: '${_rule.interval}');
    _intervalController.addListener(_onIntervalChanged);
  }

  @override
  void didUpdateWidget(covariant TimeWindowRepeatEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule != widget.rule) {
      _rule = widget.rule;
      final text = '${_rule.interval}';
      if (_intervalController.text != text) {
        _intervalController.text = text;
      }
    }
  }

  @override
  void dispose() {
    _intervalController
      ..removeListener(_onIntervalChanged)
      ..dispose();
    super.dispose();
  }

  void _onIntervalChanged() {
    final parsed = int.tryParse(_intervalController.text);
    if (parsed == null) return;
    final clamped = parsed.clamp(1, 999);
    if (clamped == _rule.interval) return;
    _emit(_rule.copyWith(interval: clamped));
  }

  void _emit(RepeatRule next) {
    setState(() => _rule = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.bundle.textStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text('Repeat', style: textStyle),
          value: _rule.enabled,
          onChanged: (v) => _emit(_rule.copyWith(enabled: v)),
        ),
        if (_rule.enabled) ...[
          DropdownButtonFormField<RepeatUnit>(
            value: _rule.unit,
            dropdownColor: widget.bundle.secondaryColor,
            style: textStyle,
            decoration: InputDecoration(
              labelText: 'Every',
              labelStyle: textStyle,
            ),
            items: RepeatUnit.values
                .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) _emit(_rule.copyWith(unit: v));
            },
          ),
          TextFormField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            style: textStyle,
            decoration: InputDecoration(
              labelText: 'Interval',
              labelStyle: textStyle,
            ),
          ),
          if (_rule.unit == RepeatUnit.weeks ||
              (_rule.unit == RepeatUnit.days && _rule.weekdays.isNotEmpty))
            Wrap(
              spacing: 4,
              children: List.generate(7, (i) {
                final day = i + 1;
                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final selected = _rule.weekdays.contains(day);
                return FilterChip(
                  label: Text(labels[i], style: textStyle),
                  selected: selected,
                  onSelected: (v) {
                    final next = Set<int>.from(_rule.weekdays);
                    if (v) {
                      next.add(day);
                    } else {
                      next.remove(day);
                    }
                    _emit(_rule.copyWith(weekdays: next));
                  },
                );
              }),
            ),
          Text(
            summarizeRepeatRule(_rule),
            style: textStyle.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }
}
