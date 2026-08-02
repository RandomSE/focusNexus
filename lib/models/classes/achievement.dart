import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:focusNexus/utils/completion_timestamp.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

/// Serializes completion times like goals: `dd MMMM yyyy HH:mm`.
class CompletionDateTimeConverter
    implements JsonConverter<DateTime?, String?> {
  const CompletionDateTimeConverter();

  @override
  DateTime? fromJson(String? json) => CompletionTimestamp.tryParse(json);

  @override
  String? toJson(DateTime? object) =>
      object == null ? null : CompletionTimestamp.formatLabel(object);
}

/// Persisted achievement definition and progress (secure storage JSON list).
@freezed
class Achievement with _$Achievement {
  const Achievement._();

  const factory Achievement({
    required String id,
    required String title,
    required String reward,
    required String task,
    @CompletionDateTimeConverter() DateTime? dateCompleted,
    @Default(false) bool isCompleted,
    @Default(true) bool isSecret,
    @Default(0.0) double progress,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  /// Debug-only invariant checks (id/title non-empty, progress 0-100).
  void validate() {
    assert(id.isNotEmpty, 'id must not be empty');
    assert(title.isNotEmpty, 'title must not be empty');
    assert(
      progress >= 0.0 && progress <= 100.0,
      'progress must be between 0 and 100',
    );
  }
}
