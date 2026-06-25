import 'package:focusNexus/repositories/points_repository.dart';

/// Live wallet / goals snapshot for truthful onboarding previews.
class OnboardingLiveStats {
  const OnboardingLiveStats({
    this.points = PointsRepository.defaultBalance,
    this.activeGoals = 0,
    this.goalsInSlotNow = 0,
  });

  final int points;
  final int activeGoals;
  final int goalsInSlotNow;
}
