import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/sound_service.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SoundService sound;

  setUp(() {
    sound = SoundService(InMemoryKeyValueStorage());
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
      InMemoryKeyValueStorage(initial: {
        'soundEnabled': 'true',
        'soundVolume': '0',
      }),
    );

    expect(await sound.checkIfSoundShouldBePlayed(), isFalse);
  });

  test('warmPlaybackCache avoids repeat storage reads', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        'soundEnabled': 'true',
        'soundVolume': '100',
      },
    );
    sound = SoundService(storage);

    await sound.warmPlaybackCache();
    await storage.write(key: 'soundEnabled', value: 'false');

    expect(await sound.checkIfSoundShouldBePlayed(), isTrue);
  });
}
