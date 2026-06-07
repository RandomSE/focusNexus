import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'achievements_list_refresh_provider.g.dart';

/// Bumps when the achievements list should reload (e.g. after completing one).
@riverpod
class AchievementsListRefresh extends _$AchievementsListRefresh {
  @override
  int build() => 0;

  void bump() => state++;
}
