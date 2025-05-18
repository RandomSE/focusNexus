// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
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
  final _templates = [
    'Clean your room',
    '5-minute walk',
    'Make a meal',
    'Take a shower',
    'Compliment someone',
  ];
  final Map<String, Map<String, dynamic>> _templateDetails = {
    'Clean your room': {
      'category': 'Productivity', 'complexity': 'Low', 'effort': 'Low', 'motivation': 'Medium', 'time': '10', 'steps': '1'
    },
    '5-minute walk': {
      'category': 'Health', 'complexity': 'Low', 'effort': 'Low', 'motivation': 'Low', 'time': '5', 'steps': '1'
    },
    'Make a meal': {
      'category': 'Health', 'complexity': 'Medium', 'effort': 'Medium', 'motivation': 'Medium', 'time': '30', 'steps': '2'
    },
    'Take a shower': {
      'category': 'Health', 'complexity': 'Low', 'effort': 'Low', 'motivation': 'Low', 'time': '10', 'steps': '1'
    },
    'Compliment someone': {
      'category': 'Social', 'complexity': 'Low', 'effort': 'Low', 'motivation': 'Low', 'time': '1', 'steps': '1'
    },
  };

  List<Map<String, dynamic>> _activeGoals = [];
  List<Map<String, dynamic>> _completedGoals = [];
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadGoals();
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
      final goal = {
        'title': _titleController.text,
        'category': _category,
        'complexity': _complexity,
        'effort': _effort,
        'motivation': _motivation,
        'time': _timeController.text,
        'steps': _stepsController.text,
        'points': _calculatePoints(),
        'stepProgress': 0
      };
      setState(() {
        _activeGoals.add(goal);
      });
      _saveGoals();
      _titleController.clear();
      _timeController.clear();
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

  void _viewGoalDetails(Map<String, dynamic> goal) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(goal['title']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${goal['category']}'),
                Text('Complexity: ${goal['complexity']}'),
                Text('Effort: ${goal['effort']}'),
                Text('Motivation: ${goal['motivation']}'),
                Text('Time Needed in minutes: ${goal['time']}'),
                Text('Steps: ${goal['steps']}'),
                Text('Points: ${goal['points']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Goals')),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                hint: const Text('Template (optional)'),
                                items: _templates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  _titleController.text = val;
                                  final data = _templateDetails[val]!;
                                  setState(() {
                                    _category = data['category'];
                                    _complexity = data['complexity'];
                                    _effort = data['effort'];
                                    _motivation = data['motivation'];
                                  });
                                  _timeController.text = data['time'];
                                  _stepsController.text = data['steps'];
                                },
                              ),
                              DropdownButtonFormField(
                                value: _complexity,
                                items:
                                    _levels
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (val) => setState(
                                      () => _complexity = val ?? 'Low',
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Complexity',
                                ),
                              ),
                              DropdownButtonFormField(
                                value: _effort,
                                items:
                                    _levels
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (val) =>
                                        setState(() => _effort = val ?? 'Low'),
                                decoration: const InputDecoration(
                                  labelText: 'Effort Required',
                                ),
                              ),
                              DropdownButtonFormField(
                                value: _motivation,
                                items:
                                    _levels
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (val) => setState(
                                      () => _motivation = val ?? 'Low',
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Motivation Needed',
                                ),
                              ),
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Goal Title',
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Title required'
                                            : null,
                              ),
                              TextFormField(
                                controller: _timeController,
                                decoration: const InputDecoration(
                                  labelText: 'Time Required in minutes',
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Enter time needed'
                                            : null,
                              ),
                              TextFormField(
                                controller: _stepsController,
                                decoration: const InputDecoration(
                                  labelText: 'Steps (if any)',
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Describe steps or type "None"'
                                            : null,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _createGoal,
                                child: const Text('Add Goal'),
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
                              value: _selectedCategoryFilter,
                              onChanged:
                                  (val) => setState(
                                    () =>
                                        _selectedCategoryFilter = val ?? 'All',
                                  ),
                              items:
                                  ['All', ..._categories]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text('Category: $e'),
                                        ),
                                      )
                                      .toList(),
                            ),
                            DropdownButton<String>(
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
                                          child: Text('Complexity: $e'),
                                        ),
                                      )
                                      .toList(),
                            ),
                            DropdownButton<String>(
                              value: _selectedStatusFilter,
                              onChanged:
                                  (val) => setState(
                                    () =>
                                        _selectedStatusFilter = val ?? 'Active',
                                  ),
                              items:
                                  ['Active', 'Completed']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text('Status: $e'),
                                        ),
                                      )
                                      .toList(),
                            ),
                            DropdownButton<String>(
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
                                      ]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text('Sort: $e'),
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
                                title: Text(g['title']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${g['points']} pts | ${g['category']}'),
                                    if (_selectedStatusFilter == 'Active' && int.tryParse(g['steps'])! > 1)
                                      Row(
                                        children: List.generate(
                                          int.tryParse(g['steps']?.toString() ?? '1')!,
                                              (i) => Icon(
                                            i < (g['stepProgress'] ?? 0) ? Icons.check_box : Icons.check_box_outline_blank,
                                            size: 18,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                                onTap: () => _viewGoalDetails(g),
                                trailing: _selectedStatusFilter == 'Active'
                                    ? Wrap(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_task),
                                      onPressed: () => _incrementStepProgress(_activeGoals.indexOf(g)),
                                      tooltip: 'Add Step Progress',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeGoal(_activeGoals.indexOf(g)),
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
    );
  }
}
