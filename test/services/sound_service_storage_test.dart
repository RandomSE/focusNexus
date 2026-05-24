import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/sound_service.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  tearDown(() {
    SoundService.resetForTesting();
  });

  test('checkSoundEnabled reads from injected storage', () async {
    SoundService.storage = InMemoryKeyValueStorage(initial: {'soundEnabled': 'true'});

    expect(await SoundService.checkSoundEnabled(), isTrue);
  });

  test('getSoundVolume normalizes stored value', () async {
    SoundService.storage = InMemoryKeyValueStorage(initial: {'soundVolume': '150'});

    expect(await SoundService.getSoundVolume(), 1.0);
  });

  test('checkIfSoundShouldBePlayed is false when disabled', () async {
    SoundService.storage = InMemoryKeyValueStorage(initial: {'soundEnabled': 'false'});

    expect(await SoundService.checkIfSoundShouldBePlayed(), isFalse);
  });

  test('checkIfSoundShouldBePlayed is false when volume is zero', () async {
    SoundService.storage = InMemoryKeyValueStorage(initial: {
      'soundEnabled': 'true',
      'soundVolume': '0',
    });

    expect(await SoundService.checkIfSoundShouldBePlayed(), isFalse);
  });
}
