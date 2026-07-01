/// Read-only app state the offline Assistant may use in answers.
class AssistantLiveContext {
  const AssistantLiveContext({
    this.pointsBalance,
    this.achievements = const [],
    this.categories = const [],
  });

  final int? pointsBalance;
  final List<AssistantAchievementHint> achievements;
  final List<String> categories;
}

/// Achievement title + task for glossary matching.
class AssistantAchievementHint {
  const AssistantAchievementHint({
    required this.title,
    required this.task,
  });

  final String title;
  final String task;
}
