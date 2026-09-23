/// When to ask for notification frequency and style after signup.
abstract final class NotificationPrefsPrompt {
  NotificationPrefsPrompt._();

  /// [confirmedRaw] is the stored `notificationPrefsConfirmed` value.
  /// Null means a legacy install that already chose during setup.
  /// `'false'` means signup deferred the choice until the first goal.
  static bool shouldPromptOnFirstGoal({
    required String? confirmedRaw,
    required bool hasAnyGoal,
  }) {
    if (hasAnyGoal) return false;
    return confirmedRaw == 'false';
  }
}
