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

  /// Cumulative wallet spends (trySpend + synced zen spends) for cherry unlock.
  static const lifetimePointsSpent = 'lifetimePointsSpent';

  /// JSON map of mini-game id -> unlock / high-score progress.
  static const miniGamesProgress = 'miniGamesProgress';

  // Garden
  static const zenGardenSave = 'zen_garden_save_v1';

  // Zen garden achievements (112-113, 141-149)
  static const cherryBlossomTreeUnlockedFlag = 'cherryBlossomTreeUnlockedFlag';
  static const cherryBlossomTreeMaxedFlag = 'cherryBlossomTreeMaxedFlag';
  static const cherryBlossomStage0CompleteFlag =
      'cherryBlossomStage0CompleteFlag';
  static const cherryBlossomStage1CompleteFlag =
      'cherryBlossomStage1CompleteFlag';
  static const cherryBlossomStage2CompleteFlag =
      'cherryBlossomStage2CompleteFlag';
  static const cherryBlossomStage3CompleteFlag =
      'cherryBlossomStage3CompleteFlag';
  static const cherryBlossomStage4CompleteFlag =
      'cherryBlossomStage4CompleteFlag';
  static const cherryBlossomStage5CompleteFlag =
      'cherryBlossomStage5CompleteFlag';
  static const cherryBlossomStage6CompleteFlag =
      'cherryBlossomStage6CompleteFlag';
  static const cherryBlossomPeacePathFlag = 'cherryBlossomPeacePathFlag';
  static const cherryBlossomPowerPathFlag = 'cherryBlossomPowerPathFlag';

  static const List<String> cherryBlossomStageCompleteFlags = [
    cherryBlossomStage0CompleteFlag,
    cherryBlossomStage1CompleteFlag,
    cherryBlossomStage2CompleteFlag,
    cherryBlossomStage3CompleteFlag,
    cherryBlossomStage4CompleteFlag,
    cherryBlossomStage5CompleteFlag,
    cherryBlossomStage6CompleteFlag,
  ];

  // Firefly Jar achievements (118-122): best single-round catch counts
  static const fireflyJarBestDuration = 'fireflyJarBestDuration';
  static const fireflyJarBestEndless = 'fireflyJarBestEndless';

  // Stone Balance achievements (123-129): best height / timeout height
  static const stoneBalanceBestHeight = 'stoneBalanceBestHeight';
  static const stoneBalanceBestEndless = 'stoneBalanceBestEndless';
  static const stoneBalanceBestTimeoutHeight = 'stoneBalanceBestTimeoutHeight';

  // Patient One secret (130): full listen of breath_background via Sound effects Preview
  static const breathBackgroundFullListenFlag =
      'breathBackgroundFullListenFlag';

  // Breath Pacer achievements (131-135): best Duration / Endless scores
  static const breathPacerBestDuration = 'breathPacerBestDuration';
  static const breathPacerBestEndless = 'breathPacerBestEndless';

  // Meteor Catch achievements (136-140): best Duration / Endless scores
  static const meteorCatchBestDuration = 'meteorCatchBestDuration';
  static const meteorCatchBestEndless = 'meteorCatchBestEndless';
  static const meteorCatchBestStreak = 'meteorCatchBestStreak';
  static const meteorCatchBestEndlessStreak = 'meteorCatchBestEndlessStreak';

  // Word Bloom achievements (156-161 best score; 162-167 order streaks)
  static const wordBloomBestDuration = 'wordBloomBestDuration';
  static const wordBloomBestEndless = 'wordBloomBestEndless';
  static const wordBloomBestStreak = 'wordBloomBestStreak';
  static const wordBloomBestEndlessStreak = 'wordBloomBestEndlessStreak';

  // Rain Catcher achievements (168-173 best score; 174-179 catch streaks)
  static const rainCatcherBestDuration = 'rainCatcherBestDuration';
  static const rainCatcherBestEndless = 'rainCatcherBestEndless';
  static const rainCatcherBestStreak = 'rainCatcherBestStreak';
  static const rainCatcherBestEndlessStreak = 'rainCatcherBestEndlessStreak';

  // Daily first-open rewards / open-streak achievements (114-117)
  /// Last local calendar day (yyyy-MM-dd) that received a daily open grant.
  static const lastAppOpenGrantDate = 'lastAppOpenGrantDate';

  /// Last local calendar day a debug dashboard points credit was used.
  static const debugPointsCreditDate = 'debugPointsCreditDate';

  /// Consecutive local calendar days with at least one eligible open grant.
  static const consecutiveDaysAppOpened = 'consecutiveDaysAppOpened';

  // User preferences
  static const theme = 'theme';
  static const themeData = 'themeData';
  static const fontSize = 'fontSize';
  static const dyslexiaFont = 'dyslexiaFont';
  static const highContrast = 'highContrast';
  static const dailyAffirmations = 'dailyAffirmations';
  static const aiEncouragement = 'aiEncouragement';

  /// Optional local nudge to keep consecutive app-open streaks.
  static const openStreakReminders = 'openStreakReminders';
  static const openStreakRemindersTime = 'openStreakRemindersTime';

  /// Optional display username from registration (Play Console tester hook).
  static const username = 'username';

  /// Initial setup form (notification/reward prefs) completed; onboarding may remain.
  static const registrationComplete = 'registrationComplete';

  /// Legacy key; still read on load for upgrades from login-based builds.
  static const loggedIn = 'loggedIn';
  static const onboardingCompleted = 'onboardingCompleted';

  /// Whether the user accepted the in-app EULA.
  static const eulaAccepted = 'eulaAccepted';

  /// Accepted EULA version string (must match [kLegalDocsVersion] for current grant).
  static const eulaAcceptedVersion = 'eulaAcceptedVersion';

  /// ISO-8601 timestamp when the current EULA version was accepted.
  static const eulaAcceptedAt = 'eulaAcceptedAt';
  static const skipToday = 'skipToday';
  static const notificationStyle = 'notificationStyle';
  static const notificationFrequency = 'notificationFrequency';

  /// `'false'` after signup until the first-goal prompt is answered.
  /// Absent on installs that already chose notifications during setup.
  static const notificationPrefsConfirmed = 'notificationPrefsConfirmed';

  /// JSON list of enabled reward type storage strings (multi-select).
  static const rewardTypes = 'rewardTypes';
  static const customizationEnabled = 'customizationEnabled';
  static const useCustomColorPalette = 'useCustomColorPalette';
  static const allowedColors = 'allowedColors';
  static const customizedPrimaryColor = 'customizedPrimaryColor';
  static const customizedSecondaryColor = 'customizedSecondaryColor';
  static const customizedFont = 'customizedFont';
  static const soundEnabled = 'soundEnabled';
  static const soundVolume = 'soundVolume';

  /// Consistency calendar heatmap palette id ([ConsistencyPaletteId.storageValue]).
  static const consistencyPalette = 'consistencyPalette';

  /// Master music volume percent (0-100); multiplies with [soundVolume] for BGM.
  static const musicVolume = 'musicVolume';

  /// JSON map of per-SFX channel enabled + volume percent.
  static const soundChannels = 'soundChannels';

  /// JSON list of owned ambient soundscape channel ids.
  static const ownedAmbientSounds = 'ownedAmbientSounds';

  /// [AmbientSelectionMode.storageValue]: global vs per_section.
  static const ambientSelectionMode = 'ambientSelectionMode';

  /// Selected ambient track id when mode is global.
  static const ambientGlobalTrackId = 'ambientGlobalTrackId';

  /// JSON map of AmbientAppSection.storageValue -> ambient track id.
  static const ambientSectionTracks = 'ambientSectionTracks';

  /// Master toggle for ambient background music (Customization).
  static const ambientEnabled = 'ambientEnabled';

  /// Progressive-visuals-only points (spent before shared wallet in PV purchases).
  static const progressiveVisualsPoints = 'progressiveVisualsPoints';

  /// Daily counter (mirrors [completedToday]) of goal completions that
  /// qualify for PV momentum (pre-daily points >= [PvDailyMomentum.qualifyingPointsThreshold]).
  static const pvMomentumQualifyingToday = 'pvMomentumQualifyingToday';

  /// Legacy shared pack key (migrated into the two keys below).
  static const customAffirmationPack = 'customAffirmationPack';

  /// Dashboard motivator pack (messages, queue, mode, enabled, presets).
  static const dashboardMotivatorPack = 'dashboardMotivatorPack';

  /// Daily affirmation pack (messages, queue, mode, enabled, presets).
  static const dailyAffirmationPack = 'dailyAffirmationPack';

  /// When true, dashboard motivator banner is hidden (Settings).
  static const motivatorsDisabled = 'motivatorsDisabled';

  static const dailyAffirmationsTime = 'dailyAffirmationsTime';

  /// Last calendar day (yyyy-MM-dd) with a scheduled daily affirmation.
  static const dailyAffirmationsScheduledUntil =
      'dailyAffirmationsScheduledUntil';

  // Achievement counters (scalar keys read by AchievementService)
  static const totalGoalsCreated = 'totalGoalsCreated';
  static const totalGoalsActive = 'totalGoalsActive';
  static const totalGoalsCompleted = 'totalGoalsCompleted';
  static const goalsCompletedToday = 'goalsCompletedToday';
  static const goalsCompletedThisWeek = 'goalsCompletedThisWeek';
  static const goalsCompletedThisMonth = 'goalsCompletedThisMonth';
  static const goalsCompletedWithHighPoints = 'goalsCompletedWithHighPoints';
  static const goalsCompletedWithHighComplexity =
      'goalsCompletedWithHighComplexity';
  static const goalsCompletedWithHighEffort = 'goalsCompletedWithHighEffort';
  static const goalsCompletedWithHighMotivation =
      'goalsCompletedWithHighMotivation';
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

  // Category completion stats (achievements 100-105)
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
