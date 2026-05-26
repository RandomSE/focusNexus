import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

/// Persisted achievement definition and progress (secure storage JSON list).
@freezed
class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    required String id,
    required String title,
    required String reward,
    required String task,
    DateTime? dateCompleted,
    @Default(false) bool isCompleted,
    @Default(true) bool isSecret,
    @Default(0.0) double progress,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  /// Debug-only invariant checks (id/title non-empty, progress 0–100).
  void validate() {
    assert(id.isNotEmpty, 'id must not be empty');
    assert(title.isNotEmpty, 'title must not be empty');
    assert(
      progress >= 0.0 && progress <= 100.0,
      'progress must be between 0 and 100',
    );
  }
}
