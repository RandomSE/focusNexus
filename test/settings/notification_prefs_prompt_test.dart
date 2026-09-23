import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/settings/notification_prefs_prompt.dart';

void main() {
  test('legacy installs with no flag are not prompted', () {
    expect(
      NotificationPrefsPrompt.shouldPromptOnFirstGoal(
        confirmedRaw: null,
        hasAnyGoal: false,
      ),
      isFalse,
    );
  });

  test('new signup is prompted only before the first goal exists', () {
    expect(
      NotificationPrefsPrompt.shouldPromptOnFirstGoal(
        confirmedRaw: 'false',
        hasAnyGoal: false,
      ),
      isTrue,
    );
    expect(
      NotificationPrefsPrompt.shouldPromptOnFirstGoal(
        confirmedRaw: 'false',
        hasAnyGoal: true,
      ),
      isFalse,
    );
    expect(
      NotificationPrefsPrompt.shouldPromptOnFirstGoal(
        confirmedRaw: 'true',
        hasAnyGoal: false,
      ),
      isFalse,
    );
  });
}
