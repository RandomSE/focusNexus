import 'package:focusNexus/app/app_navigator.dart';
import 'package:focusNexus/app/app_route.dart';

/// Pending goal navigation from notification taps (read by [GoalsScreen]).
int? pendingGoalsNotificationGoalId;

void handleGoalsNotificationPayload(String? payload) {
  if (payload == null || !payload.startsWith('goals:')) return;
  final id = int.tryParse(payload.split(':').last);
  if (id != null) pendingGoalsNotificationGoalId = id;
}

int? takePendingGoalsNotificationGoalId() {
  final id = pendingGoalsNotificationGoalId;
  pendingGoalsNotificationGoalId = null;
  return id;
}

/// Opens the goals screen and highlights the pending notification goal, if any.
void openGoalsFromPendingNotification() {
  final goalId = takePendingGoalsNotificationGoalId();
  if (goalId == null) return;

  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) {
    pendingGoalsNotificationGoalId = goalId;
    return;
  }

  navigator.pushNamed(
    GoalsRoute.routeName,
    arguments: goalId,
  );
}
