import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/repositories/ambient_soundscape_repository.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';

/// Maps a named route to the ambient section that should play on top.
///
/// Uses string names (not [AppRoute] types) to avoid import cycles with screens.
AmbientAppSection? ambientSectionForRouteName(String? name) {
  return switch (name) {
    'dashboard' => AmbientAppSection.dashboard,
    'goals' ||
    'time_window_hub' ||
    'time_window_manual' ||
    'time_window_calendar' ||
    'time_window_bulk' =>
      AmbientAppSection.goals,
    'achievements' || 'consistency_explorer' => AmbientAppSection.achievements,
    'mini_games' || 'mini_game_lobby' || 'mini_game_play' =>
      AmbientAppSection.miniGames,
    'chat' => AmbientAppSection.aiChat,
    'progressive_visual' ||
    'progressive_visual_section' ||
    'cherry_blossom_tree' =>
      AmbientAppSection.progressiveVisuals,
    'customization' ||
    'custom_affirmation_pack' ||
    'dashboard_motivator_pack' ||
    'daily_affirmation_pack' ||
    'background_music' =>
      AmbientAppSection.customization,
    'settings' => AmbientAppSection.settings,
    'music' || 'sound_effects' => AmbientAppSection.music,
    _ => null,
  };
}

/// Screens that start their own looping feature BGM (zen / cherry / etc.).
/// Customization ambient must not play on these while feature BGM is active.
bool routeOwnsFeatureBgm(String? name) {
  return switch (name) {
    'progressive_visual' ||
    'progressive_visual_section' ||
    'cherry_blossom_tree' ||
    'mini_game_play' =>
      true,
    _ => false,
  };
}

/// Shared top-route sync used by [AmbientRouteObserver] (and unit tests).
Future<void> syncAmbientForTopRoute({
  required String? routeName,
  required AmbientSoundscapeRepository repo,
  required SoundService sounds,
  required AmbientPlaybackCoordinator coordinator,
}) async {
  // Feature-BGM screens own audio handoff via startMusic / ambient fallback.
  // Do not stop ambient here: that left silence when feature channels were disabled,
  // and raced with the previous screen's dispose stopMusic.
  if (routeOwnsFeatureBgm(routeName)) {
    final section = ambientSectionForRouteName(routeName);
    if (section != null) {
      coordinator.noteActiveSection(section);
    }
    return;
  }

  final section = ambientSectionForRouteName(routeName);
  if (section == null) {
    // Unnamed routes (e.g. bonsai MaterialPageRoute) must NOT resume ambient.
    // Resuming here was resurrecting customization music under feature BGM.
    await sounds.stopAmbient(fade: false);
    return;
  }

  // Entering a normal ambient section (dashboard, etc.): drop leftover feature
  // BGM from the previous screen so ambient can start (dispose may lag).
  await sounds.stopMusic();
  await coordinator.enter(repo: repo, sounds: sounds, section: section);
}

/// Re-applies ambient whenever the top route is an ambient section.
/// Fixes silent resumes when a screen stays mounted under the stack (pop back).
class AmbientRouteObserver extends NavigatorObserver {
  AmbientRouteObserver(this._container);

  final ProviderContainer _container;

  void _syncTop(Route<dynamic>? route) {
    final repo = _container.read(appRepositoriesProvider).ambientSoundscapes;
    final sounds = _container.read(soundServiceProvider);
    final coordinator = _container.read(ambientPlaybackCoordinatorProvider);
    unawaited(
      syncAmbientForTopRoute(
        routeName: route?.settings.name,
        repo: repo,
        sounds: sounds,
        coordinator: coordinator,
      ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncTop(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncTop(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _syncTop(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncTop(previousRoute);
  }
}

/// Keeps the active ambient section so leave/dispose races do not stop music
/// after a newer screen has already entered.
class AmbientPlaybackCoordinator {
  AmbientAppSection? _activeSection;
  int _applyGeneration = 0;

  AmbientAppSection? get activeSection => _activeSection;

  /// Remembers section without starting playback (feature-BGM routes).
  void noteActiveSection(AmbientAppSection section) {
    _activeSection = section;
  }

  Future<void> enter({
    required AmbientSoundscapeRepository repo,
    required SoundService sounds,
    required AmbientAppSection section,
  }) async {
    _activeSection = section;
    await _apply(repo: repo, sounds: sounds, section: section);
  }

  /// Leave never stops audio and never clears [_activeSection].
  /// Screen dispose must not race with [AmbientRouteObserver] re-enter.
  Future<void> leave(AmbientAppSection section) async {}

  /// Re-applies the active section (or [fallback]) after picker/preview.
  Future<void> resume({
    required AmbientSoundscapeRepository repo,
    required SoundService sounds,
    AmbientAppSection fallback = AmbientAppSection.dashboard,
  }) async {
    final section = _activeSection ?? fallback;
    _activeSection = section;
    await _apply(repo: repo, sounds: sounds, section: section);
  }

  Future<void> applyForSection({
    required AmbientSoundscapeRepository repo,
    required SoundService sounds,
    required AmbientAppSection section,
  }) async {
    _activeSection = section;
    await _apply(repo: repo, sounds: sounds, section: section);
  }

  Future<void> stopAll(SoundService sounds) async {
    _applyGeneration++;
    _activeSection = null;
    await sounds.stopAmbient();
  }

  Future<void> _apply({
    required AmbientSoundscapeRepository repo,
    required SoundService sounds,
    required AmbientAppSection section,
  }) async {
    final gen = ++_applyGeneration;
    // Feature BGM owns the speakers; never layer customization ambient.
    if (sounds.hasActiveFeatureMusic) {
      await sounds.stopAmbient(fade: false);
      return;
    }
    final channel = await repo.resolveForSection(section);
    if (gen != _applyGeneration) return;
    if (_activeSection != section) return;
    if (sounds.hasActiveFeatureMusic) {
      await sounds.stopAmbient(fade: false);
      return;
    }
    if (channel == null) {
      await sounds.stopAmbient();
      return;
    }
    // Prepare-ahead when switching tracks; same-track startAmbient reuses source.
    await sounds.prepareAmbient(channel);
    if (gen != _applyGeneration) return;
    if (_activeSection != section) return;
    await sounds.startAmbient(channel);
  }
}

/// Starts feature BGM, or customization ambient when that channel cannot play.
///
/// Feature routes stop ambient optimistically; if Power/zen/etc. music is disabled
/// in Sound effects, this restores ambient so the screen is not silent.
Future<bool> startFeatureMusicOrAmbientFallback({
  required SoundService sounds,
  required AmbientSoundscapeRepository repo,
  required AmbientPlaybackCoordinator coordinator,
  required SoundChannel featureChannel,
  AmbientAppSection section = AmbientAppSection.progressiveVisuals,
  bool loop = true,
}) async {
  final audible = await sounds.isMusicChannelAudible(featureChannel);
  if (audible) {
    await sounds.prepareMusic(featureChannel);
    final started = await sounds.startMusic(featureChannel, loop: loop);
    if (started) return true;
  }
  await sounds.stopMusic();
  await coordinator.enter(repo: repo, sounds: sounds, section: section);
  return false;
}

final ambientPlaybackCoordinatorProvider =
    Provider<AmbientPlaybackCoordinator>((ref) {
  return AmbientPlaybackCoordinator();
});

/// Starts the resolved ambient track for [section] (post-frame safe).
Future<void> enterAmbientSection({
  required WidgetRef ref,
  required AmbientAppSection section,
}) async {
  final repo = ref.read(appRepositoriesProvider).ambientSoundscapes;
  final sounds = ref.read(soundServiceProvider);
  final coordinator = ref.read(ambientPlaybackCoordinatorProvider);
  await coordinator.enter(repo: repo, sounds: sounds, section: section);
}

/// No-op retained for call-site compatibility; prefer [AmbientRouteObserver].
Future<void> leaveAmbientSection({
  required WidgetRef ref,
  required AmbientAppSection section,
}) async {
  await ref.read(ambientPlaybackCoordinatorProvider).leave(section);
}
