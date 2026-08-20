import 'package:focusNexus/goals/goal_field_validators.dart';

/// Snackbar / inline copy when goal or template forms fail validation.
class GoalFormFeedback {
  GoalFormFeedback._();

  /// Joins field labels into a single user-facing sentence.
  static String formatMissingFieldsMessage(List<String> fieldLabels) {
    if (fieldLabels.isEmpty) return '';
    if (fieldLabels.length == 1) {
      return 'Please fill or fix: ${fieldLabels.single}.';
    }
    if (fieldLabels.length == 2) {
      return 'Please fill or fix: ${fieldLabels[0]} and ${fieldLabels[1]}.';
    }
    final head = fieldLabels.sublist(0, fieldLabels.length - 1).join(', ');
    return 'Please fill or fix: $head, and ${fieldLabels.last}.';
  }

  static List<String> collectNormalGoalFieldIssues({
    required String title,
    required String time,
    required String steps,
    required String deadlineHours,
  }) {
    final issues = <String>[];
    if (title.trim().isEmpty) {
      issues.add('Goal Title');
    }
    if (GoalFieldValidators.timeMinutes(time) != null) {
      issues.add('Time Required in minutes');
    }
    if (GoalFieldValidators.steps(steps) != null) {
      issues.add('Steps');
    }
    if (_optionalDeadlineIssue(
          deadlineHours,
          timeMinutes: int.tryParse(time.trim()) ?? 0,
          maxHoursExclusive: 10000,
        ) !=
        null) {
      issues.add('Hours to complete');
    }
    return issues;
  }

  static List<String> collectTimeSlotGoalFieldIssues({
    required String title,
    required String time,
    required String steps,
  }) {
    final issues = <String>[];
    if (title.trim().isEmpty) {
      issues.add('Goal Title');
    }
    if (GoalFieldValidators.timeMinutes(time) != null) {
      issues.add('Time Required in minutes');
    }
    if (GoalFieldValidators.steps(steps) != null) {
      issues.add('Steps');
    }
    return issues;
  }

  static List<String> collectTemplateFieldIssues({
    required String name,
    required String time,
    required String steps,
    required String deadlineHours,
  }) {
    final issues = <String>[];
    if (name.trim().isEmpty) {
      issues.add('Template Name');
    }
    if (GoalFieldValidators.timeMinutes(time) != null) {
      issues.add('Time (minutes)');
    }
    if (GoalFieldValidators.steps(steps) != null) {
      issues.add('Steps');
    }
    if (_optionalDeadlineIssue(
          deadlineHours,
          timeMinutes: int.tryParse(time.trim()) ?? 0,
          maxHoursExclusive: 10001,
        ) !=
        null) {
      issues.add('Hours to complete');
    }
    return issues;
  }

  /// Matches create-form / template deadline validators.
  static String? _optionalDeadlineIssue(
    String? value, {
    required int timeMinutes,
    required int maxHoursExclusive,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0 || parsed >= maxHoursExclusive) {
      return 'invalid';
    }
    if (timeMinutes > 0 && timeMinutes > parsed * 60) {
      return 'too short';
    }
    return null;
  }
}
