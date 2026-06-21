import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/goals/builtin_goal_templates.dart';
import 'package:focusNexus/goals/goals_time_window_service.dart';
import 'package:focusNexus/goals/repeat_rule.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/providers/theme_bundle_provider.dart';
import 'package:focusNexus/screens/goals/time_window_creation_feedback.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_apply_to_all_section.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_bulk_draft_card.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_repeat_editor.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_window_editor.dart';
import 'package:focusNexus/utils/common_utils.dart';

class TimeWindowBulkCreateWizard extends ConsumerStatefulWidget {
  const TimeWindowBulkCreateWizard({super.key});

  @override
  ConsumerState<TimeWindowBulkCreateWizard> createState() =>
      _TimeWindowBulkCreateWizardState();
}

class _BulkDraft {
  _BulkDraft({
    required this.name,
    required this.data,
    required this.endAt,
    required this.duration,
    required this.repeat,
  });

  final String name;
  final Map<String, dynamic> data;
  DateTime endAt;
  Duration duration;
  RepeatRule repeat;
}

class _TimeWindowBulkCreateWizardState
    extends ConsumerState<TimeWindowBulkCreateWizard> {
  int _step = 0;
  final _selected = <String>{};
  final _drafts = <_BulkDraft>[];
  DateTime _sharedEnd = DateTime.now().add(const Duration(hours: 2));
  Duration _sharedDuration = const Duration(hours: 1);
  RepeatRule _sharedRepeat = RepeatRule.none;

  Map<String, Map<String, dynamic>> get _templates {
    final ui = ref.read(goalsScreenUiProvider);
    return {...builtinGoalTemplates, ...ui.userTemplates};
  }

  void _goToWindows() {
    final templates = _templates;
    _drafts
      ..clear()
      ..addAll(
        _selected.map(
          (name) => _BulkDraft(
            name: name,
            data: templates[name]!,
            endAt: _sharedEnd,
            duration: _sharedDuration,
            repeat: _sharedRepeat,
          ),
        ),
      );
    setState(() => _step = 1);
  }

  Future<void> _createAll() async {
    final now = DateTime.now();
    final inputs = <CreateTimeWindowGoalInput>[
      for (final draft in _drafts)
        CreateTimeWindowGoalInput(
          title: draft.name,
          category: draft.data['category'] as String,
          complexity: draft.data['complexity'] as String,
          effort: draft.data['effort'] as String,
          motivation: draft.data['motivation'] as String,
          time: draft.data['time'] as String,
          steps: draft.data['steps'] as String,
          windowEndAt: draft.endAt,
          windowDuration: draft.duration,
          repeatRule: draft.repeat,
          templateName: draft.name,
        ),
    ];
    await ref.read(goalsProvider.notifier).createTimeWindowGoals(
      inputs: inputs,
      now: now,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final textStyle = ref.read(themeBundleProvider).textStyle;
    final count = inputs.length;
    Navigator.pop(context, true);
    showTimeSlotGoalsCreatedFeedback(
      messenger,
      textStyle: textStyle,
      count: count,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(themeBundleProvider);
    final templates = _templates;

    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        backgroundColor: bundle.secondaryColor,
        appBar: AppBar(
          title: Text(_stepTitle(), style: bundle.textStyle),
          backgroundColor: bundle.secondaryColor,
          iconTheme: IconThemeData(color: bundle.primaryColor),
          leading: _step > 0
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: bundle.primaryColor),
                  onPressed: () => setState(() => _step--),
                )
              : null,
        ),
        body: switch (_step) {
          0 => _selectStep(bundle, templates),
          1 => _windowsStep(bundle),
          _ => _repeatsStep(bundle),
        },
      ),
    );
  }

  String _stepTitle() => switch (_step) {
    0 => 'Create multiple',
    1 => 'Configure slots',
    _ => 'Configure repeats',
  };

  Widget _selectStep(
    ThemeBundle bundle,
    Map<String, Map<String, dynamic>> templates,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Select templates', style: bundle.textStyle),
        ...templates.keys.map((name) {
          return CheckboxListTile(
            title: Text(name, style: bundle.textStyle),
            value: _selected.contains(name),
            activeColor: bundle.primaryColor,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selected.add(name);
                } else {
                  _selected.remove(name);
                }
              });
            },
          );
        }),
        CommonUtils.buildElevatedButton(
          'Next',
          bundle.primaryColor,
          bundle.secondaryColor,
          bundle.textStyle,
          8,
          8,
          _selected.isEmpty ? () {} : _goToWindows,
          borderColor: bundle.accentColor,
        ),
      ],
    );
  }

  Widget _windowsStep(ThemeBundle bundle) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TimeWindowApplyToAllSection(
          bundle: bundle,
          title: 'Apply slot to all',
          child: TimeWindowWindowEditor(
            bundle: bundle,
            endAt: _sharedEnd,
            duration: _sharedDuration,
            onEndChanged: (v) => setState(() {
              _sharedEnd = v;
              for (final d in _drafts) {
                d.endAt = v;
              }
            }),
            onDurationChanged: (v) => setState(() {
              _sharedDuration = v;
              for (final d in _drafts) {
                d.duration = v;
              }
            }),
          ),
        ),
        const SizedBox(height: 16),
        Text('Customize each goal', style: bundle.textStyle),
        const SizedBox(height: 8),
        ..._drafts.map(
          (draft) => TimeWindowBulkDraftCard(
            bundle: bundle,
            title: draft.name,
            endAt: draft.endAt,
            duration: draft.duration,
            repeat: draft.repeat,
            showRepeat: false,
            onEndChanged: (v) => setState(() => draft.endAt = v),
            onDurationChanged: (v) => setState(() => draft.duration = v),
            onRepeatChanged: (_) {},
          ),
        ),
        CommonUtils.buildElevatedButton(
          'Next',
          bundle.primaryColor,
          bundle.secondaryColor,
          bundle.textStyle,
          8,
          8,
          () => setState(() => _step = 2),
          borderColor: bundle.accentColor,
        ),
      ],
    );
  }

  Widget _repeatsStep(ThemeBundle bundle) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TimeWindowApplyToAllSection(
          bundle: bundle,
          title: 'Apply repeat to all',
          child: TimeWindowRepeatEditor(
            bundle: bundle,
            rule: _sharedRepeat,
            onChanged: (r) => setState(() {
              _sharedRepeat = r;
              for (final d in _drafts) {
                d.repeat = r;
              }
            }),
          ),
        ),
        const SizedBox(height: 16),
        Text('Customize each goal', style: bundle.textStyle),
        const SizedBox(height: 8),
        ..._drafts.map(
          (draft) => TimeWindowBulkDraftCard(
            bundle: bundle,
            title: draft.name,
            endAt: draft.endAt,
            duration: draft.duration,
            repeat: draft.repeat,
            showWindow: false,
            onEndChanged: (_) {},
            onDurationChanged: (_) {},
            onRepeatChanged: (r) => setState(() => draft.repeat = r),
          ),
        ),
        CommonUtils.buildElevatedButton(
          'Create all',
          bundle.primaryColor,
          bundle.secondaryColor,
          bundle.textStyle,
          8,
          8,
          _createAll,
          borderColor: bundle.accentColor,
        ),
      ],
    );
  }
}
