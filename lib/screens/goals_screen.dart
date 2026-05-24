// lib/screens/goals_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

import '../repositories/app_repositories.dart';
import '../services/sound_service.dart';
import '../settings/app_settings.dart';
import '../services/achievement_streak_service.dart';
import '../models/classes/theme_bundle.dart';
import '../models/classes/goal_set.dart';
import '../utils/common_utils.dart';
import '../utils/screen_theme.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/settings_themed_builder.dart';
import '../utils/goal_points.dart';
import '../utils/notifier.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  AppRepositories get _repos => AppRepositories.instance;
  AppSettings get _settings => _repos.settings;
  AchievementStreakService get _streaks => _repos.streaks;
  ThemeBundle get themeBundle =>
      _repos.theme.bundleFromSnapshot(_settings.snapshot);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _templateName = TextEditingController();
  final TextEditingController _templateTime = TextEditingController();
  final TextEditingController _templateSteps = TextEditingController();
  final TextEditingController _templateDeadline = TextEditingController();
  String _selectedCategoryFilter = 'All';
  String _selectedComplexityFilter = 'All';
  String _selectedStatusFilter = 'Active';
  String _sortBy = 'None';
  String _category = 'Productivity';
  String _complexity = 'Low';
  String _effort = 'Low';
  String _time = '1';
  String _steps = '1';
  final String today = DateFormat('dd MM yyyy').format(DateTime.now());
  int goalsCompletedToday = 0;
  String _motivation = 'Low';
  final _categories = ['Productivity', 'Health', 'Learning', 'Social', 'Self-care', 'Work', 'Relationships', 'Other'];
  final _levels = ['Low', 'Medium', 'High'];
  final Map<String, Map<String, dynamic>> _templateDetails = {
    'Clean your room': {
      'category': 'Productivity',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Medium',
      'time': '10',
      'Hours to complete': '24',
      'steps': '1',
    },
    '5-minute walk': {
      'category': 'Health',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Low',
      'time': '5',
      'Hours to complete': '24',
      'steps': '1',
    },
    'Make a meal': {
      'category': 'Health',
      'complexity': 'Medium',
      'effort': 'Medium',
      'motivation': 'Medium',
      'time': '30',
      'Hours to complete': '24',
      'steps': '2',
    },
    'Take a shower': {
      'category': 'Health',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Low',
      'time': '10',
      'Hours to complete': '24',
      'steps': '1',
    },
    'Compliment someone': {
      'category': 'Social',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Low',
      'time': '1',
      'Hours to complete': '24',
      'steps': '1',
    },
  };
  List<Map<String, dynamic>> _activeGoals = [];
  List<Map<String, dynamic>> _completedGoals = [];
  final DateTime _currentDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    DateTime.now().hour,
    DateTime.now().minute
  );
  final DateFormat formatter = DateFormat('dd MMMM yyyy HH:mm');
  Map<String, Map<String, dynamic>> _userTemplates = {};
  Map<String, List<String>> _templateGroups = {};
  bool _pageReady = false;
  bool _notificationsEnabled = false;
  String _notificationStyle = 'Minimal';
  String _notificationFrequency = 'Low';
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadGoalsPage();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> loadNotificationStyleAndFrequency() async {
    _notificationsEnabled = _settings.notificationsEnabled;
    _notificationStyle = _settings.notificationStyle;
    _notificationFrequency = _settings.notificationFrequency;
  }


  Future<void> _loadGoalsPage() async {
    _stepsController.text = '1';
    _templateSteps.text = '1';
    await _loadGoals();
    await _loadTemplates();
    await _loadTemplateGroups();
    await loadNotificationStyleAndFrequency();
    if (mounted) setState(() => _pageReady = true);
  }


  Future<int> getTotalAmount(int amount) async {
    final count = await _repos.goals.nextCompletedTodayCount(today);
    await _repos.goals.writeCompletedToday(today: today, count: count);
    debugPrint('today: $today, count: $count');
    goalsCompletedToday = count;

    double reward = amount.toDouble();

    if (count == 1) {
      reward = amount * 2 + 100;

    } else if (count <= 5) {
      reward = amount * 1.5 + 20;
    }

    else if (count <= 10) {
      reward = amount * 1.25 + 5;
    }

    // Round up to nearest multiple of 5
    final int rounded = GoalPoints.roundUpToNearestFive(reward);
    return rounded;
  }

  Future<void> _loadTemplates() async {
    final templates = await _repos.templates.readUserTemplates();
    setState(() {
      _userTemplates = templates;
    });
  }

  Future<void> _saveTemplates() async {
    await _repos.templates.writeUserTemplates(_userTemplates);
    setState(() {});
  }

  Future<void> _loadGoals() async {
    final active = await _repos.goals.readActiveGoals();
    final complete = await _repos.goals.readCompletedGoals();
    setState(() {
      _activeGoals = active;
      _completedGoals = complete;
    });

    if (!await _repos.goals.areDeadlinesPaused()) {
      _checkForExpiredGoals();
    }
  }

  List<Map<String, dynamic>> get _filteredSortedGoals {
    List<Map<String, dynamic>> source =
        _selectedStatusFilter == 'Active' ? _activeGoals : _completedGoals;
    var goals = List<Map<String, dynamic>>.from(source);

    if (_selectedCategoryFilter != 'All') {
      goals =
          goals.where((g) => g['category'] == _selectedCategoryFilter).toList();
    }
    if (_selectedComplexityFilter != 'All') {
      goals =
          goals
              .where((g) => g['complexity'] == _selectedComplexityFilter)
              .toList();
    }

    switch (_sortBy) {
      case 'Title A-Z':
        goals.sort((a, b) => a['title'].compareTo(b['title']));
        break;
      case 'Title Z-A':
        goals.sort((a, b) => b['title'].compareTo(a['title']));
        break;
      case 'Time ↑':
        goals.sort(
          (a, b) => int.tryParse(
            a['time'] ?? '0',
          )!.compareTo(int.tryParse(b['time'] ?? '0')!),
        );
        break;
      case 'Time ↓':
        goals.sort(
          (a, b) => int.tryParse(
            b['time'] ?? '0',
          )!.compareTo(int.tryParse(a['time'] ?? '0')!),
        );
        break;
      case 'Steps ↑':
        goals.sort((a, b) => a['steps'].length.compareTo(b['steps'].length));
        break;
      case 'Steps ↓':
        goals.sort((a, b) => b['steps'].length.compareTo(a['steps'].length));
        break;

      case 'Closest deadline':
        final DateFormat deadlineFormat = formatter;

        // Separate goals into two groups: valid and invalid deadlines
        final List<Map<String, dynamic>> withDeadline = [];
        final List<Map<String, dynamic>> withoutDeadline = [];

        for (final goal in goals) {
          final deadlineString = goal['Deadline'];
          try {
            // Try parsing the deadline
            final DateTime parsed = deadlineFormat.parseStrict(deadlineString);
            goal['_parsedDeadline'] = parsed; // Temporarily store for sorting
            withDeadline.add(goal);
          } catch (_) {
            // Not parseable or missing
            withoutDeadline.add(goal);
          }
        }

        // Sort only those with valid deadlines by soonest first
        withDeadline.sort((a, b) =>
            a['_parsedDeadline'].compareTo(b['_parsedDeadline']));

        // Remove temporary field after sorting (optional)
        for (final goal in withDeadline) {
          goal.remove('_parsedDeadline');
        }

        // Merge lists: valid deadlines first, then the rest
        goals
          ..clear()
          ..addAll(withDeadline)
          ..addAll(withoutDeadline);
        break;
    }
    return goals;
  }

  void _clearGoals() {
    while (_activeGoals.isNotEmpty) {
      _removeGoalWithoutRemovingNotifications(0);
    }
    GoalNotifier.cancelAllGoalNotifications(); // Handled here separately.
    _streaks.setInt('totalGoalsActive', 0);
  }

  void _clearCompleteGoals () {
    while (_completedGoals.isNotEmpty) {
      _removeCompletedGoal(0);
    }
  }

  int _calculatePointsFromTemplate({
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required String deadline,
  }) {
    return GoalPoints.calculatePointsFromTemplate(
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      deadline: deadline,
    );
  }



  Future<void> _saveGoals() async {
    await _repos.goals.writeActiveGoals(_activeGoals);
    await _repos.goals.writeCompletedGoals(_completedGoals);
  }

  Future<void> _addPoints(int amount, String source) async {
    final value = await _repos.points.readBalance();
    final totalAmount = await getTotalAmount(amount);
    await _repos.points.writeBalance(value + totalAmount);
  }

  Map<String, dynamic> buildAndSaveGoal({
    required String title,
    required String category,
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required String deadline,
    required String goalId,
  }) {

    final goal = {
      'title': title,
      'category': category,
      'complexity': complexity,
      'effort': effort,
      'motivation': motivation,
      'time': time,
      'Deadline': deadline,
      'steps': steps,
      'points': _calculatePointsFromTemplate(
        complexity: complexity,
        effort: effort,
        motivation: motivation,
        time: time,
        steps: steps,
        deadline: deadline,
      ),
      'stepProgress': 0,
      'Id': goalId,
    };

    setState(() {
      _activeGoals.add(goal);
    });
    _saveGoals();
    return goal;


  }


  Future<void> _createGoal() async {
    if (_stepsController.text == '') {
      _stepsController.text = '1'; // default.
    }
    if (_formKey.currentState!.validate()) {
      final goalId = generateGoalId(_titleController.text);
      final int hours = int.tryParse(_deadlineController.text.trim()) ?? 0;
      final String deadline = _deadlineController.text.trim().isEmpty
          ? 'no deadline'
          : formatter.format(_currentDate.add(Duration(hours: hours)));
      debugPrint('Current deadline: $deadline');
      loadNotificationStyleAndFrequency();

      final goal = buildAndSaveGoal(
        title: _titleController.text,
        category: _category,
        complexity: _complexity,
        effort: _effort,
        motivation: _motivation,
        time: _timeController.text,
        steps: _stepsController.text,
        deadline: deadline,
        goalId: goalId.toString(),
      );

      if (_notificationsEnabled && hours > 0 && !_settings.pauseGoals) {
        final goalSet = GoalSet.fromMap(goal);
        GoalNotifier.startGoalCheck(goalSet, _notificationStyle, _notificationFrequency, hours);
      } else {
        debugPrint('Notifications not enabled — skipping goal check scheduling');
      }
      _resetControllers();
      await _streaks.increment('totalGoalsCreated');
      await _streaks.increment('totalGoalsActive');
    }

    SoundService.playGoalCreated();
  }

  void _resetControllers() {
    _titleController.clear();
    _timeController.clear();
    _deadlineController.clear();
    _stepsController.text = '1';
  }

  void _incrementStepProgress(int index) {
    final goal = _activeGoals[index];
    GoalNotifier.cancelAiEncouragementNotification(int.parse(goal['Id']));
    final max = int.tryParse(goal['steps']) ?? 1;
    if (goal['stepProgress'] < max) {
      setState(() {
        goal['stepProgress']++;
      });
      if (goal['stepProgress'] >= max) _completeGoal(index);
      _saveGoals();
    }
  }

  Future<void> _createGoalFromTemplates({
    required String title,
    required String category,
    required String complexity,
    required String effort,
    required String motivation,
    required String time,
    required String steps,
    required String deadlineHours,
  }) async {
    final goalId = GoalNotifier.generateGoalId(title);
    final int hours = int.tryParse(deadlineHours) ?? 0;
    final String deadline = deadlineHours.isEmpty
        ? 'no deadline'
        : formatter.format(_currentDate.add(Duration(hours: hours)));
    debugPrint('Current deadline: $deadline');
    loadNotificationStyleAndFrequency();

    final goal = buildAndSaveGoal(
      title: title,
      category: category,
      complexity: complexity,
      effort: effort,
      motivation: motivation,
      time: time,
      steps: steps,
      deadline: deadline,
      goalId: goalId.toString(),
    );

    if (_notificationsEnabled && hours > 0 && !_settings.pauseGoals) {
      final goalSet = GoalSet.fromMap(goal);
      GoalNotifier.startGoalCheck(goalSet, _notificationStyle, _notificationFrequency, hours);
    } else {
      debugPrint('Notifications not enabled — skipping goal check scheduling');
    }

    await _streaks.increment('totalGoalsCreated');
    await _streaks.increment('totalGoalsActive');
    SoundService.playGoalCreated();
  }

  Future<void> _checkGoalCompletionAchievementVariables(GoalSet goalSet) async {
    await _streaks.decrement('totalGoalsActive');
    await _streaks.increment('totalGoalsCompleted');
    await _streaks.checkOrAddDate();
    await _streaks.updateGoalAchievementStats(goalSet);
  }

  Future<void> _createGoalsFromTemplatesBulk(List<String> templateNames) async {
    if (templateNames.isEmpty) {
      CommonUtils.showBasicAlertDialog(
        context,
        'No templates Selected',
        'Please select at least one template to create goals from.',
        themeBundle.textStyle,
        themeBundle.secondaryColor,
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: themeBundle.secondaryColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Goals are being created.',
            style: themeBundle.textStyle,
          ),
        ),
      ),
    );

    try {
      final futures = <Future<void>>[];

      for (final templateName in templateNames) {
        final data =
            _templateDetails[templateName] ?? _userTemplates[templateName]!;

        futures.add(_createGoalFromTemplates(
          title: templateName,
          category: data['category'],
          complexity: data['complexity'],
          effort: data['effort'],
          motivation: data['motivation'],
          time: data['time'],
          steps: data['steps'],
          deadlineHours: data['Hours to complete'],
        ));
      }

      await Future.wait(futures);
      SoundService.playGoalCreated();
    } finally {
      if (mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    }

    if (!mounted) return;
    CommonUtils.showDialogWidget(
      context,
      'Goals created from selected templates.',
      themeBundle.textStyle,
      themeBundle.secondaryColor,
    );
  }



  void _completeGoal(int index) {
    final goal = _activeGoals.removeAt(index);
    final goalSet = GoalSet.fromMap(goal);
    GoalNotifier.cancelGoalNotification(goalSet); // Cancel notifications
    _completedGoals.add(goal);
    _addPoints(goal['points'], 'goal:${goal['title']}');
    _saveGoals();
    setState(() {});
    _checkGoalCompletionAchievementVariables(goalSet);
    SoundService.playGoalCompleted();
    _confettiController.play();
    CommonUtils.showSnackBar(context, '${goal['title']} completed! +${goal['points']} points. ' 'Goals completed today: $goalsCompletedToday', themeBundle.textStyle, 2000, 5);
  }

  void _removeGoal(int index) {
    final goal = _activeGoals[index];
    final goalSet = GoalSet.fromMap(goal);
    GoalNotifier.cancelGoalNotification(goalSet); // Cancel notifications
    setState(() {
      _activeGoals.removeAt(index);
    });
    _saveGoals();
    _streaks.decrement('totalGoalsActive');
  }

  void _removeGoalWithoutRemovingNotifications(int index) {
    final goal = _activeGoals[index];
    setState(() {
      _activeGoals.removeAt(index);
    });
    _saveGoals();
    _streaks.decrement('totalGoalsActive');
  }

  void _removeCompletedGoal(int index) {
    final goal = _completedGoals[index];
    setState(() {
      _completedGoals.removeAt(index);
    });
    _saveGoals();
  }

  void _checkForExpiredGoals() {
    final DateTime now = DateTime.now();

    // Reverse index scan to safely remove while iterating
    for (int i = _activeGoals.length - 1; i >= 0; i--) {
      final goal = _activeGoals[i];
      final deadlineStr = goal['Deadline'];
      if (deadlineStr == null || deadlineStr.toString().trim().isEmpty) continue;

      try {
        final parsed = formatter.parseStrict(deadlineStr);
        if (!parsed.isAfter(now)) {
          _removeGoal(i); // ✅ Remove expired goal
        }
      } catch (_) {
        // Invalid date format, skip
      }
    }
  }

  void _preSaveTemplate(String templateCategory, String templateComplexity, String templateEffort, String templateMotivation, GlobalKey<FormState> templateFormKey) {
    if (!templateFormKey.currentState!.validate()) {
      return; // stop if validation fails
    }
    if(_templateSteps.text.trim() == '') {
      _templateSteps.text = '1';
    }
    final name = _templateName.text.trim();
    final data = {
      'category': templateCategory,
      'complexity': templateComplexity,
      'effort': templateEffort,
      'motivation': templateMotivation,
      'time': _templateTime.text.trim(),
      'steps': _templateSteps.text.trim(),
      'Hours to complete': _templateDeadline.text.trim(),
    };

    if (_templateDetails.containsKey(name)) {
      setState(() => _templateDetails[name] = data);
    } else {
      setState(() => _userTemplates[name] = data);
    }
    _saveTemplates();

    _templateName.clear();
    _templateTime.clear();
    _templateSteps.text = '1';
    _templateDeadline.clear();
  }

  void _viewGoalDetails(Map<String, dynamic> goal) {
    showDialog(
      context: context,
      barrierColor: themeBundle.secondaryColor, // ✅ Sets overlay color
      builder:
          (_) => AlertDialog(
            backgroundColor: themeBundle.secondaryColor,
            iconColor: themeBundle.primaryColor,
            title: Text(goal['title'], style: themeBundle.textStyle),
            content: Container(
              color: themeBundle.secondaryColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category: ${goal['category']}', style: themeBundle.textStyle),
                  Text('Complexity: ${goal['complexity']}', style: themeBundle.textStyle),
                  Text('Effort: ${goal['effort']}', style: themeBundle.textStyle),
                  Text('Motivation: ${goal['motivation']}', style: themeBundle.textStyle),
                  Text('Time Needed in minutes: ${goal['time']}', style: themeBundle.textStyle),
                  Text('Deadline: ${goal['Deadline']}', style: themeBundle.textStyle),
                  Text('Steps: ${goal['steps']}', style: themeBundle.textStyle),
                  Text('Points: ${goal['points']}', style: themeBundle.textStyle),
                  Text('Id: ${goal['Id']}', style: themeBundle.textStyle),
                ],
              ),
            ),
            actions: [
              Container(
                color: themeBundle.secondaryColor,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: themeBundle.textStyle,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _openTemplateManager() {
    String templateCategory = _categories.first;
    String templateComplexity = _levels.first;
    String templateEffort = _levels.first;
    String templateMotivation = _levels.first;

    int minutesRequired = 0;
    int minutesToDeadline = 0;

    final GlobalKey<FormState> templateFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: themeBundle.secondaryColor,
          title: Text('Manage Templates', style: themeBundle.textStyle),
          content: SingleChildScrollView(
            child: Container(
              color: themeBundle.secondaryColor,
              child: Form(
                key: templateFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CommonUtils.buildTextFormField(
                      _templateName, 'Template Name (required)', themeBundle.textStyle, themeBundle.secondaryColor, true, (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Template name is required';
                        }
                        return null;
                        },
                    ),
                    CommonUtils.buildDropdownButtonFormField('Category', templateCategory, _categories, themeBundle.textStyle, themeBundle.secondaryColor, (v) => setState(() => templateCategory = v!)),
                    CommonUtils.buildDropdownButtonFormField('Complexity', templateComplexity, _levels, themeBundle.textStyle, themeBundle.secondaryColor, (v) => setState(() => templateComplexity = v!)),
                    CommonUtils.buildDropdownButtonFormField('Effort', templateEffort, _levels, themeBundle.textStyle, themeBundle.secondaryColor, (v) => setState(() => templateEffort = v!)),
                    CommonUtils.buildDropdownButtonFormField('Motivation', templateMotivation, _levels, themeBundle.textStyle, themeBundle.secondaryColor, (v) => setState(() => templateMotivation = v!)),
                    CommonUtils.buildTextFormField(_templateTime, 'Time (minutes, required)', themeBundle.textStyle, themeBundle.secondaryColor, true, (v) {
                      final parsed = int.tryParse(v?.trim() ?? '');
                      if (parsed == null || parsed < 1 || parsed > 999) {
                        return 'Please enter a whole number > 0 and < 1000';
                      }
                      minutesRequired = parsed;
                      return null;
                      }, keyboardType: TextInputType.number
                    ),

                    CommonUtils.buildTextFormField(_templateDeadline, 'Hours to complete (optional)', themeBundle.textStyle, themeBundle.secondaryColor, true, (v) {
                      if (v == null || v.trim().isEmpty) return null; // optional
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null || parsed <= 0 || parsed > 10000) {
                        return 'Must be a whole number > 0 and < 10000';
                      }
                      minutesToDeadline = parsed * 60;
                      if (minutesRequired > minutesToDeadline) {
                        return 'Deadline must be greater than time required.';
                      }
                      return null;
                      }, keyboardType: TextInputType.number
                    ),

                    CommonUtils.buildTextFormField(_templateSteps, 'Steps (Required)', themeBundle.textStyle, themeBundle.secondaryColor, true, (v) {
                      final trimmed = v?.trim();
                      final parsed = int.tryParse(trimmed?.isEmpty ?? true ? '1' : trimmed!);
                      if (parsed == null || parsed < 1 || parsed > 999) {
                        return 'Please enter a valid whole number > 0 and smaller than 1000';
                      }
                      return null;
                      },
                    ),
                    CommonUtils.buildElevatedButton('Save Template', themeBundle.primaryColor, themeBundle.secondaryColor, themeBundle.textStyle, 14, 10, () => _preSaveTemplate(templateCategory, templateComplexity, templateEffort, templateMotivation, templateFormKey)),
                    const Divider(),
                    Text('Templates:', style: themeBundle.textStyle),
                    ...[
                      ..._templateDetails.keys,
                      ..._userTemplates.keys,
                    ].map(
                          (name) => ListTile(
                        title: Text(name),
                        titleTextStyle: themeBundle.textStyle,
                        trailing: _userTemplates.containsKey(name)
                            ? IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _userTemplates.remove(name);
                              _saveTemplates();
                              _validateTemplateGroups(); // check that no multi-templates were effected by this deletion.
                            });
                          },
                        )
                            : null,
                        onTap: () {
                          final t = _templateDetails[name] ?? _userTemplates[name]!;
                          setState(() {
                            _templateName.text = name;
                            templateCategory = t['category'];
                            templateComplexity = t['complexity'];
                            templateEffort = t['effort'];
                            templateMotivation = t['motivation'];
                            _templateTime.text = t['time'];
                            _templateDeadline.text = t['Hours to complete'];
                            _templateSteps.text = t['steps'];
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: themeBundle.textStyle),
            ),
          ],
        ),
      ),
    );
  }

  static int generateGoalId(String goalName) {
    final random = Random();
    final randomPart = random.nextInt(100000);
    final hashPart = goalName.hashCode.abs();

    // Combine safely within 32-bit int range
    final combined = (hashPart % 1000000) * 100000 + randomPart;
    return combined & 0x7FFFFFFF;
  }

  Future<void> _saveTemplateGroups() async {
    await _repos.templates.writeTemplateGroups(_templateGroups);
  }

  Future<void> _validateTemplateGroups() async { // Cleans up template groups with deleted templates.
    // Collect all valid template names
    final validTemplateNames = _userTemplates.keys.toSet();

    final Map<String, List<String>> updatedGroups = {};

    _templateGroups.forEach((groupName, templates) {
      // Keep only templates that still exist
      final validTemplates = templates.where((t) => validTemplateNames.contains(t)).toList();

      if (validTemplates.isEmpty) {
        debugPrint('Group "$groupName" only contained deleted templates. Removing group.');
        CommonUtils.showBasicAlertDialog(context, 'Multi-template using deleted template(s)', '$groupName contained only deleted templates. Removing group.', themeBundle.textStyle, themeBundle.secondaryColor);
        // skip this group entirely
      } else if (validTemplates.length < templates.length) {
        debugPrint('Group "$groupName" had some deleted templates. Rebuilding with valid ones: $validTemplates');
        CommonUtils.showBasicAlertDialog(context, 'Multi-template using deleted template(s)', 'Group "$groupName" had some deleted templates. Rebuilding with valid ones: $validTemplates', themeBundle.textStyle, themeBundle.secondaryColor);
        updatedGroups[groupName] = validTemplates;
      } else {
        // all templates still valid
        updatedGroups[groupName] = templates;
      }
    });

    setState(() {
      _templateGroups = updatedGroups;
    });

    // persist the cleaned-up groups
    await _repos.templates.writeTemplateGroups(_templateGroups);
  }



  Future<void> _loadTemplateGroups() async {
    final groups = await _repos.templates.readTemplateGroups();
    setState(() {
      _templateGroups = groups;
    });
  }

  void _openMultiTemplateManager() {
    String? validationMessage;

    final TextEditingController groupNameController = TextEditingController();
    List<String> selectedTemplates = [];
    String? selectedGroup;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: themeBundle.secondaryColor,
            title: Text('Select Multiple Templates', style: themeBundle.textStyle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonUtils.buildDropdownButtonFormField('Load Saved Group', selectedGroup, _templateGroups.keys.toList(), themeBundle.textStyle, themeBundle.secondaryColor, (groupName){
                    setState(() {
                      selectedGroup = groupName;
                      selectedTemplates = List.from(_templateGroups[groupName!] ?? []);
                      groupNameController.text = groupName; // auto-fill name when loading group
                    });
                  }),
                  const SizedBox(height: 10),
                  CommonUtils.buildTextFormField(groupNameController, 'Group Name (required to save/update)', themeBundle.textStyle, themeBundle.secondaryColor, false, (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Group name is required';
                    }
                    return null;
                  }),
                  const SizedBox(height: 10),
                  Text('Select Templates to Create Goals:', style: themeBundle.textStyle),
                  ...[..._templateDetails.keys, ..._userTemplates.keys].map((templateName) {
                    final selected = selectedTemplates.contains(templateName);
                    return CheckboxListTile(
                      title: Text(templateName, style: themeBundle.textStyle),
                      value: selected,
                      activeColor: themeBundle.primaryColor,
                      checkColor: themeBundle.secondaryColor,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedTemplates.add(templateName);
                          } else {
                            selectedTemplates.remove(templateName);
                          }
                        });
                      },
                    );
                  }),
                  const Divider(),
                  Text('Existing Groups:', style: themeBundle.textStyle),
                  ..._templateGroups.keys.map((name) {
                    return ListTile(
                      title: Text(name, style: themeBundle.textStyle),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        color: themeBundle.primaryColor,
                        onPressed: () {
                          setState(() {
                            _templateGroups.remove(name);
                          });
                          _saveTemplateGroups();
                        },
                      ),
                      onTap: () async {
                        setState(() {
                          selectedGroup = name;
                          selectedTemplates = List.from(_templateGroups[name]!);
                          groupNameController.text = name; // auto-fill name when selecting existing group
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              CommonUtils.buildTextButton( () => Navigator.pop(context), 'Cancel', themeBundle.textStyle),
              CommonUtils.buildTextButton( () {
                  final groupName = groupNameController.text.trim();
                  if (groupName.isEmpty || selectedTemplates.isEmpty) {
                    setState(() {
                      validationMessage = 'Please enter a group name and select at least one template.';
                    });
                    return;
                  }

                  setState(() {
                    _templateGroups[groupName] = List.from(selectedTemplates);
                    validationMessage = null; // clear message on success
                  });
                  _saveTemplateGroups();
                  CommonUtils.showDialogWidget(context, '$groupName has been updated.', themeBundle.textStyle, themeBundle.secondaryColor);
              }, 'Save/Update Group', themeBundle.textStyle ),
              if (validationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    validationMessage!,
                    style: themeBundle.textStyle.copyWith(color: Colors.purple),
                  ),
                ),
              CommonUtils.buildElevatedButton('Create Goals', themeBundle.primaryColor, themeBundle.secondaryColor, themeBundle.textStyle, 0, 0, () async {
                if (selectedTemplates.isEmpty) {
                  CommonUtils.showBasicAlertDialog(context, 'No templates Selected', 'Please select at least one template to create goals from.', themeBundle.textStyle, themeBundle.secondaryColor);
                  return;
                }
                await _createGoalsFromTemplatesBulk(selectedTemplates);
              }),
            ],
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        if (!_pageReady) {
          return themedLoadingShell(
            bundle,
            title: 'Goals',
            body: GoalsSkeleton(bundle: bundle),
          );
        }
        return _buildGoalsScaffold(context, bundle);
      },
    );
  }

  Widget _buildGoalsScaffold(BuildContext context, ThemeBundle bundle) {
    int minutesRequired = 0;
    int minutesToDeadline = 0;

    return Theme(
      data: bundle.themeData,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            'Goals',
            style: bundle.textStyle,
          ),
          backgroundColor: bundle.secondaryColor,
          iconTheme: IconThemeData(color: bundle.primaryColor),
        ),
        backgroundColor: bundle.secondaryColor,
        body: Container(
          // SafeArea - Container
          color: bundle.secondaryColor,
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                CommonUtils.buildDropdownButtonFormField(
                                'Template (optional)', null, [..._templateDetails.keys, ..._userTemplates.keys], themeBundle.textStyle, themeBundle.secondaryColor,
                                (val) {
                                  if (val == null) return;
                                  _titleController.text = val;
                                  final data = _templateDetails[val] ?? _userTemplates[val]!;
                                  setState(() {
                                  _category = data['category'];
                                  _complexity = data['complexity'];
                                  _effort = data['effort'];
                                  _time = data['time'];
                                  _steps = data['steps'];
                                  _motivation = data['motivation'];
                                  });
                                  _timeController.text = data['time'];
                                  _deadlineController.text = data['Hours to complete'];
                                  _stepsController.text = data['steps'];
                                  }),
                                CommonUtils.buildDropdownButtonFormField('Category', _category, _categories, themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _category = val ?? 'Productivity')),
                                CommonUtils.buildDropdownButtonFormField('Complexity', _complexity, _levels, themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _complexity = val ?? 'Low')),
                                CommonUtils.buildDropdownButtonFormField('Effort Required', _effort, _levels, themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _effort = val ?? 'Low')),
                                CommonUtils.buildDropdownButtonFormField('Motivation Needed', _motivation, _levels, themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _motivation = val ?? 'Low')),
                                CommonUtils.buildTextFormField(_titleController, 'Goal Title', themeBundle.textStyle, themeBundle.secondaryColor, true, (v) =>
                                v == null || v.isEmpty
                                    ? 'Title required'
                                    : null),
                                CommonUtils.buildTextFormField(_timeController, 'Time Required in minutes', themeBundle.textStyle, themeBundle.secondaryColor, true, (v) {
                                  final parsed = int.tryParse(v?.trim() ?? '');
                                  if (parsed == null || parsed < 1) {
                                    return 'Please enter a valid whole number';
                                  }
                                  minutesRequired = parsed;
                                  return null;
                                }, ),
                                CommonUtils.buildTextFormField(_deadlineController, 'Hours to complete (optional)', themeBundle.textStyle, themeBundle.secondaryColor, true, (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final parsed = int.tryParse(v);
                                  if (parsed == null || parsed <= 0 || parsed > 9999) {
                                    return 'Must be a whole number > 0 and < 10000';
                                  }
                                  minutesToDeadline = parsed * 60;
                                  if (minutesRequired > minutesToDeadline) {
                                    return 'Deadline must be greater than time required.';
                                  }
                                  return null;
                                },),
                                CommonUtils.buildTextFormField(_stepsController, 'Steps (Required)', themeBundle.textStyle, themeBundle.secondaryColor, true, (v) {
                                  final trimmed = v?.trim();
                                  final parsed = int.tryParse(trimmed?.isEmpty ?? true ? '1' : trimmed!);
                                  if (parsed == null || parsed < 1) {
                                    return 'Please enter a valid whole number above 0';
                                  }
                                  return null;
                                },),
                                const SizedBox(height: 10),
                                CommonUtils.buildElevatedButton('Add Goal', themeBundle.primaryColor, themeBundle.secondaryColor, themeBundle.textStyle, 5, 5, _createGoal),
                                CommonUtils.buildElevatedButton('Clear Active Goals', themeBundle.primaryColor, themeBundle.secondaryColor, themeBundle.textStyle, 5, 5, _clearGoals),
                                CommonUtils.buildElevatedButton('Clear Completed Goals', themeBundle.primaryColor, themeBundle.secondaryColor, themeBundle.textStyle, 5, 5, _clearCompleteGoals),
                                CommonUtils.buildElevatedButton('Manage Multi-templates', themeBundle.primaryColor, themeBundle.secondaryColor, themeBundle.textStyle, 5, 5, _openMultiTemplateManager),
                                CommonUtils.buildElevatedButton('Manage Templates', themeBundle.primaryColor, themeBundle.secondaryColor, themeBundle.textStyle, 5, 5, _openTemplateManager),
                                ConfettiWidget(
                                  confettiController: _confettiController,
                                  blastDirectionality: BlastDirectionality.explosive,
                                  shouldLoop: false),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Sort and Filter Controls
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CommonUtils.buildDropdownButton(_selectedCategoryFilter, ['All', ..._categories], themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _selectedCategoryFilter = val ?? 'All'), displayText: (v) => 'Category: $v',),
                              CommonUtils.buildDropdownButton(_selectedComplexityFilter, ['All', ..._levels], themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _selectedComplexityFilter = val ?? 'All'), displayText: (v) => 'Complexity: $v',),
                              CommonUtils.buildDropdownButton(_selectedStatusFilter, ['Active', 'Completed'], themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _selectedStatusFilter = val ?? 'Active'), displayText: (v) => 'Status: $v',),
                              CommonUtils.buildDropdownButton(_sortBy, [ 'None', 'Title A-Z', 'Title Z-A', 'Time ↑', 'Time ↓', 'Steps ↑', 'Steps ↓', 'Closest deadline',], themeBundle.textStyle, themeBundle.secondaryColor, (val) => setState(() => _sortBy = val ?? 'None'), displayText: (v) => 'Sort: $v',),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 🗂 Filter + Sort Results
                          SizedBox(
                            height: 300,
                            child: ListView.builder(
                              itemCount: _filteredSortedGoals.length,
                              itemBuilder: (_, i) {
                                final g = _filteredSortedGoals[i];
                                final steps = int.tryParse(g['steps']?.toString() ?? '') ?? 1;
                                return ListTile(
                                  titleTextStyle: themeBundle.textStyle,
                                  textColor: themeBundle.primaryColor,
                                  title: Text(g['title']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${g['points']} pts | ${g['category']}',
                                        style: themeBundle.textStyle,
                                      ),
                                      if (_selectedStatusFilter == 'Active' &&
                                          steps > 1)
                                        buildStepDisplay(g, _settings.userFontSize)
                                    ],
                                  ),
                                  onTap: () => _viewGoalDetails(g),
                                  trailing:
                                      _selectedStatusFilter == 'Active'
                                          ? Wrap(
                                            children: [
                                              CommonUtils.buildIconButton('Add Step Progress', Icons.add_circle_outline, themeBundle.primaryColor, () =>
                                                  _incrementStepProgress( _activeGoals.indexOf(g))),
                                              CommonUtils.buildIconButton('Complete Goal', Icons.add_task, themeBundle.primaryColor, () =>
                                                  _completeGoal(_activeGoals.indexOf(g))),
                                              CommonUtils.buildIconButton('Remove Goal', Icons.delete, themeBundle.primaryColor, () => _removeGoal(
                                                _activeGoals.indexOf(g))),
                                            ],
                                          )
                                          : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

Widget buildStepDisplay(Map<String, dynamic> g, double userFontSize) {
  final int totalSteps = int.tryParse(g['steps']?.toString() ?? '1') ?? 1;
  final int currentProgress = (g['stepProgress'] ?? 0).clamp(0, totalSteps);

  if (totalSteps > 10) {
    return Text(
      'Step $currentProgress/$totalSteps',
      style: TextStyle(fontSize: userFontSize),
    );
  }

  return Wrap(
    spacing: 4.0,
    runSpacing: 4.0,
    children: List.generate(
      totalSteps,
          (i) => Icon(
        i < currentProgress ? Icons.check_box : Icons.check_box_outline_blank,
        size: userFontSize,
      ),
    ),
  );
}