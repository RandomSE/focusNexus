import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/goals/builtin_goal_templates.dart';
import 'package:focusNexus/goals/goals_time_window_service.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/goals/time_window_points_label.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/time_window_creation_feedback.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_goal_fields_editor.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_repeat_editor.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_window_editor.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Inline form for creating a single time-slot goal (hub or full-screen route).
class TimeSlotGoalCreatePanel extends ConsumerStatefulWidget {
  const TimeSlotGoalCreatePanel({
    super.key,
    this.onGoalCreated,
  });

  final VoidCallback? onGoalCreated;

  @override
  ConsumerState<TimeSlotGoalCreatePanel> createState() =>
      _TimeSlotGoalCreatePanelState();
}

class _TimeSlotGoalCreatePanelState extends ConsumerState<TimeSlotGoalCreatePanel> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  DateTime _endAt = DateTime.now().add(const Duration(hours: 2));
  Duration _duration = const Duration(hours: 1);
  DateTime get _startAt => _endAt.subtract(_duration);
  RepeatRule _repeat = RepeatRule.none;
  String _category = 'Health';
  String _complexity = 'Low';
  String _effort = 'Low';
  String _motivation = 'Low';
  final _time = TextEditingController(text: '10');
  final _steps = TextEditingController(text: '1');

  @override
  void dispose() {
    _title.dispose();
    _time.dispose();
    _steps.dispose();
    super.dispose();
  }

  void _applyTemplate(String name, Map<String, dynamic> data) {
    _title.text = name;
    _category = data['category'] as String;
    _complexity = data['complexity'] as String;
    _effort = data['effort'] as String;
    _motivation = data['motivation'] as String;
    _time.text = data['time'] as String;
    _steps.text = data['steps'] as String;
    setState(() {});
  }

  void _resetForm() {
    _title.clear();
    _time.text = '10';
    _steps.text = '1';
    _category = 'Health';
    _complexity = 'Low';
    _effort = 'Low';
    _motivation = 'Low';
    _endAt = DateTime.now().add(const Duration(hours: 2));
    _duration = const Duration(hours: 1);
    _repeat = RepeatRule.none;
    setState(() {});
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    await ref.read(goalsProvider.notifier).createTimeWindowGoal(
      input: CreateTimeWindowGoalInput(
        title: _title.text.trim(),
        category: _category,
        complexity: _complexity,
        effort: _effort,
        motivation: _motivation,
        time: _time.text,
        steps: _steps.text,
        windowEndAt: _endAt,
        windowDuration: _duration,
        repeatRule: _repeat,
      ),
      now: now,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final textStyle = ref.read(themeBundleProvider).textStyle;
    showTimeSlotGoalsCreatedFeedback(
      messenger,
      textStyle: textStyle,
      count: 1,
    );
    _resetForm();
    widget.onGoalCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(themeBundleProvider);
    final ui = ref.watch(goalsScreenUiProvider);
    final templates = {
      ...builtinGoalTemplates,
      ...ui.userTemplates,
    };
    final previewPoints = previewTimeWindowPoints(
      complexity: _complexity,
      effort: _effort,
      motivation: _motivation,
      time: _time.text,
      steps: _steps.text,
      windowDuration: _duration,
    );
    final multiplierLabel = timeWindowMultiplierLabel(_duration);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommonUtils.buildDropdownButtonFormField(
            'Template (optional)',
            null,
            templates.keys.toList(),
            bundle.textStyle,
            bundle.secondaryColor,
            (v) {
              if (v == null) return;
              _applyTemplate(v, templates[v]!);
            },
          ),
          TimeWindowGoalFieldsEditor(
            bundle: bundle,
            titleController: _title,
            timeController: _time,
            stepsController: _steps,
            category: _category,
            complexity: _complexity,
            effort: _effort,
            motivation: _motivation,
            onCategoryChanged: (v) =>
                setState(() => _category = v ?? _category),
            onComplexityChanged: (v) =>
                setState(() => _complexity = v ?? _complexity),
            onEffortChanged: (v) => setState(() => _effort = v ?? _effort),
            onMotivationChanged: (v) =>
                setState(() => _motivation = v ?? _motivation),
          ),
          TimeWindowWindowEditor(
            bundle: bundle,
            endAt: _endAt,
            startAt: _startAt,
            duration: _duration,
            onEndChanged: (v) => setState(() => _endAt = v),
            onStartChanged: (v) => setState(
              () => _duration = _endAt.difference(v),
            ),
            onDurationChanged: (v) => setState(() => _duration = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Reward: $previewPoints pts ($multiplierLabel)',
              style: bundle.textStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TimeWindowRepeatEditor(
            bundle: bundle,
            rule: _repeat,
            onChanged: (r) => setState(() => _repeat = r),
          ),
          const SizedBox(height: 12),
          CommonUtils.buildElevatedButton(
            'Create time-slot goal',
            bundle.primaryColor,
            bundle.secondaryColor,
            bundle.textStyle,
            8,
            8,
            _create,
            borderColor: bundle.accentColor,
          ),
        ],
      ),
    );
  }
}
