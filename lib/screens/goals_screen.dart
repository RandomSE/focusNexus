// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Map<String, dynamic>> _goals = [];
  final _titleController = TextEditingController();
  String _category = 'Productivity';
  int _progress = 0;
  final _categories = ['Productivity', 'Health', 'Learning'];
  final _templates = [
    'Complete a 25-minute focus session',
    'Read for 15 minutes',
    'Go for a 10-minute walk',
  ];

  void _addGoal() {
    if (_titleController.text.isEmpty) return;
    setState(() {
      _goals.add({
        'title': _titleController.text,
        'category': _category,
        'progress': 0,
        'target': 30,
      });
      _titleController.clear();
    });
  }

  void _incrementProgress(int index) {
    setState(() {
      if (_goals[index]['progress'] < _goals[index]['target']) {
        _goals[index]['progress']++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _category = val ?? _category),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal Title'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              hint: const Text('Pick a template (optional)'),
              items: _templates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => _titleController.text = val ?? '',
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _addGoal, child: const Text('Add Goal')),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  final percent = goal['progress'] / goal['target'];
                  return Card(
                    child: ListTile(
                      title: Text(goal['title']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: percent),
                          Text('${goal['progress']} of ${goal['target']} days complete'),
                          const SizedBox(height: 4),
                          Text('"Consistency is key!"'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () => _incrementProgress(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}