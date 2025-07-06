// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../utils/BaseState.dart';

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
  String _motivation = 'Low';
  final _categories = ['Productivity', 'Health', 'Learning'];
  final _levels = ['Low', 'Medium', 'High'];
  final Map<String, Map<String, dynamic>> _templateDetails = {
    'Clean your room': {
      'category': 'Productivity',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Medium',
      'time': '10',
      'Days to complete': '1',
      'steps': '1',
    },
    '5-minute walk': {
      'category': 'Health',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Low',
      'time': '5',
      'Days to complete': '1',
      'steps': '1',
    },
    'Make a meal': {
      'category': 'Health',
      'complexity': 'Medium',
      'effort': 'Medium',
      'motivation': 'Medium',
      'time': '30',
      'Days to complete': '1',
      'steps': '2',
    },
    'Take a shower': {
      'category': 'Health',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Low',
      'time': '10',
      'Days to complete': '1',
      'steps': '1',
    },
    'Compliment someone': {
      'category': 'Social',
      'complexity': 'Low',
      'effort': 'Low',
      'motivation': 'Low',
      'time': '1',
      'Days to complete': '1',
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
  );
  final DateFormat formatter = DateFormat('dd MMMM yyyy');
  Map<String, Map<String, dynamic>> _userTemplates = {};
  late ThemeData _themeData;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadTemplates();
    _themeData = defaultThemeData; // Start with default
    loadStoredTheme(); // Try loading stored theme data
    setThemeData();
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
        final DateFormat deadlineFormat = DateFormat('d MMMM yyyy');

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

  int _calculatePoints() {
    int base = 5;
    int mult = 1;
    if (_complexity == 'Medium') mult++;
    if (_complexity == 'High') mult += 2;
    if (_effort == 'Medium') mult++;
    if (_effort == 'High') mult += 2;
    if (_motivation == 'Medium') mult++;
    if (_motivation == 'High') mult += 2;
    return base * mult;
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
    await _storage.write(key: 'points', value: (value + amount).toString());
  }

  void _createGoal() {
    if (_formKey.currentState!.validate()) {
      String deadlineDays = _deadlineController.text;
      String deadline = formatter.format(_currentDate); // default. should be updated below.
      if(deadlineDays == '' || deadlineDays == null){
        deadline = 'no deadline';
      }
      else {
        final int days = int.tryParse(deadlineDays) ?? 0;
        final DateTime deadlineDate = _currentDate.add(Duration(days: days));
        deadline = formatter.format(deadlineDate);
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
    _completedGoals.add(goal);
    _addPoints(goal['points'], 'goal:${goal['title']}');
    _saveGoals();
    setState(() {});
  }

  void _removeGoal(int index) {
    setState(() {
      _activeGoals.removeAt(index);
    });
    _saveGoals();
  }

  void _checkForExpiredGoals() {
    final DateFormat format = DateFormat('d MMMM yyyy');
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
    final TextStyle textStyle = TextStyle(
      fontSize: userFontSize,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    );

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
    final TextStyle textStyle = TextStyle(
      fontSize: userFontSize,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    );

    final TextEditingController _templateName = TextEditingController();
    final TextEditingController _templateTime = TextEditingController();
    final TextEditingController _templateSteps = TextEditingController();
    final TextEditingController _templateDeadline = TextEditingController();
    String _templateCategory = _categories.first;
    String _templateComplexity = _levels.first;
    String _templateEffort = _levels.first;
    String _templateMotivation = _levels.first;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: secondaryColor,
                  title: Text('Manage Templates', style: textStyle),
                  content: SingleChildScrollView(
                    child: Container(
                      color: secondaryColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _templateName,
                            style: textStyle,
                            decoration: InputDecoration(
                              labelText: 'Template Name',
                              labelStyle: textStyle,
                              filled: true,
                              fillColor: secondaryColor,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          DropdownButtonFormField(
                            dropdownColor: secondaryColor,
                            value: _templateCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: textStyle,
                            ),
                            items:
                                _categories
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            style: textStyle,
                            onChanged:
                                (v) => setState(() => _templateCategory = v!),
                          ),
                          DropdownButtonFormField(
                            dropdownColor: secondaryColor,
                            value: _templateComplexity,
                            decoration: InputDecoration(
                              labelText: 'Complexity',
                              labelStyle: textStyle,
                            ),
                            items:
                                _levels
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            style: textStyle,
                            onChanged:
                                (v) => setState(() => _templateComplexity = v!),
                          ),
                          DropdownButtonFormField(
                            dropdownColor: secondaryColor,
                            value: _templateEffort,
                            decoration: InputDecoration(
                              labelText: 'Effort',
                              labelStyle: textStyle,
                            ),
                            items:
                                _levels
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            style: textStyle,
                            onChanged:
                                (v) => setState(() => _templateEffort = v!),
                          ),
                          DropdownButtonFormField(
                            dropdownColor: secondaryColor,
                            value: _templateMotivation,
                            decoration: InputDecoration(
                              labelText: 'Motivation',
                              labelStyle: textStyle,
                            ),
                            items:
                                _levels
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            style: textStyle,
                            onChanged:
                                (v) => setState(() => _templateMotivation = v!),
                          ),
                          TextField(
                            style: textStyle,
                            controller: _templateTime,
                            decoration: InputDecoration(
                              labelText: 'Time (minutes)',
                              labelStyle: textStyle,
                            ),
                          ),
                          TextField(
                            style: textStyle,
                            controller: _templateDeadline,
                            decoration: InputDecoration(
                              labelText: 'Days to complete',
                              labelStyle: textStyle,
                            ),
                          ),
                          TextField(
                            style: textStyle,
                            controller: _templateSteps,
                            decoration: InputDecoration(
                              labelText: 'Steps',
                              labelStyle: textStyle,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final name = _templateName.text.trim();
                              if (name.isEmpty) return;
                              final data = {
                                'category': _templateCategory,
                                'complexity': _templateComplexity,
                                'effort': _templateEffort,
                                'motivation': _templateMotivation,
                                'time': _templateTime.text.trim(),
                                'steps': _templateSteps.text.trim(),
                                'Days to complete': _templateDeadline.text.trim()
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
                              trailing:
                                  _userTemplates.containsKey(name)
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
                                final t =
                                    _templateDetails[name] ??
                                    _userTemplates[name]!;
                                setState(() {
                                  _templateName.text = name;
                                  _templateCategory = t['category'];
                                  _templateComplexity = t['complexity'];
                                  _templateEffort = t['effort'];
                                  _templateMotivation = t['motivation'];
                                  _templateTime.text = t['time'];
                                  _templateDeadline.text = t['Days to complete'];
                                  _templateSteps.text = t['steps'];
                                });
                              },
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = userTheme == 'dark';
    final bool contrastMode = highContrastMode;
    final Color primaryColor = getPrimaryColor(isDark, contrastMode);
    final Color secondaryColor = getSecondaryColor(isDark, contrastMode);
    final TextStyle textStyle = getTextStyle(
      userFontSize,
      primaryColor,
      useDyslexiaFont,
    );
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: secondaryColor,
      foregroundColor: primaryColor,
    );

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
                                      _motivation = data['motivation'];
                                    });
                                    _timeController.text = data['time'];
                                    _deadlineController.text = data['Days to complete'];
                                    _stepsController.text = data['steps'];
                                  },
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
                                    if (v == null || v.trim().isEmpty) return null;
                                    final intValue = int.tryParse(v);
                                    if (intValue == null) return 'Please enter a valid number';
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  style: textStyle,
                                  controller: _deadlineController,
                                  decoration: InputDecoration(
                                    labelText: 'Days to complete',
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
                                    labelText: 'Steps (if any)',
                                    labelStyle: textStyle,
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Describe steps or type "None"'
                                              : null,
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: buttonStyle,
                                  onPressed: _createGoal,
                                  child: Text('Add Goal', style: textStyle),
                                ),
                                ElevatedButton(
                                  style: buttonStyle,
                                  onPressed: _openTemplateManager,
                                  child: Text(
                                    'Manage Templates',
                                    style: textStyle,
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
                                        Row(
                                          children: List.generate(
                                            int.tryParse(
                                              g['steps']?.toString() ?? '1',
                                            )!,
                                            (i) => Icon(
                                              i < (g['stepProgress'] ?? 0)
                                                  ? Icons.check_box
                                                  : Icons
                                                      .check_box_outline_blank,
                                              size: userFontSize,
                                            ),
                                          ),
                                        ),
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
