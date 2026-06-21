import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/sound_volume.dart';

class SoundService {
  SoundService(this._storage);

  final KeyValueStorage _storage;
  AudioPlayer? _player;
  bool? _cachedSoundEnabled;
  double? _cachedVolume;

  AudioPlayer get _effectivePlayer => _player ??= AudioPlayer();

  @visibleForTesting
  void clearPlaybackCacheForTesting() {
    _cachedSoundEnabled = null;
    _cachedVolume = null;
  }

  /// Preloads sound prefs so completion playback skips storage I/O.
  Future<void> warmPlaybackCache() async {
    await _ensurePlaybackCache();
  }

  Future<void> _ensurePlaybackCache() async {
    _cachedSoundEnabled ??=
        bool.tryParse(
          await _storage.read(key: StorageKeys.soundEnabled) ?? 'false',
        ) ??
        false;
    if (_cachedSoundEnabled!) {
      final raw = await _storage.read(key: StorageKeys.soundVolume);
      _cachedVolume = normalizeSoundVolume(
        double.tryParse(raw ?? '0.0') ?? 0.0,
      );
    } else {
      _cachedVolume = 0.0;
    }
  }

  Future<bool> checkSoundEnabled() async {
    if (_cachedSoundEnabled != null) return _cachedSoundEnabled!;
    final soundEnabled = await _storage.read(key: StorageKeys.soundEnabled);
    _cachedSoundEnabled = bool.parse(soundEnabled ?? 'false');
    return _cachedSoundEnabled!;
  }

  Future<double> getSoundVolume() async {
    if (_cachedVolume != null) return _cachedVolume!;
    final soundVolume = await _storage.read(key: StorageKeys.soundVolume);
    final parsed = double.tryParse(soundVolume ?? '0.0') ?? 0.0;
    final normalized = normalizeSoundVolume(parsed);
    debugPrint('played volume: $parsed (normalized: $normalized)');
    _cachedVolume = normalized;
    return normalized;
  }

  Future<bool> checkIfSoundShouldBePlayed() async {
    await _ensurePlaybackCache();
    if (_cachedSoundEnabled! && _cachedVolume! > 0.0) {
      _effectivePlayer.setVolume(_cachedVolume!);
      return true;
    }
    return false;
  }

  Future<void> playGoalCreated() async {
    if (await checkIfSoundShouldBePlayed()) {
      await _effectivePlayer.play(AssetSource('sounds/goal_created.mp3'));
    }
  }

  Future<void> playGoalCompleted() async {
    if (await checkIfSoundShouldBePlayed()) {
      await _effectivePlayer.play(AssetSource('sounds/goal_completed.mp3'));
    }
  }

  Future<void> playAchievementCompleted() async {
    if (await checkIfSoundShouldBePlayed()) {
      await _effectivePlayer.play(AssetSource('sounds/achievement_completed.mp3'));
    }
  }
}
