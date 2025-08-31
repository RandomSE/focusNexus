// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../utils/BaseState.dart';
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
  final DateFormat formatter = DateFormat('dd HH:mm MMMM yyyy');
  Map<String, Map<String, dynamic>> _userTemplates = {};
  late ThemeData _themeData;
  Map<String, List<String>> _templateGroups = {};
  late Color _primaryColor;
  late Color _secondaryColor;
  late TextStyle _textStyle;
  late ButtonStyle _buttonStyle;
  bool _themeLoaded = false;
  bool _notificationsEnabled = false;
  String _notificationStyle = 'Minimal';

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadNotificationStyle() async {
    _notificationStyle = await getNotificationStyle();
    debugPrint('AT THIS TIME: $_notificationStyle');
  }

  Future<void> loadSettings() async {
    await _loadGoals();
    await _loadTemplates();
    await _loadTemplateGroups();
    _themeData = ThemeData.light();
    await _initializeTheme(); // async theme setup from storage
    await loadNotificationStyle();
  }


  Future<int> getTotalAmount(int amount) async {
    final String today = DateFormat('dd MM yyyy').format(DateTime.now());

    // Read stored value
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

    // Save updated value
    await _storage.write(key: 'completedToday', value: '$today|$count');
    debugPrint('today: $today, count: $count');

    // Apply reward logic
    if (count == 1) return amount * 2 + 100;
    if (count >= 2 && count <= 5) return (amount * 1.5).round() + 20;
    if (count >= 6 && count <= 10) return (amount * 1.25).round() + 5;
    return amount;
  }

  Future<void> _initializeTheme() async {
    ThemeData loadedTheme;

    final String? storedTheme = await _storage.read(key: 'themeData');
    await Future.delayed(const Duration(seconds: 1));
    if (storedTheme != null) {
      loadedTheme = parseThemeData(storedTheme);
    } else {
      loadedTheme = await setAndGetThemeData(
        isDark: userTheme == 'dark',
        highContrastMode: highContrastMode,
        userFontSize: userFontSize,
        useDyslexiaFont: useDyslexiaFont,
      );
    }

    if (mounted) {
      setState(() {
        _themeData      = loadedTheme;
        _primaryColor   = loadedTheme.primaryColor;
        _secondaryColor = loadedTheme.scaffoldBackgroundColor;
        _textStyle      = loadedTheme.textTheme.bodyMedium!;
        _buttonStyle    = ElevatedButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: _primaryColor,
        );
        _themeLoaded = true;
      });
    }
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
      _removeGoal(0);
    }
  }

  void _clearCompleteGoals () {
    while (_completedGoals.isNotEmpty) {
      _removeCompletedGoal(0);
    }
  }

  int _calculatePoints() {
    const int base = 5;

    int complexityWeight = (_complexity == 'Medium') ? 1 : (_complexity == 'High') ? 2 : 0;
    int effortWeight     = (_effort == 'Medium')     ? 1 : (_effort == 'High')     ? 2 : 0;
    int motivationWeight = (_motivation == 'Medium') ? 1 : (_motivation == 'High') ? 2 : 0;

    int time = int.tryParse(_time) ?? 0;
    int timeBonus = (time > 15) ? ((time - 15) ~/ 5) : 0;
    timeBonus = timeBonus.clamp(0, 4);

    int steps = int.tryParse(_steps) ?? 1;
    int stepMultiplier = (steps > 1) ? (steps - 1) : 1;
    stepMultiplier = stepMultiplier.clamp(1, 4);

    int totalMultiplier = 1 + complexityWeight + effortWeight + motivationWeight + timeBonus + stepMultiplier;

    return base * totalMultiplier;
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

  Future<void> _createGoal() async {
    if (_formKey.currentState!.validate()) {
      final String deadlineHours = _deadlineController.text.trim();
      String deadline;
      if (deadlineHours.isEmpty) {
        deadline = 'no deadline';
      } else {
        _notificationsEnabled = getNotificationsEnabled(); // Put here to check every time a goal is made that it checks.
        loadNotificationStyle();
        final int hours = int.tryParse(deadlineHours) ?? 0;
        final DateTime deadlineDate = _currentDate.add(Duration(hours: hours));
        deadline = formatter.format(deadlineDate);
        if (_notificationsEnabled) {
          GoalNotifier.startGoalCheck(_titleController.text, hours, _notificationStyle);
        }
        else {
          debugPrint('Notifications not enabled — skipping goal check scheduling');
        }
      }

    final goal = {
        'title': _titleController.text,
        'category': _category,
        'complexity': _complexity,
        'effort': _effort,
        'motivation': _motivation,
        'time': _timeController.text,
        'Deadline': deadline,
        'steps': _stepsController.text,
        'points': _calculatePoints(),
        'stepProgress': 0,
      };
      setState(() {
        _activeGoals.add(goal);
      });
      _saveGoals();
      _titleController.clear();
      _timeController.clear();
      _deadlineController.clear();
      _stepsController.clear();
    }
  }

  void _incrementStepProgress(int index) {
    final goal = _activeGoals[index];
    final max = int.tryParse(goal['steps']) ?? 1;
    if (goal['stepProgress'] < max) {
      setState(() {
        goal['stepProgress']++;
      });
      if (goal['stepProgress'] >= max) _completeGoal(index);
      _saveGoals();
    }
  }

  void _completeGoal(int index) {
    final goal = _activeGoals.removeAt(index);
    GoalNotifier.cancelGoalNotification(goal['title']); // Cancel notifications
    _completedGoals.add(goal);
    _addPoints(goal['points'], 'goal:${goal['title']}');
    _saveGoals();
    setState(() {});
  }

  void _removeGoal(int index) {
    final goal = _activeGoals[index];
    GoalNotifier.cancelGoalNotification(goal['title']); // Cancel notifications
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
    final DateFormat format = formatter;
    final DateTime today = DateTime.now();

    // Reverse index scan to safely remove while iterating
    for (int i = _activeGoals.length - 1; i >= 0; i--) {
      final goal = _activeGoals[i];
      final deadlineStr = goal['Deadline'];
      if (deadlineStr == null || deadlineStr.toString().trim().isEmpty) continue;

      try {
        final parsed = format.parseStrict(deadlineStr);
        if (!parsed.isAfter(today)) {
          _removeGoal(i); // ✅ Remove expired goal
        }
      } catch (_) {
        // Invalid date format, skip
      }
    }
  }

  void _viewGoalDetails(Map<String, dynamic> goal) {
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(userFontSize, primaryColor, useDyslexiaFont);

    showDialog(
      context: context,
      barrierColor: secondaryColor, // ✅ Sets overlay color
      builder:
          (_) => AlertDialog(
            backgroundColor: secondaryColor,
            // ✅ Applies secondaryColor to dialog background
            iconColor: primaryColor,
            // ✅ Ensures icons respect primaryColor
            title: Text(goal['title'], style: textStyle),
            // ✅ Sets title text color
            content: Container(
              color: secondaryColor,
              // ✅ Wraps content in secondaryColor to ensure correct background
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category: ${goal['category']}', style: textStyle),
                  Text('Complexity: ${goal['complexity']}', style: textStyle),
                  Text('Effort: ${goal['effort']}', style: textStyle),
                  Text('Motivation: ${goal['motivation']}', style: textStyle),
                  Text('Time Needed in minutes: ${goal['time']}', style: textStyle),
                  Text('Deadline: ${goal['Deadline']}', style: textStyle),
                  Text('Steps: ${goal['steps']}', style: textStyle),
                  Text('Points: ${goal['points']}', style: textStyle),
                ],
              ),
            ),
            actions: [
              Container(
                color: secondaryColor,
                // ✅ Ensures button area follows background color
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: textStyle,
                  ), // ✅ Applies primaryColor to button text
                ),
              ),
            ],
          ),
    );
  }

  // ✅ Enhanced Template Manager: full field editing support for base and custom templates
  void _openTemplateManager() {
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(userFontSize, primaryColor, useDyslexiaFont);

    final TextEditingController _templateName = TextEditingController();
    final TextEditingController _templateTime = TextEditingController();
    final TextEditingController _templateSteps = TextEditingController();
    final TextEditingController _templateDeadline = TextEditingController();

    String _templateCategory = _categories.first;
    String _templateComplexity = _levels.first;
    String _templateEffort = _levels.first;
    String _templateMotivation = _levels.first;

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: secondaryColor,
          title: Text('Manage Templates', style: textStyle),
          content: SingleChildScrollView(
            child: Container(
              color: secondaryColor,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _templateName,
                      style: textStyle,
                      decoration: InputDecoration(
                        labelText: 'Template Name (required)',
                        labelStyle: textStyle,
                        filled: true,
                        fillColor: secondaryColor,
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
                      dropdownColor: secondaryColor,
                      value: _templateCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: textStyle,
                      ),
                      items: _categories
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: textStyle,
                      onChanged: (v) => setState(() => _templateCategory = v!),
                    ),
                    DropdownButtonFormField(
                      dropdownColor: secondaryColor,
                      value: _templateComplexity,
                      decoration: InputDecoration(
                        labelText: 'Complexity',
                        labelStyle: textStyle,
                      ),
                      items: _levels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: textStyle,
                      onChanged: (v) => setState(() => _templateComplexity = v!),
                    ),
                    DropdownButtonFormField(
                      dropdownColor: secondaryColor,
                      value: _templateEffort,
                      decoration: InputDecoration(
                        labelText: 'Effort',
                        labelStyle: textStyle,
                      ),
                      items: _levels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: textStyle,
                      onChanged: (v) => setState(() => _templateEffort = v!),
                    ),
                    DropdownButtonFormField(
                      dropdownColor: secondaryColor,
                      value: _templateMotivation,
                      decoration: InputDecoration(
                        labelText: 'Motivation',
                        labelStyle: textStyle,
                      ),
                      items: _levels
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      style: textStyle,
                      onChanged: (v) => setState(() => _templateMotivation = v!),
                    ),
                    TextFormField(
                      style: textStyle,
                      controller: _templateTime,
                      decoration: InputDecoration(
                        labelText: 'Time (minutes, required)',
                        labelStyle: textStyle,
                      ),
                      validator: (v) {
                        final parsed = int.tryParse(v?.trim() ?? '');
                        if (parsed == null || parsed < 1) {
                          return 'Please enter a valid number greater than 0';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      style: textStyle,
                      controller: _templateDeadline,
                      decoration: InputDecoration(
                        labelText: 'Hours to complete (optional)',
                        labelStyle: textStyle,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null; // optional
                        final parsed = int.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Must be a whole number greater than 0';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      style: textStyle,
                      controller: _templateSteps,
                      decoration: InputDecoration(
                        labelText: 'Steps (required)',
                        labelStyle: textStyle,
                      ),
                      validator: (v) {
                        final parsed = int.tryParse(v?.trim() ?? '');
                        if (parsed == null || parsed < 1) {
                          return 'Please enter a valid number greater than 0';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return; // stop if validation fails
                        }

                        final name = _templateName.text.trim();
                        final data = {
                          'category': _templateCategory,
                          'complexity': _templateComplexity,
                          'effort': _templateEffort,
                          'motivation': _templateMotivation,
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
                        _templateSteps.clear();
                        _templateDeadline.clear();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: primaryColor,
                      ),
                      child: const Text('Save Template'),
                    ),
                    const Divider(),
                    Text('Templates:', style: textStyle),
                    ...[
                      ..._templateDetails.keys,
                      ..._userTemplates.keys,
                    ].map(
                          (name) => ListTile(
                        title: Text(name),
                        titleTextStyle: textStyle,
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
                            _templateCategory = t['category'];
                            _templateComplexity = t['complexity'];
                            _templateEffort = t['effort'];
                            _templateMotivation = t['motivation'];
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
              child: Text('Close', style: textStyle),
            ),
          ],
        ),
      ),
    );
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
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(userFontSize, primaryColor, useDyslexiaFont);

    final TextEditingController _groupNameController = TextEditingController();
    List<String> _selectedTemplates = [];
    String? _selectedGroup;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: secondaryColor,
            title: Text('Select Multiple Templates', style: textStyle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _selectedGroup,
                    hint: Text('Load Saved Group', style: textStyle),
                    dropdownColor: secondaryColor,
                    items: _templateGroups.keys.map((groupName) {
                      return DropdownMenuItem(
                        value: groupName,
                        child: Text(groupName, style: textStyle),
                      );
                    }).toList(),
                    onChanged: (groupName) {
                      setState(() {
                        _selectedGroup = groupName;
                        _selectedTemplates = List.from(_templateGroups[groupName!] ?? []);
                        _groupNameController.text = groupName; // auto-fill name when loading group
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _groupNameController,
                    style: textStyle,
                    decoration: InputDecoration(
                      labelText: 'Group Name (required to save/update)',
                      labelStyle: textStyle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Select Templates to Create Goals:', style: textStyle),
                  ...[..._templateDetails.keys, ..._userTemplates.keys].map((templateName) {
                    final selected = _selectedTemplates.contains(templateName);
                    return CheckboxListTile(
                      title: Text(templateName, style: textStyle),
                      value: selected,
                      activeColor: primaryColor,
                      checkColor: secondaryColor,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedTemplates.add(templateName);
                          } else {
                            _selectedTemplates.remove(templateName);
                          }
                        });
                      },
                    );
                  }).toList(),
                  const Divider(),
                  Text('Existing Groups:', style: textStyle),
                  ..._templateGroups.keys.map((name) {
                    return ListTile(
                      title: Text(name, style: textStyle),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        color: primaryColor,
                        onPressed: () {
                          setState(() {
                            _templateGroups.remove(name);
                          });
                          _saveTemplateGroups();
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedGroup = name;
                          _selectedTemplates = List.from(_templateGroups[name]!);
                          _groupNameController.text = name; // auto-fill name when selecting existing group
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
                child: Text('Cancel', style: textStyle),
              ),
              TextButton(
                onPressed: () {
                  final groupName = _groupNameController.text.trim();
                  if (groupName.isEmpty || _selectedTemplates.isEmpty) return;
                  setState(() {
                    _templateGroups[groupName] = List.from(_selectedTemplates);
                  });
                  _saveTemplateGroups();
                },
                child: Text('Save/Update Group', style: textStyle),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: primaryColor,
                ),
                onPressed: () {
                  if (_selectedTemplates.isEmpty) return;
                  for (final templateName in _selectedTemplates) {
                    final data = _templateDetails[templateName] ?? _userTemplates[templateName]!;
                    _titleController.text = templateName;
                    _category = data['category'];
                    _complexity = data['complexity'];
                    _effort = data['effort'];
                    _time = data['time'];
                    _steps = data['steps'];
                    _motivation = data['motivation'];
                    _timeController.text = data['time'];
                    _deadlineController.text = data['Hours to complete'];
                    _stepsController.text = data['steps'];
                    _createGoal();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Create Goals'),
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

    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(userFontSize, primaryColor, useDyslexiaFont);
    final ButtonStyle buttonStyle = _buttonStyle;

    return Theme(
      data: _themeData,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            'Goals',
            style: TextStyle(
              backgroundColor: secondaryColor,
              color: primaryColor,
            ),
          ),
          backgroundColor: secondaryColor,
          iconTheme: IconThemeData(color: primaryColor),
        ),
        backgroundColor: secondaryColor,
        body: Container(
          // SafeArea - Container
          color: secondaryColor,
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
                                  dropdownColor: secondaryColor,
                                  isExpanded: true,
                                  hint: Text(
                                    'Template (optional)',
                                    style: textStyle,
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
                                                style: textStyle,
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
                                  dropdownColor: secondaryColor,
                                  value: _category,
                                  items:
                                  _categories
                                      .map(
                                        (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e, style: textStyle),
                                    ),
                                  )
                                      .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _category= val ?? 'Productivity',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    labelStyle: textStyle,
                                  ),
                                ),
                                DropdownButtonFormField(
                                  dropdownColor: secondaryColor,
                                  value: _complexity,
                                  items:
                                      _levels
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e, style: textStyle),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _complexity = val ?? 'Low',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Complexity',
                                    labelStyle: textStyle,
                                  ),
                                ),
                                DropdownButtonFormField(
                                  dropdownColor: secondaryColor,
                                  value: _effort,
                                  items:
                                      _levels
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e, style: textStyle),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _effort = val ?? 'Low',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Effort Required',
                                    labelStyle: textStyle,
                                  ),
                                ),
                                DropdownButtonFormField(
                                  dropdownColor: secondaryColor,
                                  value: _motivation,
                                  items:
                                      _levels
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e, style: textStyle),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) => setState(
                                        () => _motivation = val ?? 'Low',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Motivation Needed',
                                    labelStyle: textStyle,
                                  ),
                                ),
                                TextFormField(
                                  style: textStyle,
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    labelText: 'Goal Title',
                                    labelStyle: textStyle,
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Title required'
                                              : null,
                                ),
                                TextFormField(
                                  style: textStyle,
                                  controller: _timeController,
                                  decoration: InputDecoration(
                                    labelText: 'Time Required in minutes',
                                    labelStyle: textStyle,
                                  ),
                                  validator: (v) {
                                    final parsed = int.tryParse(v?.trim() ?? '');
                                    if (parsed == null || parsed < 1) {
                                      return 'Please enter a valid whole number';
                                    }
                                    return null; // ✅ Valid input
                                  },
                                ),
                                TextFormField(
                                  style: textStyle,
                                  controller: _deadlineController,
                                  decoration: InputDecoration(
                                    labelText: 'Hours to complete',
                                    labelStyle: textStyle,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return null; // ✅ Accepts no deadline
                                    final parsed = int.tryParse(v);
                                    if (parsed == null || parsed <= 0) return 'Please enter a whole number larger than 0';
                                    return null; // ✅ Input is a valid number
                                  },
                                ),
                                TextFormField(
                                  style: textStyle,
                                  controller: _stepsController,
                                  decoration: InputDecoration(
                                    labelText: 'Steps',
                                    labelStyle: textStyle,
                                  ),
                                  validator: (v) {
                                    final parsed = int.tryParse(v?.trim() ?? '');
                                    if (parsed == null || parsed < 1) {
                                      return 'Please enter a valid whole number';
                                    }
                                    return null; // ✅ Valid input
                                  },
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: buttonStyle,
                                  onPressed: _createGoal,
                                  child: Text('Add Goal', style: textStyle),
                                ),
                                ElevatedButton(
                                  style: buttonStyle,
                                  onPressed: _clearGoals,
                                  child: Text('Clear Active Goals', style: textStyle),
                                ),
                                ElevatedButton(
                                  style: buttonStyle,
                                  onPressed: _clearCompleteGoals,
                                  child: Text('Clear Completed Goals', style: textStyle),
                                ),
                                ElevatedButton(
                                  style: buttonStyle,
                                  onPressed: _openMultiTemplateManager,
                                  child: Text('Manage Multi-templates', style: textStyle),
                                ),
                                ElevatedButton(
                                  style: buttonStyle,
                                  onPressed: _openTemplateManager,
                                  child: Text('Manage Templates', style: textStyle,
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
                                dropdownColor: secondaryColor,
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
                                              style: textStyle,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              DropdownButton<String>(
                                dropdownColor: secondaryColor,
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
                                              style: textStyle,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              DropdownButton<String>(
                                dropdownColor: secondaryColor,
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
                                              style: textStyle,
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              DropdownButton<String>(
                                dropdownColor: secondaryColor,
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
                                              style: textStyle,
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
                                return ListTile(
                                  titleTextStyle: textStyle,
                                  textColor: primaryColor,
                                  title: Text(g['title']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${g['points']} pts | ${g['category']}',
                                        style: textStyle,
                                      ),
                                      if (_selectedStatusFilter == 'Active' &&
                                          int.tryParse(g['steps'])! > 1)
                                        buildStepDisplay(g, userFontSize)
                                    ],
                                  ),
                                  onTap: () => _viewGoalDetails(g),
                                  trailing:
                                      _selectedStatusFilter == 'Active'
                                          ? Wrap(
                                            children: [
                                              IconButton(
                                                color: primaryColor,
                                                icon: const Icon(
                                                  Icons.add_task,
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
                                                color: primaryColor,
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

