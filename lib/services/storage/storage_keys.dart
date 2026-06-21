/// Canonical secure-storage keys (single source of truth).
///
/// All persisted keys in production and tests must reference this module.
abstract final class StorageKeys {
  // Goals
  static const activeGoals = 'activeGoals';
  static const completedGoals = 'completedGoals';
  static const completedToday = 'completedToday';
  static const pauseGoals = 'pauseGoals';

  // Templates
  static const userTemplates = 'userTemplates';
  static const templateGroups = 'templateGroups';
  static const timeWindowRepeatSeries = 'timeWindowRepeatSeries';

  // Wallet
  static const points = 'points';

  // Garden
  static const zenGardenSave = 'zen_garden_save_v1';

  // User preferences
  static const theme = 'theme';
  static const themeData = 'themeData';
  static const fontSize = 'fontSize';
  static const dyslexiaFont = 'dyslexiaFont';
  static const highContrast = 'highContrast';
  static const dailyAffirmations = 'dailyAffirmations';
  static const aiEncouragement = 'aiEncouragement';
  /// Initial setup form (notification/reward prefs) completed; onboarding may remain.
  static const registrationComplete = 'registrationComplete';
  /// Legacy key; still read on load for upgrades from login-based builds.
  static const loggedIn = 'loggedIn';
  static const onboardingCompleted = 'onboardingCompleted';
  static const skipToday = 'skipToday';
  static const notificationStyle = 'notificationStyle';
  static const notificationFrequency = 'notificationFrequency';
  static const rewardType = 'rewardType';
  static const customizationEnabled = 'customizationEnabled';
  static const useCustomColorPalette = 'useCustomColorPalette';
  static const allowedColors = 'allowedColors';
  static const customizedPrimaryColor = 'customizedPrimaryColor';
  static const customizedSecondaryColor = 'customizedSecondaryColor';
  static const customizedFont = 'customizedFont';
  static const soundEnabled = 'soundEnabled';
  static const soundVolume = 'soundVolume';
  static const dailyAffirmationsTime = 'dailyAffirmationsTime';
  /// Last calendar day (yyyy-MM-dd) with a scheduled daily affirmation.
  static const dailyAffirmationsScheduledUntil = 'dailyAffirmationsScheduledUntil';

  // Achievement counters (scalar keys read by AchievementService)
  static const totalGoalsCreated = 'totalGoalsCreated';
  static const totalGoalsActive = 'totalGoalsActive';
  static const totalGoalsCompleted = 'totalGoalsCompleted';
  static const goalsCompletedToday = 'goalsCompletedToday';
  static const goalsCompletedThisWeek = 'goalsCompletedThisWeek';
  static const goalsCompletedThisMonth = 'goalsCompletedThisMonth';
  static const goalsCompletedWithHighPoints = 'goalsCompletedWithHighPoints';
  static const goalsCompletedWithHighComplexity = 'goalsCompletedWithHighComplexity';
  static const goalsCompletedWithHighEffort = 'goalsCompletedWithHighEffort';
  static const goalsCompletedWithHighMotivation = 'goalsCompletedWithHighMotivation';
  static const goalsCompletedWithAllHigh = 'goalsCompletedWithAllHigh';
  static const goalsCompletedWithHighTimeRequirement =
      'goalsCompletedWithHighTimeRequirement';
  static const goalsCompletedWithManySteps = 'goalsCompletedWithManySteps';
  static const goalsCompletedEarly = 'goalsCompletedEarly';
  static const dateGoalsCompleted = 'dateGoalsCompleted';
  static const lastWeekGoalWasCompleted = 'lastWeekGoalWasCompleted';
  static const lastMonthGoalWasCompleted = 'lastMonthGoalWasCompleted';
  static const consecutiveDaysWithGoalsCompleted =
      'consecutiveDaysWithGoalsCompleted';
  static const consecutiveWeeksWithGoalsCompleted =
      'consecutiveWeeksWithGoalsCompleted';

  // Category completion stats (achievements 100–105)
  static const goalsCompletedByCategory = 'goalsCompletedByCategory';
  static const categoriesWithAtLeast1Goal = 'categoriesWithAtLeast1Goal';
  static const categoriesWithAtLeast3Goals = 'categoriesWithAtLeast3Goals';
  static const categoriesWithAtLeast5Goals = 'categoriesWithAtLeast5Goals';
  static const categoriesWithAtLeast10Goals = 'categoriesWithAtLeast10Goals';
  static const categoriesWithAtLeast25Goals = 'categoriesWithAtLeast25Goals';
  static const categoriesWithAllTypesCompleted =
      'categoriesWithAllTypesCompleted';

  // Achievements list blob
  static const achievements = 'achievements';
  static const achievementTrackingData = 'achievementTrackingData';
}
