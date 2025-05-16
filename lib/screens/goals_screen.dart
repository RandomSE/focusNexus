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
    'Compliment someone'
  ];

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
      _activeGoals = active != null ? List<Map<String, dynamic>>.from(json.decode(active)) : [];
      _completedGoals = complete != null ? List<Map<String, dynamic>>.from(json.decode(complete)) : [];
    });
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
    await _storage.write(key: 'completedGoals', value: json.encode(_completedGoals));
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
      builder: (_) => AlertDialog(
        title: Text(goal['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${goal['category']}'),
            Text('Complexity: ${goal['complexity']}'),
            Text('Effort: ${goal['effort']}'),
            Text('Motivation: ${goal['motivation']}'),
            Text('Time Needed: ${goal['time']}'),
            Text('Steps: ${goal['steps']}'),
            Text('Points: ${goal['points']}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _viewCompletedGoals() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Completed Goals'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _completedGoals.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(_completedGoals[i]['title']),
              subtitle: Text('${_completedGoals[i]['points']} points earned'),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // ✅ Fixed overflow in goals build method with full scroll-safe layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Goals')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) =>
              SingleChildScrollView(
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
                              DropdownButtonFormField(
                                value: _category,
                                items: _categories
                                    .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() =>
                                    _category = val ?? 'Productivity'),
                                decoration: const InputDecoration(
                                    labelText: 'Category'),
                              ),
                              DropdownButtonFormField(
                                value: _complexity,
                                items: _levels
                                    .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _complexity = val ?? 'Low'),
                                decoration: const InputDecoration(
                                    labelText: 'Complexity'),
                              ),
                              DropdownButtonFormField(
                                value: _effort,
                                items: _levels
                                    .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _effort = val ?? 'Low'),
                                decoration: const InputDecoration(
                                    labelText: 'Effort Required'),
                              ),
                              DropdownButtonFormField(
                                value: _motivation,
                                items: _levels
                                    .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _motivation = val ?? 'Low'),
                                decoration: const InputDecoration(
                                    labelText: 'Motivation Needed'),
                              ),
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                    labelText: 'Goal Title'),
                                validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Title required'
                                    : null,
                              ),
                              DropdownButtonFormField<String>(
                                hint: const Text('Template (optional)'),
                                items: _templates
                                    .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) =>
                                _titleController.text = val ?? '',
                              ),
                              TextFormField(
                                controller: _timeController,
                                decoration: const InputDecoration(
                                    labelText: 'Time Required in minutes'),
                                validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter time needed'
                                    : null,
                              ),
                              TextFormField(
                                controller: _stepsController,
                                decoration: const InputDecoration(
                                    labelText: 'Steps (if any)'),
                                validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Describe steps or type "None"'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(onPressed: _createGoal,
                                  child: const Text('Add Goal')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: _activeGoals.length,
                            itemBuilder: (_, i) {
                              final g = _activeGoals[i];
                              return ListTile(
                                title: Text(g['title']),
                                subtitle: Text(
                                    '${g['points']} pts | ${g['category']}'),
                                onTap: () => _viewGoalDetails(g),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check),
                                      onPressed: () => _completeGoal(i),
                                      tooltip: 'Mark Complete',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeGoal(i),
                                      tooltip: 'Remove Goal',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _viewCompletedGoals,
                          child: const Text('View Completed Goals'),
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