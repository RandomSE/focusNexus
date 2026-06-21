import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goals_deep_link_provider.g.dart';

/// Goal id to highlight when opening Goals from a notification tap.
@Riverpod(keepAlive: true)
class GoalsDeepLink extends _$GoalsDeepLink {
  @override
  int? build() => null;

  void setGoalId(int? goalId) => state = goalId;

  int? takeGoalId() {
    final id = state;
    state = null;
    return id;
  }
}
