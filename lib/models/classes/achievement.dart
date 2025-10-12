class Achievement {
  final String id;
  final String title;
  final String reward;
  final String task; // doubles as the description of the achievement
  final DateTime? dateCompleted;
  final bool isCompleted;
  final bool isSecret;
  final double progress;

  Achievement({
    required this.id,
    required this.title,
    required this.reward,
    required this.task,
    this.dateCompleted,
    this.isCompleted = false,
    required this.isSecret,
    this.progress = 0.0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      reward: json['reward'],
      task: json['task'],
      dateCompleted: json['dateCompleted'] != null
          ? DateTime.parse(json['dateCompleted'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      isSecret: json['isSecret'] ?? true,
      progress: json['progress'] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'reward': reward,
    'task': task,
    'dateCompleted': dateCompleted?.toIso8601String(),
    'isCompleted': isCompleted,
    'isSecret': isSecret,
    'progress': progress,
  };
}
