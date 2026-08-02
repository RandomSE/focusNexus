import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/breath_pacer/breath_pacer_constants.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/sound_channel.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SoundService sound;

  setUp(() {
    SoundService.suppressNativePlaybackForTesting = true;
    sound = SoundService(InMemoryKeyValueStorage());
  });

  tearDown(() {
    SoundService.suppressNativePlaybackForTesting = false;
  });

  test('checkSoundEnabled reads from injected storage', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(initial: {'soundEnabled': 'true'}),
    );

    expect(await sound.checkSoundEnabled(), isTrue);
  });

  test('getSoundVolume normalizes stored value', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(initial: {'soundVolume': '150'}),
    );

    expect(await sound.getSoundVolume(), 1.0);
  });

  test('checkIfSoundShouldBePlayed is false when disabled', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'}),
    );

    expect(await sound.checkIfSoundShouldBePlayed(), isFalse);
  });

  test('checkIfSoundShouldBePlayed is false when volume is zero', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(
        initial: {'soundEnabled': 'true', 'soundVolume': '0'},
      ),
    );

    expect(await sound.checkIfSoundShouldBePlayed(), isFalse);
  });

  test('playFireflyClick no-ops when sound disabled', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'}),
    );

    await sound.playFireflyClick();
    expect(await sound.checkIfSoundShouldBePlayed(), isFalse);
  });

  test('warmPlaybackCache avoids repeat storage reads', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {'soundEnabled': 'true', 'soundVolume': '100'},
    );
    sound = SoundService(storage);

    await sound.warmPlaybackCache();
    await storage.write(key: 'soundEnabled', value: 'false');

    expect(await sound.checkIfSoundShouldBePlayed(), isTrue);
  });

  test('empty storage defaults to sound enabled at full volume', () async {
    sound = SoundService(InMemoryKeyValueStorage());

    expect(await sound.checkSoundEnabled(), isTrue);
    expect(await sound.getSoundVolume(), 1.0);
    expect(await sound.checkIfSoundShouldBePlayed(), isTrue);
  });

  test(
    'invalidatePlaybackCache picks up settings changes after warm',
    () async {
      final storage = InMemoryKeyValueStorage(
        initial: {'soundEnabled': 'false', 'soundVolume': '0'},
      );
      sound = SoundService(storage);

      await sound.warmPlaybackCache();
      expect(await sound.checkIfSoundShouldBePlayed(), isFalse);

      await storage.write(key: 'soundEnabled', value: 'true');
      await storage.write(key: 'soundVolume', value: '100');
      sound.invalidatePlaybackCache();

      expect(await sound.checkIfSoundShouldBePlayed(), isTrue);
    },
  );

  test('rapid firefly clicks start overlapping plays', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(
        initial: {'soundEnabled': 'true', 'soundVolume': '100'},
      ),
    );

    await Future.wait([
      sound.playFireflyClick(),
      sound.playFireflyClick(),
      sound.playFireflyClick(),
      sound.playFireflyClick(),
    ]);

    expect(sound.fireflyPlayStartCount, 4);
  });

  test(
    'late-overlap meteor clicks use distinct pool slots before wrap',
    () async {
      sound = SoundService(
        InMemoryKeyValueStorage(
          initial: {'soundEnabled': 'true', 'soundVolume': '100'},
        ),
      );

      // Simulate catches near end of a still-playing meteor_click: each start
      // must claim a fresh dedicated slot so stop()+restart cannot mute/echo.
      await sound.playMeteorClick();
      await sound.playMeteorClick();
      await sound.playMeteorClick();

      expect(sound.meteorPlayStartCount, 3);
      expect(sound.meteorPlayPlayerSlots, hasLength(3));
      expect(sound.meteorPlayPlayerSlots.toSet(), hasLength(3));
      expect(
        sound.meteorPlayPlayerSlots.every(
          (slot) =>
              slot >= 0 && slot < SoundService.meteorSfxPoolSize,
        ),
        isTrue,
      );
    },
  );

  test('playFireflyClick returns quickly (no await on clip end)', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(
        initial: {'soundEnabled': 'true', 'soundVolume': '100'},
      ),
    );

    final sw = Stopwatch()..start();
    await sound.playFireflyClick();
    sw.stop();

    expect(sw.elapsed, lessThan(const Duration(milliseconds: 500)));
    expect(sound.fireflyPlayStartCount, 1);
  });

  test('Breath background allows long asset preparation', () {
    expect(
      SoundService.backgroundPlaybackStartTimeout,
      greaterThan(SoundService.sfxPlaybackStartTimeout),
    );
    expect(
      SoundService.backgroundPlaybackStartTimeout,
      greaterThanOrEqualTo(const Duration(seconds: 20)),
    );
  });

  test('Breath background starts with default sound preferences', () async {
    await sound.startBreathBackground(loop: false);

    expect(sound.breathBackgroundStartCount, 1);
  });

  test(
    'Breath click mixes directly without ducking background playback',
    () async {
      await sound.startBreathBackground(loop: true);
      expect(sound.isBreathBackgroundRequested, isTrue);

      await sound.playBreathClick();

      expect(sound.isBreathBackgroundRequested, isTrue);
      expect(sound.breathBackgroundStopCount, 0);
      expect(sound.breathClickPlayStartCount, 1);
      expect(sound.breathClickDirectStartCount, 1);
      expect(sound.breathBackgroundDuckCount, 0);
    },
  );

  test('Breath click uses mp3 asset under sounds/', () {
    expect(SoundChannel.breathClick.assetPath, 'sounds/breath_click.mp3');
    expect(BreathPacerConstants.clickSoundAsset, 'sounds/breath_click.mp3');
    final file = File('assets/sounds/breath_click.mp3');
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(1000));
  });

  test('Breath background music lives under sounds/music/', () {
    expect(
      SoundChannel.breathBackground.assetPath,
      'sounds/music/breath_background.mp3',
    );
    expect(
      BreathPacerConstants.backgroundSoundAsset,
      'sounds/music/breath_background.mp3',
    );
    final file = File('assets/sounds/music/breath_background.mp3');
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(1000));
  });

  test('music volume multiplies BGM gain and persists', () async {
    await sound.setMusicVolumePercent(50);
    expect(await sound.getMusicVolume(), closeTo(0.5, 0.001));
    sound.clearPlaybackCacheForTesting();
    expect(await sound.getMusicVolume(), closeTo(0.5, 0.001));

    await sound.startMusic(SoundChannel.zenGardenMusic);
    expect(sound.breathBackgroundStartCount, 0);
    // Zen garden is music; suppress mode still records request path via BGM start.
    expect(sound.isBreathBackgroundRequested, isTrue);
  });

  test('bundled music tracks exist on disk', () {
    for (final channel in SoundChannel.values.where((c) => c.isMusic)) {
      final file = File('assets/${channel.assetPath}');
      expect(file.existsSync(), isTrue, reason: channel.assetPath);
      expect(file.lengthSync(), greaterThan(1000), reason: channel.assetPath);
    }
  });

  test('attenuated channels apply 0.6 play-time gain and still start', () async {
    sound = SoundService(
      InMemoryKeyValueStorage(
        initial: {'soundEnabled': 'true', 'soundVolume': '100'},
      ),
    );

    await sound.playMeteorClick();
    expect(sound.meteorPlayStartCount, 1);
    expect(sound.lastAppliedGain, closeTo(0.5, 0.001));

    await sound.playGameFailed();
    expect(sound.lastAppliedGain, closeTo(0.6, 0.001));

    await sound.playAchievementCompleted();
    expect(sound.lastAppliedGain, closeTo(0.6, 0.001));

    await sound.playFireflyClick();
    expect(sound.fireflyPlayStartCount, 1);
    expect(sound.lastAppliedGain, closeTo(1.0, 0.001));

    await sound.playBreathClick();
    expect(sound.lastAppliedGain, closeTo(1.5, 0.001));
  });

  test('Breath click uses media stream without taking audio focus', () {
    final context = SoundService.breathClickAudioContextForTesting.android;

    expect(context.contentType, AndroidContentType.sonification);
    expect(context.usageType, AndroidUsageType.media);
    expect(context.audioFocus, AndroidAudioFocus.none);
  });

  test('default SFX and global context use media stream (not UI sonification)', () {
    final sfx = SoundService.sfxAudioContextForTesting.android;
    final global = SoundService.globalAudioContextForTesting.android;

    expect(sfx.usageType, AndroidUsageType.media);
    expect(sfx.audioFocus, AndroidAudioFocus.none);
    expect(global.usageType, AndroidUsageType.media);
    expect(global.usageType, isNot(AndroidUsageType.assistanceSonification));
  });

  test(
    'channel settings persist and mute firefly without master mute',
    () async {
      final storage = InMemoryKeyValueStorage(
        initial: {'soundEnabled': 'true', 'soundVolume': '100'},
      );
      sound = SoundService(storage);

      final channels = await sound.loadChannelSettings();
      channels[SoundChannel.fireflyClick] = const SoundChannelSettings(
        enabled: false,
        volumePercent: 100,
      );
      await sound.saveChannelSettings(channels);

      await sound.playFireflyClick();
      expect(sound.fireflyPlayStartCount, 0);
    },
  );
}
