import 'package:focusNexus/goals/repeat_rule.dart';

/// Persisted repeat schedule for time-window goals (separate from instances).
class GoalRepeatSeries {
  const GoalRepeatSeries({
    required this.seriesId,
    this.isActive = true,
    required this.repeatRule,
    required this.windowDuration,
    required this.anchorEndAt,
    this.lastSpawnedWindowEnd = '',
    this.templateName,
    required this.title,
    required this.category,
    required this.complexity,
    required this.effort,
    required this.motivation,
    required this.time,
    required this.steps,
  });

  final int seriesId;
  final bool isActive;
  final RepeatRule repeatRule;
  final Duration windowDuration;
  final String anchorEndAt;
  final String lastSpawnedWindowEnd;
  final String? templateName;
  final String title;
  final String category;
  final String complexity;
  final String effort;
  final String motivation;
  final int time;
  final int steps;

  GoalRepeatSeries copyWith({
    int? seriesId,
    bool? isActive,
    RepeatRule? repeatRule,
    Duration? windowDuration,
    String? anchorEndAt,
    String? lastSpawnedWindowEnd,
    String? templateName,
    String? title,
    String? category,
    String? complexity,
    String? effort,
    String? motivation,
    int? time,
    int? steps,
  }) {
    return GoalRepeatSeries(
      seriesId: seriesId ?? this.seriesId,
      isActive: isActive ?? this.isActive,
      repeatRule: repeatRule ?? this.repeatRule,
      windowDuration: windowDuration ?? this.windowDuration,
      anchorEndAt: anchorEndAt ?? this.anchorEndAt,
      lastSpawnedWindowEnd: lastSpawnedWindowEnd ?? this.lastSpawnedWindowEnd,
      templateName: templateName ?? this.templateName,
      title: title ?? this.title,
      category: category ?? this.category,
      complexity: complexity ?? this.complexity,
      effort: effort ?? this.effort,
      motivation: motivation ?? this.motivation,
      time: time ?? this.time,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toMap() => {
    'seriesId': seriesId,
    'isActive': isActive,
    'repeatRule': repeatRule.toMap(),
    'windowDurationMinutes': windowDuration.inMinutes,
    'anchorEndAt': anchorEndAt,
    'lastSpawnedWindowEnd': lastSpawnedWindowEnd,
    if (templateName != null) 'templateName': templateName,
    'title': title,
    'category': category,
    'complexity': complexity,
    'effort': effort,
    'motivation': motivation,
    'time': time,
    'steps': steps,
  };

  factory GoalRepeatSeries.fromMap(Map<String, dynamic> map) {
    final ruleRaw = map['repeatRule'];
    return GoalRepeatSeries(
      seriesId: int.tryParse(map['seriesId']?.toString() ?? '0') ?? 0,
      isActive: map['isActive'] != false &&
          map['isActive']?.toString().toLowerCase() != 'false',
      repeatRule: ruleRaw is Map
          ? RepeatRule.fromMap(Map<String, dynamic>.from(ruleRaw))
          : RepeatRule.none,
      windowDuration: Duration(
        minutes:
            int.tryParse(map['windowDurationMinutes']?.toString() ?? '0') ?? 0,
      ),
      anchorEndAt: map['anchorEndAt']?.toString() ?? '',
      lastSpawnedWindowEnd: map['lastSpawnedWindowEnd']?.toString() ?? '',
      templateName: map['templateName']?.toString(),
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      complexity: map['complexity']?.toString() ?? '',
      effort: map['effort']?.toString() ?? '',
      motivation: map['motivation']?.toString() ?? '',
      time: int.tryParse(map['time']?.toString() ?? '0') ?? 0,
      steps: int.tryParse(map['steps']?.toString() ?? '0') ?? 0,
    );
  }
}
