# Play Console: SCHEDULE_EXACT_ALARM

FocusNexus uses Android `SCHEDULE_EXACT_ALARM` so time-sensitive goal
reminders, affirmations, and streak nudges can fire at the times the user
chose.

## Declaration guidance (operator)

When Play Console asks why the app needs exact alarms, state that:

- The app schedules **local** goal reminders and related time-sensitive alerts.
- Exact alarms improve reminder precision for ADHD-friendly planning.
- If the user denies exact-alarm access, the app **falls back to inexact**
  scheduling (`inexactAllowWhileIdle`) and continues to deliver reminders at
  approximate times.
- The app does **not** use exact alarms for ads, location tracking, or
  unrelated background work.

Keep `SCHEDULE_EXACT_ALARM` in the main manifest. Do not switch to
`USE_EXACT_ALARM` unless Play policy or OEM evidence requires it.

Full Console questionnaire recipe (Data safety, content rating, ads, 13+):
[`PLAY_CONSOLE_OPERATOR_FORMS.md`](PLAY_CONSOLE_OPERATOR_FORMS.md).

## In-app behaviour

- Notification permission alone enables local notifications.
- Exact-alarm grant selects exact vs inexact schedule mode only.
- When exact alarm is denied, Settings explains that reminders may be less
  precise and offers a shortcut to the system exact-alarm settings screen.
