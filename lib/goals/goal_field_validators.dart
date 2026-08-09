/// Shared create-form validators aligned with goal scoring plateaus.
class GoalFieldValidators {
  GoalFieldValidators._();

  /// [CommonUtils.scoreFromTime] stops increasing at 600 minutes.
  static const int maxTimeMinutesForPoints = 600;

  /// [CommonUtils.scoreFromSteps] stops increasing at 50 steps.
  static const int maxStepsForPoints = 50;

  static String? timeMinutes(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) {
      return 'Please enter a valid whole number';
    }
    if (parsed > maxTimeMinutesForPoints) {
      return 'Max $maxTimeMinutesForPoints minutes '
          '(higher does not increase points)';
    }
    return null;
  }

  static String? steps(String? value) {
    final trimmed = value?.trim();
    final parsed = int.tryParse(
      trimmed == null || trimmed.isEmpty ? '1' : trimmed,
    );
    if (parsed == null || parsed < 1) {
      return 'Please enter a valid whole number above 0';
    }
    if (parsed > maxStepsForPoints) {
      return 'Max $maxStepsForPoints steps '
          '(higher does not increase points)';
    }
    return null;
  }
}
