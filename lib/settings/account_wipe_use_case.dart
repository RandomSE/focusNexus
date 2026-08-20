import 'package:focusNexus/models/classes/achievement_tracking_variables.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/settings/app_settings.dart';
import 'package:focusNexus/utils/notifier.dart';

/// Orchestrates local account wipe side effects (dialogs stay in the UI layer).
class AccountWipeUseCase {
  AccountWipeUseCase({
    required AppRepositories repos,
    required AppSettings settings,
    required AchievementService achievements,
    required SoundService sounds,
    required AmbientPlaybackCoordinator ambientCoordinator,
    required Future<void> Function() resetZenGardenSession,
    required void Function() bumpAchievementsList,
    required void Function() invalidatePointsBalance,
  })  : _repos = repos,
        _settings = settings,
        _achievements = achievements,
        _sounds = sounds,
        _ambientCoordinator = ambientCoordinator,
        _resetZenGardenSession = resetZenGardenSession,
        _bumpAchievementsList = bumpAchievementsList,
        _invalidatePointsBalance = invalidatePointsBalance;

  final AppRepositories _repos;
  final AppSettings _settings;
  final AchievementService _achievements;
  final SoundService _sounds;
  final AmbientPlaybackCoordinator _ambientCoordinator;
  final Future<void> Function() _resetZenGardenSession;
  final void Function() _bumpAchievementsList;
  final void Function() _invalidatePointsBalance;

  /// Wipes local user data and restores default preferences.
  ///
  /// Order matters: clear keepAlive garden first so dispose cannot re-save onto
  /// wiped disk and so cherry flags are not re-flipped from a stale unlocked tree.
  Future<void> execute() async {
    await _resetZenGardenSession();
    await _ambientCoordinator.stopAll(_sounds);
    await _sounds.stopMusic();
    _sounds.invalidatePlaybackCache();
    await _repos.wipeAllUserData();
    await _achievements.clearAll();
    await AchievementTrackingVariables().reset();
    await _achievements.initialize();
    _bumpAchievementsList();
    _invalidatePointsBalance();
    await GoalNotifier.purgeAllScheduledNotifications();
    await _settings.applyDefaultPreferences();
  }
}
