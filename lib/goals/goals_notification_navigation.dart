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
