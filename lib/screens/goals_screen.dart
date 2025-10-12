// lib/screens/goals_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../utils/BaseState.dart';
import '../models/classes/theme_bundle.dart';
import '../models/classes/goal_set.dart';
import '../utils/common_utils.dart';
import '../utils/notifier.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends BaseState<GoalsScreen> {
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
  final _storage = const FlutterSecureStorage();
  final DateTime _currentDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    DateTime.now().hour
  );
  final DateFormat formatter = DateFormat('dd MMMM yyyy HH:mm');
  Map<String, Map<String, dynamic>> _userTemplates = {};
  Map<String, List<String>> _templateGroups = {};
  late ThemeData _themeData;
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  late ButtonStyle _buttonStyle;
  bool _themeLoaded = false;
  bool _notificationsEnabled = false;
  String _notificationStyle = 'Minimal';
  String _notificationFrequency = 'Low';

  @override
  void initState() {
    super.initState();
    _loadGoalsPage();
  }

  Future<void> loadNotificationStyleAndFrequency() async {
    _notificationsEnabled = getNotificationsEnabled();
    _notificationStyle = await notificationStyle;
    _notificationFrequency = await notificationFrequency;
  }


  Future<void> _loadGoalsPage() async {
    _stepsController.text = '1';
    _templateSteps.text = '1';
    await _loadGoals();
    await _loadTemplates();
    await _loadTemplateGroups();
    await loadNotificationStyleAndFrequency();
    final themeBundle = await initializeScreenTheme();
    await setThemeDataScreen(themeBundle);
  }

  Future<void> setThemeDataScreen (ThemeBundle themeBundle)  async {
    setState(() {
      _themeData = themeBundle.themeData;
      _primaryColor = themeBundle.primaryColor;
      _secondaryColor = themeBundle.secondaryColor;
      _textStyle = themeBundle.textStyle;
      _buttonStyle = themeBundle.buttonStyle;
      _themeLoaded = true;
    });
  }


  Future<int> getTotalAmount(int amount) async {
    final String today = DateFormat('dd MM yyyy').format(DateTime.now());

    final String? stored = await _storage.read(key: 'completedToday');
    int count = 1;

    if (stored != null) {
      final parts = stored.split('|');
      final storedDate = parts[0];
      final storedCount = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      if (storedDate == today) {
        count = storedCount + 1;
      }
    }

    await _storage.write(key: 'completedToday', value: '$today|$count');
    debugPrint('today: $today, count: $count');

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
    final int rounded = ((reward + 4) ~/ 5) * 5;
    return rounded;
  }

  Future<void> _loadTemplates() async {
    final userT = await _storage.read(key: 'userTemplates');
    setState(() {
      _userTemplates =
          userT != null
              ? Map<String, Map<String, dynamic>>.from(json.decode(userT))
              : {};
    });
  }

  Future<void> _saveTemplates() async {
    await _storage.write(
      key: 'userTemplates',
      value: json.encode(_userTemplates),
    );
    setState(() {
    });
  }

  Future<void> _loadGoals() async {
    final active = await _storage.read(key: 'activeGoals');
    final complete = await _storage.read(key: 'completedGoals');
    setState(() {
      _activeGoals =
          active != null
              ? List<Map<String, dynamic>>.from(json.decode(active))
              : [];
      _completedGoals =
          complete != null
              ? List<Map<String, dynamic>>.from(json.decode(complete))
              : [];
    });
    _checkForExpiredGoals();
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
    const int base = 5;

    // Parse inputs
    final int timeVal = int.tryParse(time) ?? 0;
    final int stepsVal = int.tryParse(steps) ?? 0;

    // Score components
    final int complexityScore = CommonUtils.scoreFromLevel(complexity);
    final int effortScore = CommonUtils.scoreFromLevel(effort);
    final int motivationScore = CommonUtils.scoreFromLevel(motivation);
    final int timeScore = CommonUtils.scoreFromTime(timeVal);
    final int stepScore = CommonUtils.scoreFromSteps(stepsVal);
    final int deadlineBonus = (deadline.isNotEmpty && deadline != 'no deadline') ? 2 : 0;

    // Additive multiplier
    final int additive = 1 + complexityScore + effortScore + motivationScore + timeScore + stepScore + deadlineBonus;
    int rawScore = base * additive;

    // Final multiplier based on "high" levels
    final List<String> levels = [complexity, effort, motivation];
    final int highCount = levels.where((l) => l.toLowerCase() == 'high').length;

    double multiplier = switch (highCount) {
      3 => 2.0,
      2 => 1.5,
      1 => 1.25,
      _ => 1.0,
    };

    // Apply multiplier and round up to nearest 5
    final double adjusted = rawScore * multiplier;
    final int rounded = ((adjusted + 4) ~/ 5) * 5;

    return rounded;
  }



  Future<void> _saveGoals() async {
    await _storage.write(key: 'activeGoals', value: json.encode(_activeGoals));
    await _storage.write(
      key: 'completedGoals',
      value: json.encode(_completedGoals),
    );
  }

  Future<void> _addPoints(int amount, String source) async {
    final points = await _storage.read(key: 'points');
    final value = int.tryParse(points ?? '50') ?? 50;
    final totalAmount = await getTotalAmount(amount);


    await _storage.write(key: 'points', value: (value + totalAmount).toString());
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

      if (_notificationsEnabled && hours > 0) {
        final goalSet = GoalSet.fromMap(goal);
        GoalNotifier.startGoalCheck(goalSet, _notificationStyle, _notificationFrequency, hours);
      } else {
        debugPrint('Notifications not enabled — skipping goal check scheduling');
      }
      _resetControllers();
    }
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
    final goalId = generateGoalId(title);
    final int hours = int.tryParse(deadlineHours) ?? 0;
    final String deadline = deadlineHours.isEmpty
        ? 'no deadline'
        : formatter.format(_currentDate.add(Duration(hours: hours)));
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

    if (_notificationsEnabled && hours > 0) {
      final goalSet = GoalSet.fromMap(goal);
      GoalNotifier.startGoalCheck(goalSet, _notificationStyle, _notificationFrequency, hours);
    } else {
      debugPrint('Notifications not enabled — skipping goal check scheduling');
    }
  }


  void _completeGoal(int index) {
    final goal = _activeGoals.removeAt(index);
    final goalSet = GoalSet.fromMap(goal);
    GoalNotifier.cancelGoalNotification(goalSet); // Cancel notifications
    _completedGoals.add(goal);
    _addPoints(goal['points'], 'goal:${goal['title']}');
    _saveGoals();
    setState(() {});
  }

  void _removeGoal(int index) {
    final goal = _activeGoals[index];
    final goalSet = GoalSet.fromMap(goal);
    GoalNotifier.cancelGoalNotification(goalSet); // Cancel notifications
    setState(() {
      _activeGoals.removeAt(index);
    });
    _saveGoals();
  }

  void _removeGoalWithoutRemovingNotifications(int index) {
    final goal = _activeGoals[index];
    setState(() {
      _activeGoals.removeAt(index);
    });
    _saveGoals();
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

  void _viewGoalDetails(Map<String, dynamic> goal) {
    showDialog(
      context: context,
      barrierColor: _secondaryColor, // ✅ Sets overlay color
      builder:
          (_) => AlertDialog(
            backgroundColor: _secondaryColor,
            iconColor: _primaryColor,
            title: Text(goal['title'], style: _textStyle),
            content: Container(
              color: _secondaryColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category: ${goal['category']}', style: _textStyle),
                  Text('Complexity: ${goal['complexity']}', style: _textStyle),
                  Text('Effort: ${goal['effort']}', style: _textStyle),
                  Text('Motivation: ${goal['motivation']}', style: _textStyle),
                  Text('Time Needed in minutes: ${goal['time']}', style: _textStyle),
                  Text('Deadline: ${goal['Deadline']}', style: _textStyle),
                  Text('Steps: ${goal['steps']}', style: _textStyle),
                  Text('Points: ${goal['points']}', style: _textStyle),
                  Text('Id: ${goal['Id']}', style: _textStyle),
                ],
              ),
            ),
            actions: [
              Container(
                color: _secondaryColor,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: _textStyle,
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
          backgroundColor: _secondaryColor,
          title: Text('Manage Templates', style: _textStyle),
          content: SingleChildScrollView(
            child: Container(
              color: _secondaryColor,
              child: Form(
                key: templateFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _templateName,
                      style: _textStyle,
                      decoration: InputDecoration(
                        labelText: 'Template Name (required)',
                        labelStyle: _textStyle,
                        filled: true,
                        fillColor: _secondaryColor,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Template name is required';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField(
                      dropdownColor: _secondaryColor,
                      value: templateCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: _textStyle,
                      ),
                      items: _categories
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: _textStyle,
                      onChanged: (v) => setState(() => templateCategory = v!),
                    ),
                    DropdownButtonFormField(
                      dropdownColor: _secondaryColor,
                      value: templateComplexity,
                      decoration: InputDecoration(
                        labelText: 'Complexity',
                        labelStyle: _textStyle,
                      ),
                      items: _levels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: _textStyle,
                      onChanged: (v) => setState(() => templateComplexity = v!),
                    ),
                    DropdownButtonFormField(
                      dropdownColor: _secondaryColor,
                      value: templateEffort,
                      decoration: InputDecoration(
                        labelText: 'Effort',
                        labelStyle: _textStyle,
                      ),
                      items: _levels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: _textStyle,
                      onChanged: (v) => setState(() => templateEffort = v!),
                    ),
                    DropdownButtonFormField(
                      dropdownColor: _secondaryColor,
                      value: templateMotivation,
                      decoration: InputDecoration(
                        labelText: 'Motivation',
                        labelStyle: _textStyle,
                      ),
                      items: _levels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: _textStyle,
                      onChanged: (v) => setState(() => templateMotivation = v!),
                    ),
                    TextFormField(
                      style: _textStyle,
                      controller: _templateTime,
                      decoration: InputDecoration(
                        labelText: 'Time (minutes, required)',
                        labelStyle: _textStyle,
                      ),
                      validator: (v) {
                        final parsed = int.tryParse(v?.trim() ?? '');
                        if (parsed == null || parsed < 1 || parsed > 999) {
                          return 'Please enter a valid number greater than 0 and smaller than 1000';
                        }
                        minutesRequired = parsed;
                        return null;
                      },
                    ),
                    TextFormField(
                      style: _textStyle,
                      controller: _templateDeadline,
                      decoration: InputDecoration(
                        labelText: 'Hours to complete (optional)',
                        labelStyle: _textStyle,
                      ),
                      validator: (v) {
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
                      },
                    ),
                    TextFormField(
                      style: _textStyle,
                      controller: _templateSteps,
                      decoration: InputDecoration(
                        labelText: 'Steps',
                        labelStyle: _textStyle,
                      ),
                      validator: (v) {
                        final trimmed = v?.trim();
                        final parsed = int.tryParse(trimmed?.isEmpty ?? true ? '1' : trimmed!);
                        if (parsed == null || parsed < 1 || parsed > 999) {
                          return 'Please enter a valid whole number above 0 and smaller than 1000';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor,
                        foregroundColor: _primaryColor,
                      ),
                      child: Text('Save Template', style:_textStyle),
                    ),
                    const Divider(),
                    Text('Templates:', style: _textStyle),
                    ...[
                      ..._templateDetails.keys,
                      ..._userTemplates.keys,
                    ].map(
                          (name) => ListTile(
                        title: Text(name),
                        titleTextStyle: _textStyle,
                        trailing: _userTemplates.containsKey(name)
                            ? IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _userTemplates.remove(name);
                              _saveTemplates();
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
              child: Text('Close', style: _textStyle),
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
    await _storage.write(
      key: 'templateGroups',
      value: json.encode(_templateGroups),
    );
  }

  Future<void> _loadTemplateGroups() async {
    final saved = await _storage.read(key: 'templateGroups');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _templateGroups = Map<String, List<String>>.from(
          (json.decode(saved) as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, List<String>.from(v)),
          ),
        );
      });
    }
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
            backgroundColor: _secondaryColor,
            title: Text('Select Multiple Templates', style: _textStyle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedGroup,
                    hint: Text('Load Saved Group', style: _textStyle),
                    dropdownColor: _secondaryColor,
                    items: _templateGroups.keys.map((groupName) {
                      return DropdownMenuItem(
                        value: groupName,
                        child: Text(groupName, style: _textStyle),
                      );
                    }).toList(),
                    onChanged: (groupName) {
                      setState(() {
                        selectedGroup = groupName;
                        selectedTemplates = List.from(_templateGroups[groupName!] ?? []);
                        groupNameController.text = groupName; // auto-fill name when loading group
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: groupNameController,
                    style: _textStyle,
                    decoration: InputDecoration(
                      labelText: 'Group Name (required to save/update)',
                      labelStyle: _textStyle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Select Templates to Create Goals:', style: _textStyle),
                  ...[..._templateDetails.keys, ..._userTemplates.keys].map((templateName) {
                    final selected = selectedTemplates.contains(templateName);
                    return CheckboxListTile(
                      title: Text(templateName, style: _textStyle),
                      value: selected,
                      activeColor: _primaryColor,
                      checkColor: _secondaryColor,
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
                  Text('Existing Groups:', style: _textStyle),
                  ..._templateGroups.keys.map((name) {
                    return ListTile(
                      title: Text(name, style: _textStyle),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        color: _primaryColor,
                        onPressed: () {
                          setState(() {
                            _templateGroups.remove(name);
                          });
                          _saveTemplateGroups();
                        },
                      ),
                      onTap: () {
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: _textStyle),
              ),
              TextButton(
                onPressed: () {
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
                  Navigator.of(context).pop(); // close dialog
                  },
                  child: Text('Save/Update Group', style: _textStyle),
                ),
                if (validationMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      validationMessage!,
                      style: _textStyle.copyWith(color: Colors.red),
                    ),
                  ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _secondaryColor,
                  foregroundColor: _primaryColor,
                ),
                onPressed: () async {
                  if (selectedTemplates.isEmpty) return;
                  for (final templateName in selectedTemplates) {
                    final data = _templateDetails[templateName] ?? _userTemplates[templateName]!;
                    await _createGoalFromTemplates(
                    title: templateName,
                    category: data['category'],
                    complexity: data['complexity'],
                    effort: data['effort'],
                    motivation: data['motivation'],
                    time: data['time'],
                    steps: data['steps'],
                    deadlineHours: data['Hours to complete'],
                    );
                  }
                  Navigator.pop(context);
                },
                child: Text('Create Goals', style: _textStyle),
              ),
            ],
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {

    if (!_themeLoaded) {
      // show placeholder while theme loads
      return const Center(child: CircularProgressIndicator());
    }

    int minutesRequired = 0;
    int minutesToDeadline = 0;

    return Theme(
      data: _themeData,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            'Goals',
            style: TextStyle(
              backgroundColor: _secondaryColor,
              color: _primaryColor,
            ),
          ),
          backgroundColor: _secondaryColor,
          iconTheme: IconThemeData(color: _primaryColor),
        ),
        backgroundColor: _secondaryColor,
        body: Container(
          // SafeArea - Container
          color: _secondaryColor,
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
                                DropdownButtonFormField<String>(
                                  dropdownColor: _secondaryColor,
                                  isExpanded: true,
                                  hint: Text(
                                    'Template (optional)',
                                    style: _textStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  items:
                                      [
                                            ..._templateDetails.keys,
                                            ..._userTemplates.keys,
                                          ]
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                e,
                                                style: _textStyle,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    _titleController.text = val;
                                    final data =
                                        _templateDetails[val] ??
                                        _userTemplates[val]!;
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
                                  },
                                ),
                                DropdownButtonFormField(
                                  dropdownColor: _secondaryColor,
                                  value: _category,
                                  items:
                                  _categories
                                      .map(
                                        (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e, style: _textStyle),
                                    ),
                                  )
                                      .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _category= val ?? 'Productivity',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    labelStyle: _textStyle,
                                  ),
                                ),
                                DropdownButtonFormField(
                                  dropdownColor: _secondaryColor,
                                  value: _complexity,
                                  items:
                                      _levels
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e, style: _textStyle),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _complexity = val ?? 'Low',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Complexity',
                                    labelStyle: _textStyle,
                                  ),
                                ),
                                DropdownButtonFormField(
                                  dropdownColor: _secondaryColor,
                                  value: _effort,
                                  items:
                                      _levels
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e, style: _textStyle),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _effort = val ?? 'Low',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Effort Required',
                                    labelStyle: _textStyle,
                                  ),
                                ),
                                DropdownButtonFormField(
                                  dropdownColor: _secondaryColor,
                                  value: _motivation,
                                  items:
                                      _levels
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e, style: _textStyle),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _motivation = val ?? 'Low',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Motivation Needed',
                                    labelStyle: _textStyle,
                                  ),
                                ),
                                TextFormField(
                                  style: _textStyle,
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    labelText: 'Goal Title',
                                    labelStyle: _textStyle,
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Title required'
                                              : null,
                                ),
                                TextFormField(
                                  style: _textStyle,
                                  controller: _timeController,
                                  decoration: InputDecoration(
                                    labelText: 'Time Required in minutes',
                                    labelStyle: _textStyle,
                                  ),
                                  validator: (v) {
                                    final parsed = int.tryParse(v?.trim() ?? '');
                                    if (parsed == null || parsed < 1) {
                                      return 'Please enter a valid whole number';
                                    }
                                    minutesRequired = parsed;
                                    return null; // ✅ Valid input
                                  },
                                ),
                                TextFormField(
                                  style: _textStyle,
                                  controller: _deadlineController,
                                  decoration: InputDecoration(
                                    labelText: 'Hours to complete (optional)',
                                    labelStyle: _textStyle,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return null; // ✅ Accepts no deadline
                                    final parsed = int.tryParse(v);
                                    if (parsed == null || parsed <= 0 || parsed > 9999) {
                                      return 'Must be a whole number > 0 and < 10000';
                                    }
                                    minutesToDeadline = parsed * 60;
                                    if (minutesRequired > minutesToDeadline) {
                                      return 'Deadline must be greater than time required.';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  style: _textStyle,
                                  controller: _stepsController,
                                  decoration: InputDecoration(
                                    labelText: 'Steps',
                                    labelStyle: _textStyle,
                                  ),
                                  validator: (v) {
                                    final trimmed = v?.trim();
                                    final parsed = int.tryParse(trimmed?.isEmpty ?? true ? '1' : trimmed!);
                                    if (parsed == null || parsed < 1) {
                                      return 'Please enter a valid whole number above 0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: _buttonStyle,
                                  onPressed: _createGoal,
                                  child: Text('Add Goal', style: _textStyle),
                                ),
                                ElevatedButton(
                                  style: _buttonStyle,
                                  onPressed: _clearGoals,
                                  child: Text('Clear Active Goals', style: _textStyle),
                                ),
                                ElevatedButton(
                                  style: _buttonStyle,
                                  onPressed: _clearCompleteGoals,
                                  child: Text('Clear Completed Goals', style: _textStyle),
                                ),
                                ElevatedButton(
                                  style: _buttonStyle,
                                  onPressed: _openMultiTemplateManager,
                                  child: Text('Manage Multi-templates', style: _textStyle),
                                ),
                                ElevatedButton(
                                  style: _buttonStyle,
                                  onPressed: _openTemplateManager,
                                  child: Text('Manage Templates', style: _textStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 🔎 Sort and Filter Controls
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              DropdownButton<String>(
                                dropdownColor: _secondaryColor,
                                isExpanded: true,
                                value: _selectedCategoryFilter,
                                onChanged:
                                    (val) => setState(
                                      () =>
                                          _selectedCategoryFilter =
                                              val ?? 'All',
                                    ),
                                items:
                                    ['All', ..._categories]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              'Category: $e',
                                              style: _textStyle,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              DropdownButton<String>(
                                dropdownColor: _secondaryColor,
                                isExpanded: true,
                                value: _selectedComplexityFilter,
                                onChanged:
                                    (val) => setState(
                                      () =>
                                          _selectedComplexityFilter =
                                              val ?? 'All',
                                    ),
                                items:
                                    ['All', ..._levels]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              'Complexity: $e',
                                              style: _textStyle,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              DropdownButton<String>(
                                dropdownColor: _secondaryColor,
                                value: _selectedStatusFilter,
                                onChanged:
                                    (val) => setState(
                                      () =>
                                          _selectedStatusFilter =
                                              val ?? 'Active',
                                    ),
                                items:
                                    ['Active', 'Completed']
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              'Status: $e',
                                              style: _textStyle,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              DropdownButton<String>(
                                dropdownColor: _secondaryColor,
                                value: _sortBy,
                                onChanged:
                                    (val) =>
                                        setState(() => _sortBy = val ?? 'None'),
                                items:
                                    [
                                          'None',
                                          'Title A-Z',
                                          'Title Z-A',
                                          'Time ↑',
                                          'Time ↓',
                                          'Steps ↑',
                                          'Steps ↓',
                                          'Closest deadline',
                                        ]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              'Sort: $e',
                                              style: _textStyle,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
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
                                  titleTextStyle: _textStyle,
                                  textColor: _primaryColor,
                                  title: Text(g['title']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${g['points']} pts | ${g['category']}',
                                        style: _textStyle,
                                      ),
                                      if (_selectedStatusFilter == 'Active' &&
                                          steps > 1)
                                        buildStepDisplay(g, userFontSize)
                                    ],
                                  ),
                                  onTap: () => _viewGoalDetails(g),
                                  trailing:
                                      _selectedStatusFilter == 'Active'
                                          ? Wrap(
                                            children: [
                                              IconButton(
                                                color: _primaryColor,
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                ),
                                                onPressed:
                                                    () =>
                                                        _incrementStepProgress(
                                                          _activeGoals.indexOf(
                                                            g,
                                                          ),
                                                        ),
                                                tooltip: 'Add Step Progress',
                                              ),
                                              IconButton(
                                                color: _primaryColor,
                                                icon: const Icon(
                                                  Icons.add_task,
                                                ),
                                                onPressed:
                                                    () =>
                                                    _completeGoal(
                                                      _activeGoals.indexOf(
                                                        g,
                                                      ),
                                                    ),
                                                tooltip: 'Complete Goal',
                                              ),
                                              IconButton(
                                                color: _primaryColor,
                                                icon: const Icon(Icons.delete),
                                                onPressed:
                                                    () => _removeGoal(
                                                      _activeGoals.indexOf(g),
                                                    ),
                                                tooltip: 'Remove Goal',
                                              ),
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

