import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/ambient_soundscape_repository.dart';
import 'package:focusNexus/services/ambient_section_playback.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/sound_service.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SoundService sound;

  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
    SoundService.ambientFadeDuration = Duration.zero;
    SoundService.ambientStartDelayForTesting = Duration.zero;
    sound = SoundService(InMemoryKeyValueStorage());
  });

  test('startAmbient tracks request without touching BGM counters', () async {
    await sound.startAmbient(SoundChannel.ambientRunningWater);
    expect(sound.isAmbientRequested, isTrue);
    expect(sound.isAmbientDucked, isFalse);
    expect(sound.ambientStartCount, 1);
    expect(sound.activeAmbientChannelForTesting, SoundChannel.ambientRunningWater);
    expect(sound.isBreathBackgroundRequested, isFalse);
  });

  test('stopAmbient clears ambient request', () async {
    await sound.startAmbient(SoundChannel.ambientWhiteNoise);
    await sound.stopAmbient();
    expect(sound.isAmbientRequested, isFalse);
    expect(sound.ambientStopCount, 1);
    expect(sound.activeAmbientChannelForTesting, isNull);
  });

  test('feature BGM hard-stops ambient; stopMusic does not restore it', () async {
    await sound.startAmbient(SoundChannel.ambientRunningWater);
    expect(sound.isAmbientRequested, isTrue);

    await sound.startMusic(SoundChannel.zenGardenMusic);
    expect(sound.activeFeatureMusicForTesting, SoundChannel.zenGardenMusic);
    expect(sound.isAmbientRequested, isFalse);
    expect(sound.activeAmbientChannelForTesting, isNull);
    expect(sound.ambientStopCount, greaterThanOrEqualTo(1));

    await sound.stopMusic();
    expect(sound.activeFeatureMusicForTesting, isNull);
    expect(sound.isAmbientRequested, isFalse);
  });

  test('startAmbient no-ops while feature BGM is active', () async {
    await sound.startMusic(SoundChannel.bonsaiMusic);
    expect(sound.activeFeatureMusicForTesting, SoundChannel.bonsaiMusic);

    await sound.startAmbient(SoundChannel.ambientWhiteNoise);
    expect(sound.isAmbientRequested, isFalse);
    expect(sound.ambientStartCount, 0);
    expect(sound.activeAmbientChannelForTesting, isNull);
  });

  test('ambient allowed when feature music channel is disabled', () async {
    final channels = await sound.loadChannelSettings();
    channels[SoundChannel.zenGardenMusic] = const SoundChannelSettings(
      enabled: false,
      volumePercent: 100,
    );
    await sound.saveChannelSettings(channels);

    await sound.startMusic(SoundChannel.zenGardenMusic);
    expect(sound.activeFeatureMusicForTesting, isNull);

    await sound.startAmbient(SoundChannel.ambientRunningWater);
    expect(sound.isAmbientRequested, isTrue);
    expect(
      sound.activeAmbientChannelForTesting,
      SoundChannel.ambientRunningWater,
    );
  });

  test('pauseAllMusicForAppBackground stops ambient and feature BGM', () async {
    await sound.startAmbient(SoundChannel.ambientRunningWater);
    await sound.startMusic(SoundChannel.cherryBalanceMusic);
    expect(sound.activeFeatureMusicForTesting, SoundChannel.cherryBalanceMusic);
    expect(sound.isAmbientRequested, isFalse);

    await sound.pauseAllMusicForAppBackground();
    expect(sound.isSuspendedForBackgroundForTesting, isTrue);
    expect(sound.activeFeatureMusicForTesting, isNull);
    expect(sound.isAmbientRequested, isFalse);

    await sound.resumeAfterAppForeground();
    expect(sound.isSuspendedForBackgroundForTesting, isFalse);
    expect(
      sound.activeFeatureMusicForTesting,
      SoundChannel.cherryBalanceMusic,
    );
    expect(sound.isAmbientRequested, isFalse);
  });

  test('resumeAfterAppForeground restores ambient-only when no feature BGM',
      () async {
    await sound.startAmbient(SoundChannel.ambientWhiteNoise);
    await sound.pauseAllMusicForAppBackground();
    expect(sound.isAmbientRequested, isFalse);

    await sound.resumeAfterAppForeground();
    expect(sound.activeFeatureMusicForTesting, isNull);
    // Ambient restore is coordinator-owned; SoundService alone does not restart it.
    expect(sound.isAmbientRequested, isFalse);
  });

  test('previewAmbient allows locked piano track', () async {
    await sound.previewAmbient(SoundChannel.ambientPiano);
    expect(sound.isAmbientRequested, isTrue);
    expect(sound.activeAmbientChannelForTesting, SoundChannel.ambientPiano);
  });

  test('startAmbient no-ops when sound disabled', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'}),
    );
    await sound.startAmbient(SoundChannel.ambientRunningWater);
    expect(sound.isAmbientRequested, isFalse);
    expect(sound.ambientStartCount, 0);
  });

  test('superseded startAmbient does not win after stopAmbient', () async {
    SoundService.ambientStartDelayForTesting = const Duration(milliseconds: 40);
    final slow = sound.startAmbient(SoundChannel.ambientRunningWater);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await sound.stopAmbient();
    await slow;
    expect(sound.isAmbientRequested, isFalse);
    expect(sound.activeAmbientChannelForTesting, isNull);

    await sound.startAmbient(SoundChannel.ambientWhiteNoise);
    expect(sound.isAmbientRequested, isTrue);
    expect(
      sound.activeAmbientChannelForTesting,
      SoundChannel.ambientWhiteNoise,
    );
  });

  test('newer startAmbient supersedes older in-flight start', () async {
    SoundService.ambientStartDelayForTesting = const Duration(milliseconds: 40);
    final first = sound.startAmbient(SoundChannel.ambientRunningWater);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = sound.startAmbient(SoundChannel.ambientWhiteNoise);
    await Future.wait([first, second]);
    expect(sound.isAmbientRequested, isTrue);
    expect(
      sound.activeAmbientChannelForTesting,
      SoundChannel.ambientWhiteNoise,
    );
  });

  test('musicStartOffsetFor skips quiet head on feature and ambient beds', () {
    expect(
      SoundService.musicStartOffsetFor(SoundChannel.zenGardenMusic),
      greaterThan(Duration.zero),
    );
    expect(
      SoundService.musicStartOffsetFor(SoundChannel.ambientRunningWater),
      greaterThan(Duration.zero),
    );
    expect(
      SoundService.musicStartOffsetFor(SoundChannel.breathBackground),
      Duration.zero,
    );
  });

  test('feature BGM start hard-stops ambient without requiring fade', () async {
    SoundService.ambientFadeDuration = const Duration(milliseconds: 800);
    await sound.startAmbient(SoundChannel.ambientRunningWater);
    final sw = Stopwatch()..start();
    await sound.startMusic(SoundChannel.bonsaiMusic);
    sw.stop();
    expect(sound.isAmbientRequested, isFalse);
    // Must not wait a full ambient fade before BGM is considered started.
    expect(sw.elapsedMilliseconds, lessThan(500));
  });

  test('prepareAmbient then startAmbient reuses prepared standby without second load',
      () async {
    await sound.prepareAmbient(SoundChannel.ambientOceanWaves);
    expect(sound.musicAssetSetSourceCount, 1);
    expect(
      sound.ambientStandbyPreparedPathForTesting,
      SoundChannel.ambientOceanWaves.assetPath,
    );

    await sound.startAmbient(SoundChannel.ambientOceanWaves);
    expect(sound.musicAssetSetSourceCount, 1);
    expect(
      sound.ambientPreparedPathForTesting,
      SoundChannel.ambientOceanWaves.assetPath,
    );
    expect(sound.activeAmbientChannelForTesting, SoundChannel.ambientOceanWaves);
  });

  test('prepareMusic marks feature path for instant startMusic reuse', () async {
    await sound.prepareMusic(SoundChannel.zenGardenMusic);
    expect(sound.musicAssetSetSourceCount, 1);
    expect(
      sound.bgmPreparedPathForTesting,
      SoundChannel.zenGardenMusic.assetPath,
    );
    await sound.startMusic(SoundChannel.zenGardenMusic);
    // Test-mode startMusic does not cold-load again when path is prepared.
    expect(sound.musicAssetSetSourceCount, 1);
    expect(
      sound.activeFeatureMusicForTesting,
      SoundChannel.zenGardenMusic,
    );
  });

  test('stopMusicIfChannel does not kill a newer feature track', () async {
    await sound.startMusic(SoundChannel.cherryPowerMusic);
    expect(sound.activeFeatureMusicForTesting, SoundChannel.cherryPowerMusic);

    await sound.startMusic(SoundChannel.zenGardenMusic);
    expect(sound.activeFeatureMusicForTesting, SoundChannel.zenGardenMusic);

    await sound.stopMusicIfChannel(SoundChannel.cherryPowerMusic);
    expect(sound.activeFeatureMusicForTesting, SoundChannel.zenGardenMusic);
    expect(sound.hasActiveFeatureMusic, isTrue);

    await sound.stopMusicIfChannel(SoundChannel.zenGardenMusic);
    expect(sound.activeFeatureMusicForTesting, isNull);
    expect(sound.hasActiveFeatureMusic, isFalse);
  });

  test('disabled breath falls back to mini-games ambient', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        'soundEnabled': 'true',
        'volume': '1.0',
        'musicVolume': '1.0',
      },
    );
    // Seed ambient via repo path used by coordinator.
    final repo = AmbientSoundscapeRepository(storage);
    await repo.writeEnabled(true);
    await repo.applyTrackToAllSections('white_noise');
    final coordinator = AmbientPlaybackCoordinator();
    final s = SoundService(storage);
    SoundService.suppressNativePlaybackForTesting = true;

    final channels = await s.loadChannelSettings();
    channels[SoundChannel.breathBackground] = const SoundChannelSettings(
      enabled: false,
      volumePercent: 100,
    );
    await s.saveChannelSettings(channels);

    final started = await startFeatureMusicOrAmbientFallback(
      sounds: s,
      repo: repo,
      coordinator: coordinator,
      featureChannel: SoundChannel.breathBackground,
      section: AmbientAppSection.miniGames,
    );
    expect(started, isFalse);
    expect(s.isAmbientRequested, isTrue);
    expect(
      s.activeAmbientChannelForTesting,
      SoundChannel.ambientWhiteNoise,
    );
  });
}
