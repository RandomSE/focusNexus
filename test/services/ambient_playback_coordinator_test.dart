import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/ambient_soundscape_repository.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryKeyValueStorage storage;
  late AmbientSoundscapeRepository repo;
  late SoundService sounds;
  late AmbientPlaybackCoordinator coordinator;

  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
    SoundService.ambientFadeDuration = Duration.zero;
    SoundService.ambientStartDelayForTesting = Duration.zero;
    storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.points: '1000',
        StorageKeys.ambientEnabled: 'true',
        StorageKeys.ambientGlobalTrackId: 'running_water',
      },
    );
    repo = AmbientSoundscapeRepository(storage);
    sounds = SoundService(storage);
    coordinator = AmbientPlaybackCoordinator();
  });

  test('leave of previous section does not stop newer section ambient', () async {
    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.dashboard,
    );
    expect(sounds.isAmbientRequested, isTrue);

    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.goals,
    );
    await coordinator.leave(AmbientAppSection.dashboard);

    expect(coordinator.activeSection, AmbientAppSection.goals);
    expect(sounds.isAmbientRequested, isTrue);
    expect(
      sounds.activeAmbientChannelForTesting,
      SoundChannel.ambientRunningWater,
    );
  });

  test('applyForSection starts ambient immediately', () async {
    await coordinator.applyForSection(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.achievements,
    );
    expect(sounds.isAmbientRequested, isTrue);
    expect(sounds.ambientStartCount, greaterThan(0));
  });

  test('route name map covers hub screens and phrase pack editors', () {
    expect(
      ambientSectionForRouteName('dashboard'),
      AmbientAppSection.dashboard,
    );
    expect(ambientSectionForRouteName('goals'), AmbientAppSection.goals);
    expect(
      ambientSectionForRouteName('cherry_blossom_tree'),
      AmbientAppSection.progressiveVisuals,
    );
    expect(
      ambientSectionForRouteName('settings'),
      AmbientAppSection.settings,
    );
    expect(
      ambientSectionForRouteName('background_music'),
      AmbientAppSection.customization,
    );
    expect(
      ambientSectionForRouteName('customization'),
      AmbientAppSection.customization,
    );
    expect(
      ambientSectionForRouteName('dashboard_motivator_pack'),
      AmbientAppSection.customization,
    );
    expect(
      ambientSectionForRouteName('daily_affirmation_pack'),
      AmbientAppSection.customization,
    );
    expect(ambientSectionForRouteName('reward'), isNull);
  });

  test('feature-BGM routes are flagged for ambient suppress', () {
    expect(routeOwnsFeatureBgm('progressive_visual'), isTrue);
    expect(routeOwnsFeatureBgm('progressive_visual_section'), isTrue);
    expect(routeOwnsFeatureBgm('cherry_blossom_tree'), isTrue);
    expect(routeOwnsFeatureBgm('mini_game_play'), isTrue);
    expect(routeOwnsFeatureBgm('dashboard'), isFalse);
    expect(routeOwnsFeatureBgm(null), isFalse);
  });

  test('enter on feature section does not start ambient while feature BGM on',
      () async {
    await sounds.startMusic(SoundChannel.zenGardenMusic);
    expect(sounds.hasActiveFeatureMusic, isTrue);

    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.progressiveVisuals,
    );

    expect(sounds.isAmbientRequested, isFalse);
    expect(sounds.activeAmbientChannelForTesting, isNull);
    expect(sounds.hasActiveFeatureMusic, isTrue);
  });

  test('syncTop for feature route notes section without stopping ambient', () async {
    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.customization,
    );
    expect(sounds.isAmbientRequested, isTrue);

    await syncAmbientForTopRoute(
      routeName: 'cherry_blossom_tree',
      repo: repo,
      sounds: sounds,
      coordinator: coordinator,
    );

    expect(coordinator.activeSection, AmbientAppSection.progressiveVisuals);
    // Ambient stays up until feature startMusic hard-stops it (or fallback keeps it).
    expect(sounds.isAmbientRequested, isTrue);
    expect(
      sounds.activeAmbientChannelForTesting,
      SoundChannel.ambientRunningWater,
    );
  });

  test(
    'disabled Power music falls back to ambient after cherry feature sync',
    () async {
      await repo.applyTrackToAllSections('running_water');
      await repo.writeEnabled(true);
      final channels = await sounds.loadChannelSettings();
      channels[SoundChannel.cherryPowerMusic] = const SoundChannelSettings(
        enabled: false,
        volumePercent: 100,
      );
      await sounds.saveChannelSettings(channels);

      await coordinator.enter(
        repo: repo,
        sounds: sounds,
        section: AmbientAppSection.customization,
      );
      expect(sounds.isAmbientRequested, isTrue);

      await syncAmbientForTopRoute(
        routeName: 'cherry_blossom_tree',
        repo: repo,
        sounds: sounds,
        coordinator: coordinator,
      );
      expect(sounds.isAmbientRequested, isTrue);

      final started = await startFeatureMusicOrAmbientFallback(
        sounds: sounds,
        repo: repo,
        coordinator: coordinator,
        featureChannel: SoundChannel.cherryPowerMusic,
      );

      expect(started, isFalse);
      expect(sounds.hasActiveFeatureMusic, isFalse);
      expect(sounds.isAmbientRequested, isTrue);
      expect(
        sounds.activeAmbientChannelForTesting,
        SoundChannel.ambientRunningWater,
      );
    },
  );

  test(
    'audible Power music still hard-stops ambient via feature fallback helper',
    () async {
      await repo.applyTrackToAllSections('running_water');
      await repo.writeEnabled(true);
      await coordinator.enter(
        repo: repo,
        sounds: sounds,
        section: AmbientAppSection.customization,
      );

      final started = await startFeatureMusicOrAmbientFallback(
        sounds: sounds,
        repo: repo,
        coordinator: coordinator,
        featureChannel: SoundChannel.cherryPowerMusic,
      );

      expect(started, isTrue);
      expect(sounds.hasActiveFeatureMusic, isTrue);
      expect(sounds.isAmbientRequested, isFalse);
      expect(
        sounds.activeFeatureMusicForTesting,
        SoundChannel.cherryPowerMusic,
      );
    },
  );

  test('syncTop for unnamed bonsai route does not resurrect ambient', () async {
    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.progressiveVisuals,
    );
    expect(sounds.isAmbientRequested, isTrue);
    await sounds.startMusic(SoundChannel.cherryBalanceMusic);

    // Unnamed MaterialPageRoute (bonsai garden) previously called resume.
    await syncAmbientForTopRoute(
      routeName: null,
      repo: repo,
      sounds: sounds,
      coordinator: coordinator,
    );

    expect(sounds.isAmbientRequested, isFalse);
    expect(sounds.activeAmbientChannelForTesting, isNull);
    expect(sounds.hasActiveFeatureMusic, isTrue);
  });

  test('syncTop for dashboard stops leftover feature BGM then starts ambient',
      () async {
    await sounds.startMusic(SoundChannel.zenGardenMusic);
    expect(sounds.hasActiveFeatureMusic, isTrue);

    await syncAmbientForTopRoute(
      routeName: 'dashboard',
      repo: repo,
      sounds: sounds,
      coordinator: coordinator,
    );

    expect(sounds.hasActiveFeatureMusic, isFalse);
    expect(sounds.isAmbientRequested, isTrue);
    expect(
      sounds.activeAmbientChannelForTesting,
      SoundChannel.ambientRunningWater,
    );
  });

  test('leave of active section does not clear or stop ambient', () async {
    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.dashboard,
    );
    await coordinator.leave(AmbientAppSection.dashboard);
    expect(coordinator.activeSection, AmbientAppSection.dashboard);
    expect(sounds.isAmbientRequested, isTrue);
  });

  test('leave never clears newer active section and does not stop audio', () async {
    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.progressiveVisuals,
    );
    await coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.dashboard,
    );
    await coordinator.leave(AmbientAppSection.progressiveVisuals);
    expect(coordinator.activeSection, AmbientAppSection.dashboard);
    expect(sounds.isAmbientRequested, isTrue);
  });

  test('in-flight apply for old section loses to newer section', () async {
    SoundService.ambientStartDelayForTesting = const Duration(milliseconds: 50);
    final first = coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.progressiveVisuals,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = coordinator.enter(
      repo: repo,
      sounds: sounds,
      section: AmbientAppSection.dashboard,
    );
    await Future.wait([first, second]);
    expect(coordinator.activeSection, AmbientAppSection.dashboard);
    expect(sounds.isAmbientRequested, isTrue);
    expect(
      sounds.activeAmbientChannelForTesting,
      SoundChannel.ambientRunningWater,
    );
  });
}
