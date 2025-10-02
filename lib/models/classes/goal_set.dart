class GoalSet { /// here so I can pass over many variables without many lines of code. Mostly used when goals are passed to notifier to be canceled, so it can filter correctly.
  final String title;
  final String category;
  final String complexity;
  final String effort;
  final String motivation;
  final int time;
  final String deadline;
  final int steps;
  final int points;
  final int stepProgress;
  final int goalId;

  GoalSet({
    required this.title,
    required this.category,
    required this.complexity,
    required this.effort,
    required this.motivation,
    required this.time,
    required this.deadline,
    required this.steps,
    required this.points,
    required this.stepProgress,
    required this.goalId,
});


  /// Factory to build from Map of (String, dynamic)
  factory GoalSet.fromMap(Map<String, dynamic> map) {
    return GoalSet(
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      complexity: map['complexity'] ?? '',
      effort: map['effort'] ?? '',
      motivation: map['motivation'] ?? '',
      time: int.tryParse(map['time']?.toString() ?? '0') ?? 0,
      deadline: map['Deadline'] ?? '', // watch casing here
      steps: int.tryParse(map['steps']?.toString() ?? '0') ?? 0,
      points: int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      stepProgress: int.tryParse(map['stepProgress']?.toString() ?? '0') ?? 0,
      goalId: int.tryParse(map['Id']?.toString() ?? '0') ?? 0,
    );
  }

  /// convert back to Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'complexity': complexity,
      'effort': effort,
      'motivation': motivation,
      'time': time,
      'Deadline': deadline,
      'steps': steps,
      'points': points,
      'stepProgress': stepProgress,
      'Id': goalId,
    };
  }

  @override
  String toString() {
    return 'title: $title \n category: $category \n complexity: $complexity \n effort: $effort \n motivation: $motivation \n time required in minutes: $time \n'
        ' deadline: $deadline \n steps: $steps \n points: $points \n steps completed: $stepProgress \n goalId: $goalId' ;
  }
}