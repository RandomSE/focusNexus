import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();


  static Future<bool> checkSoundEnabled() async {
    final soundEnabled = await _storage.read(key: 'soundEnabled');
    return bool.parse(soundEnabled ?? 'false');
  }

  static Future<double> getSoundVolume() async {
    final soundVolume = await _storage.read(key: 'soundVolume');
    final parsed = double.tryParse(soundVolume ?? '0.0') ?? 0.0;
    final normalized = (parsed.clamp(0.0, 100.0)) / 100.0;
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