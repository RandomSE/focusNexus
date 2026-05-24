import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:focusNexus/services/storage/flutter_secure_key_value_storage.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/utils/sound_volume.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static KeyValueStorage storage = const FlutterSecureKeyValueStorage();

  /// Test-only: inject storage between tests.
  static void resetForTesting() {
    storage = const FlutterSecureKeyValueStorage();
  }

  static Future<bool> checkSoundEnabled() async {
    final soundEnabled = await storage.read(key: 'soundEnabled');
    return bool.parse(soundEnabled ?? 'false');
  }

  static Future<double> getSoundVolume() async {
    final soundVolume = await storage.read(key: 'soundVolume');
    final parsed = double.tryParse(soundVolume ?? '0.0') ?? 0.0;
    final normalized = normalizeSoundVolume(parsed);
    debugPrint('played volume: $parsed (normalized: $normalized)');
    return normalized;
  }

  static Future<bool> checkIfSoundShouldBePlayed() async {
    if (await checkSoundEnabled()) {
      double soundVolume = await getSoundVolume();
      if (soundVolume > 0.0) {
        _player.setVolume(soundVolume);
        return true;
      } else {
        return false; // sound is enabled but set to 0 - don't send sound.
      }
    } else {
      return false; // sound is disabled.
    }
  }

  /// Play sound when a goal is created
  static Future<void> playGoalCreated() async {
    if (await checkIfSoundShouldBePlayed()) {
      await _player.play(AssetSource('sounds/goal_created.mp3'));
    }
  }

  /// Play sound when a goal is completed
  static Future<void> playGoalCompleted() async {
    if (await checkIfSoundShouldBePlayed()) {
      await _player.play(AssetSource('sounds/goal_completed.mp3'));
    }
  }

  /// Play sound when a goal is completed
  static Future<void> playAchievementCompleted() async {
    if (await checkIfSoundShouldBePlayed()) {
      await _player.play(AssetSource('sounds/achievement_completed.mp3'));
    }
  }
}