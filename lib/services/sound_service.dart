import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show VoidCallback, visibleForTesting;
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/debug_log.dart';
import 'package:focusNexus/utils/sound_volume.dart';

class SoundService {
  SoundService(this._storage);

  final KeyValueStorage _storage;
  AudioPlayer? _oneshotPlayer;
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _breathClickPlayer;
  StreamSubscription<void>? _bgmCompleteSub;
  final List<AudioPlayer> _sfxPool = <AudioPlayer>[];
  int _sfxPoolIndex = 0;
  final List<AudioPlayer> _meteorSfxPool = <AudioPlayer>[];
  int _meteorSfxPoolIndex = 0;
  bool? _cachedSoundEnabled;
  double? _cachedVolume;
  double? _cachedMusicVolume;
  Map<SoundChannel, SoundChannelSettings>? _cachedChannels;
  bool _breathBackgroundRequested = false;
  static bool _audioContextConfigured = false;

  /// Overlapping short SFX (firefly clicks) share this pool.
  static const int sfxPoolSize = 4;

  /// Dedicated meteor pool so a late re-catch never stop()+restarts the same
  /// MediaPlayer still finishing [SoundChannel.meteorClick].
  @visibleForTesting
  static const int meteorSfxPoolSize = 6;

  /// Short SFX should become responsive quickly.
  @visibleForTesting
  static const Duration sfxPlaybackStartTimeout = Duration(seconds: 2);

  /// The 17 MB Breath track needs a wider source preparation window on device.
  @visibleForTesting
  static const Duration backgroundPlaybackStartTimeout = Duration(seconds: 30);

  /// Extra play-time attenuation (~40% quieter) for peaky clips.
  @visibleForTesting
  static const double attenuatedChannelGain = 0.6;

  /// Meteor click relative gain (50% of full channel gain).
  @visibleForTesting
  static const double meteorClickChannelGain = 0.5;

  /// Breath click relative gain (50% louder than full channel gain).
  @visibleForTesting
  static const double breathClickChannelGain = 1.5;

  static const Set<SoundChannel> _attenuatedChannels = {
    SoundChannel.achievementCompleted,
    SoundChannel.gameFailed,
  };

  /// Last gain passed to native prepare/play (tests).
  @visibleForTesting
  double? lastAppliedGain;

  static AudioContext _sfxAudioContext() => AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      // Media stream (not ASSISTANCE_SONIFICATION / UI), which many devices
      // mute independently of the media volume slider the user actually hears.
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  static AudioContext _breathClickAudioContext() => _sfxAudioContext();

  @visibleForTesting
  static AudioContext get breathClickAudioContextForTesting =>
      _breathClickAudioContext();

  @visibleForTesting
  static AudioContext get sfxAudioContextForTesting => _sfxAudioContext();

  @visibleForTesting
  static AudioContext get globalAudioContextForTesting => _globalAudioContext();

  static AudioContext _globalAudioContext() => _sfxAudioContext();

  @visibleForTesting
  int fireflyPlayStartCount = 0;

  @visibleForTesting
  int meteorPlayStartCount = 0;

  /// Pool slot indexes used by successive [playMeteorClick] starts.
  @visibleForTesting
  final List<int> meteorPlayPlayerSlots = <int>[];

  @visibleForTesting
  int breathClickPlayStartCount = 0;

  @visibleForTesting
  int breathClickDirectStartCount = 0;

  @visibleForTesting
  int breathBackgroundStartCount = 0;

  @visibleForTesting
  int breathBackgroundStopCount = 0;

  @visibleForTesting
  int breathBackgroundDuckCount = 0;

  @visibleForTesting
  bool get isBreathBackgroundRequested => _breathBackgroundRequested;

  /// Unit tests: skip native audioplayers (MissingPluginException / zone noise).
  @visibleForTesting
  static bool suppressNativePlaybackForTesting = false;

  AudioPlayer get _oneshot => _oneshotPlayer ??= AudioPlayer();

  AudioPlayer get _bgm => _bgmPlayer ??= AudioPlayer();

  AudioPlayer get _breathClick => _breathClickPlayer ??= AudioPlayer();

  /// Clears cached prefs so the next play re-reads storage.
  void invalidatePlaybackCache() {
    _cachedSoundEnabled = null;
    _cachedVolume = null;
    _cachedMusicVolume = null;
    _cachedChannels = null;
  }

  @visibleForTesting
  void clearPlaybackCacheForTesting() => invalidatePlaybackCache();

  /// Preloads sound prefs so completion playback skips storage I/O.
  Future<void> warmPlaybackCache() async {
    await _ensurePlaybackCache();
  }

  Future<void> _ensurePlaybackCache() async {
    _cachedSoundEnabled ??=
        bool.tryParse(
          await _storage.read(key: StorageKeys.soundEnabled) ?? 'true',
        ) ??
        true;
    if (_cachedSoundEnabled!) {
      final raw = await _storage.read(key: StorageKeys.soundVolume);
      _cachedVolume = normalizeSoundVolume(
        double.tryParse(raw ?? '100') ?? 100.0,
      );
    } else {
      _cachedVolume = 0.0;
    }
    final musicRaw = await _storage.read(key: StorageKeys.musicVolume);
    _cachedMusicVolume = normalizeSoundVolume(
      double.tryParse(musicRaw ?? '100') ?? 100.0,
    );
    _cachedChannels ??= SoundChannelCodec.decode(
      await _storage.read(key: StorageKeys.soundChannels),
    );
  }

  /// Master music volume as 0-1 (independent of per-track channel %).
  Future<double> getMusicVolume() async {
    await _ensurePlaybackCache();
    return _cachedMusicVolume!;
  }

  /// Persists music master volume as 0-100 percent.
  Future<void> setMusicVolumePercent(int percent) async {
    final clamped = percent.clamp(0, 100);
    await _storage.write(
      key: StorageKeys.musicVolume,
      value: clamped.toString(),
    );
    _cachedMusicVolume = clamped / 100.0;
  }

  double _musicMasterGain() => _cachedMusicVolume ?? 1.0;

  Future<Map<SoundChannel, SoundChannelSettings>> loadChannelSettings() async {
    await _ensurePlaybackCache();
    return Map<SoundChannel, SoundChannelSettings>.from(_cachedChannels!);
  }

  Future<void> saveChannelSettings(
    Map<SoundChannel, SoundChannelSettings> settings,
  ) async {
    await _storage.write(
      key: StorageKeys.soundChannels,
      value: SoundChannelCodec.encode(settings),
    );
    _cachedChannels = Map<SoundChannel, SoundChannelSettings>.from(settings);
  }

  Future<bool> checkSoundEnabled() async {
    if (_cachedSoundEnabled != null) return _cachedSoundEnabled!;
    final soundEnabled = await _storage.read(key: StorageKeys.soundEnabled);
    _cachedSoundEnabled = bool.tryParse(soundEnabled ?? 'true') ?? true;
    return _cachedSoundEnabled!;
  }

  Future<double> getSoundVolume() async {
    if (_cachedVolume != null) return _cachedVolume!;
    final soundVolume = await _storage.read(key: StorageKeys.soundVolume);
    final parsed = double.tryParse(soundVolume ?? '100') ?? 100.0;
    final normalized = normalizeSoundVolume(parsed);
    debugLog('played volume: $parsed (normalized: $normalized)');
    _cachedVolume = normalized;
    return normalized;
  }

  Future<bool> checkIfSoundShouldBePlayed() async {
    await _ensurePlaybackCache();
    return _cachedSoundEnabled! && _cachedVolume! > 0.0;
  }

  Future<void> _ensureAudioContext() async {
    if (_audioContextConfigured) return;
    try {
      // Fire-and-forget with a short bound: never block SFX on context setup.
      await AudioPlayer.global
          .setAudioContext(_globalAudioContext())
          .timeout(const Duration(milliseconds: 800));
      _audioContextConfigured = true;
    } catch (_) {
      // Headless/tests or slow devices: still attempt playback.
      _audioContextConfigured = true;
    }
  }

  Future<void> _preparePlayer(
    AudioPlayer player,
    double volume, {
    AudioContext? audioContext,
  }) async {
    await _ensureAudioContext();
    try {
      // Always pin a per-player context. Global alone is not enough: breath
      // already proved ASSISTANCE_SONIFICATION can be silent while media works.
      final ctx = audioContext ?? _sfxAudioContext();
      await player
          .setAudioContext(ctx)
          .timeout(const Duration(milliseconds: 800));
      // mediaPlayer + AssetSource is reliable on Android; lowLatency can hang.
      await player
          .setPlayerMode(PlayerMode.mediaPlayer)
          .timeout(const Duration(milliseconds: 500));
      await player
          .setReleaseMode(ReleaseMode.stop)
          .timeout(const Duration(milliseconds: 500));
      await player
          .setVolume(volume.clamp(0.0, 1.0))
          .timeout(const Duration(milliseconds: 500));
    } catch (error) {
      debugLog('sound prepare skipped: $error');
    }
  }

  AudioPlayer _nextSfxPlayer() {
    if (_sfxPool.isEmpty) {
      for (var i = 0; i < sfxPoolSize; i++) {
        _sfxPool.add(AudioPlayer());
      }
    }
    final player = _sfxPool[_sfxPoolIndex % _sfxPool.length];
    _sfxPoolIndex += 1;
    return player;
  }

  int _nextMeteorPlayerSlot() {
    final slot = _meteorSfxPoolIndex % meteorSfxPoolSize;
    _meteorSfxPoolIndex += 1;
    return slot;
  }

  AudioPlayer _meteorPlayerAt(int slot) {
    while (_meteorSfxPool.length <= slot) {
      _meteorSfxPool.add(AudioPlayer());
    }
    return _meteorSfxPool[slot];
  }

  /// Starts playback without waiting for the clip to finish.
  Future<void> _startAsset(
    AudioPlayer player,
    String assetPath, {
    Duration startTimeout = sfxPlaybackStartTimeout,
  }) async {
    try {
      await player.stop().timeout(const Duration(milliseconds: 400));
    } catch (_) {}
    try {
      // Prefer setSource + resume (avoids play()-until-complete hangs). Pooling
      // concurrent SFX prevents Android MediaPlayer -38 on a shared oneshot.
      await player.setSource(AssetSource(assetPath)).timeout(startTimeout);
      await player.resume().timeout(startTimeout);
    } on TimeoutException {
      debugLog('sound start timed out ($assetPath)');
    } catch (error) {
      debugLog('sound setSource/resume failed ($assetPath): $error');
      try {
        await player.play(AssetSource(assetPath)).timeout(startTimeout);
      } catch (fallbackError) {
        debugLog('sound play fallback failed ($assetPath): $fallbackError');
      }
    }
  }

  Future<void> _playChannel(
    SoundChannel channel, {
    bool preview = false,
  }) async {
    await _ensurePlaybackCache();
    if (!preview && !(_cachedSoundEnabled! && _cachedVolume! > 0.0)) return;
    final channelSettings =
        _cachedChannels?[channel] ?? const SoundChannelSettings();
    if (!channelSettings.enabled || channelSettings.volumePercent <= 0) {
      return;
    }
    final master = preview && _cachedSoundEnabled != true
        ? 1.0
        : (_cachedVolume ?? 0.0);
    if (!preview && master <= 0) return;
    var gain = master * (channelSettings.volumePercent / 100.0);
    if (channel == SoundChannel.meteorClick) {
      gain *= meteorClickChannelGain;
    } else if (channel == SoundChannel.breathClick) {
      gain *= breathClickChannelGain;
    } else if (_attenuatedChannels.contains(channel)) {
      // These clips peak louder than peers; keep ~40% quieter at equal settings.
      gain *= attenuatedChannelGain;
    }
    if (gain <= 0) return;
    lastAppliedGain = gain;

    final usePool =
        channel == SoundChannel.fireflyClick ||
        channel == SoundChannel.rockFalling ||
        channel == SoundChannel.gameFailed ||
        channel == SoundChannel.wordBloomClick ||
        channel == SoundChannel.rainCatchClick ||
        channel == SoundChannel.rainMiss;
    if (channel == SoundChannel.fireflyClick) {
      fireflyPlayStartCount += 1;
    }
    if (channel == SoundChannel.meteorClick) {
      meteorPlayStartCount += 1;
      final meteorSlot = _nextMeteorPlayerSlot();
      meteorPlayPlayerSlots.add(meteorSlot);
      if (suppressNativePlaybackForTesting) return;
      final meteorPlayer = _meteorPlayerAt(meteorSlot);
      try {
        await _preparePlayer(
          meteorPlayer,
          gain,
          audioContext: _sfxAudioContext(),
        );
        unawaited(() async {
          try {
            await _startAsset(meteorPlayer, channel.assetPath);
          } catch (error) {
            debugLog('sound play failed (${channel.id}): $error');
          }
        }());
      } catch (error) {
        debugLog('sound play failed (${channel.id}): $error');
      }
      return;
    }
    if (channel.isMusic) {
      if (preview) {
        if (channel == SoundChannel.breathBackground) {
          await previewBreathBackground();
        } else {
          await previewMusic(channel);
        }
      } else {
        await startMusic(channel);
      }
      return;
    }
    if (channel == SoundChannel.breathClick) {
      breathClickPlayStartCount += 1;
      breathClickDirectStartCount += 1;
    }
    if (suppressNativePlaybackForTesting) return;

    final player = channel == SoundChannel.breathClick
        ? _breathClick
        : usePool
        ? _nextSfxPlayer()
        : _oneshot;
    try {
      await _preparePlayer(
        player,
        gain,
        audioContext: channel == SoundChannel.breathClick
            ? _breathClickAudioContext()
            : _sfxAudioContext(),
      );
      // Do not await clip end: only wait for start so rapid SFX stay responsive.
      unawaited(() async {
        try {
          await _startAsset(player, channel.assetPath);
        } catch (error) {
          debugLog('sound play failed (${channel.id}): $error');
        }
      }());
    } catch (error) {
      debugLog('sound play failed (${channel.id}): $error');
    }
  }

  /// Preview a channel from Settings (audible even if master sound is off).
  Future<void> previewChannel(SoundChannel channel) =>
      _playChannel(channel, preview: true);

  /// Starts looping (or one-shot) BGM for [channel]. Stops any current BGM first.
  Future<void> startMusic(
    SoundChannel channel, {
    bool loop = true,
  }) async {
    assert(channel.isMusic, 'startMusic requires a music channel');
    await _ensurePlaybackCache();
    if (!(_cachedSoundEnabled! && _cachedVolume! > 0.0)) return;
    final channelSettings =
        _cachedChannels?[channel] ?? const SoundChannelSettings();
    if (!channelSettings.enabled || channelSettings.volumePercent <= 0) {
      return;
    }
    final gain =
        (_cachedVolume ?? 0.0) *
        _musicMasterGain() *
        (channelSettings.volumePercent / 100.0);
    if (gain <= 0) return;

    await _startBgmInternal(
      assetPath: channel.assetPath,
      loop: loop,
      gain: gain,
      listenForComplete: false,
      trackBreathCounters: channel == SoundChannel.breathBackground,
    );
  }

  /// Stops current BGM (zen / cherry / breath / bonsai).
  Future<void> stopMusic() => _stopBreathBackground(clearRequest: true);

  /// Starts Breath background during play. Loops in Endless; Duration stops
  /// with [stopBreathBackground] when the round ends.
  Future<void> startBreathBackground({required bool loop}) =>
      startMusic(SoundChannel.breathBackground, loop: loop);

  Future<void> previewBreathBackground({VoidCallback? onCompleted}) async {
    await _ensurePlaybackCache();
    final channelSettings =
        _cachedChannels?[SoundChannel.breathBackground] ??
        const SoundChannelSettings();
    if (!channelSettings.enabled || channelSettings.volumePercent <= 0) {
      return;
    }
    final master = _cachedSoundEnabled != true ? 1.0 : (_cachedVolume ?? 0.0);
    final gain =
        master * _musicMasterGain() * (channelSettings.volumePercent / 100.0);
    if (gain <= 0) return;

    await _startBgmInternal(
      assetPath: SoundChannel.breathBackground.assetPath,
      loop: false,
      gain: gain,
      listenForComplete: true,
      onCompleted: onCompleted,
      trackBreathCounters: true,
    );
  }

  /// Preview a music track once (Sound effects Preview).
  Future<void> previewMusic(SoundChannel channel) async {
    assert(channel.isMusic);
    await _ensurePlaybackCache();
    final channelSettings =
        _cachedChannels?[channel] ?? const SoundChannelSettings();
    if (!channelSettings.enabled || channelSettings.volumePercent <= 0) {
      return;
    }
    final master = _cachedSoundEnabled != true ? 1.0 : (_cachedVolume ?? 0.0);
    final gain =
        master * _musicMasterGain() * (channelSettings.volumePercent / 100.0);
    if (gain <= 0) return;
    await _startBgmInternal(
      assetPath: channel.assetPath,
      loop: false,
      gain: gain,
      listenForComplete: false,
      trackBreathCounters: channel == SoundChannel.breathBackground,
    );
  }

  Future<void> _startBgmInternal({
    required String assetPath,
    required bool loop,
    required double gain,
    required bool listenForComplete,
    VoidCallback? onCompleted,
    bool trackBreathCounters = false,
  }) async {
    if (trackBreathCounters) {
      breathBackgroundStartCount += 1;
    }
    await _stopBreathBackground(clearRequest: false);
    _breathBackgroundRequested = true;
    if (suppressNativePlaybackForTesting) return;

    final player = _bgm;
    if (listenForComplete) {
      await _bgmCompleteSub?.cancel();
      _bgmCompleteSub = player.onPlayerComplete.listen((_) {
        onCompleted?.call();
      });
    }
    try {
      await _preparePlayer(
        player,
        gain,
        audioContext: AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _startAsset(
        player,
        assetPath,
        startTimeout: backgroundPlaybackStartTimeout,
      );
    } catch (error) {
      debugLog('bgm start failed ($assetPath): $error');
    }
  }

  Future<void> stopBreathBackground() =>
      _stopBreathBackground(clearRequest: true);

  Future<void> _stopBreathBackground({required bool clearRequest}) async {
    if (clearRequest && _breathBackgroundRequested) {
      breathBackgroundStopCount += 1;
      _breathBackgroundRequested = false;
    }
    await _bgmCompleteSub?.cancel();
    _bgmCompleteSub = null;
    final player = _bgmPlayer;
    if (player == null) return;
    try {
      await player.stop().timeout(const Duration(milliseconds: 400));
    } catch (_) {}
  }

  Future<void> playFireflyClick() => _playChannel(SoundChannel.fireflyClick);

  Future<void> playMeteorClick() => _playChannel(SoundChannel.meteorClick);

  Future<void> playWordBloomClick() =>
      _playChannel(SoundChannel.wordBloomClick);

  Future<void> playWordCollected() =>
      _playChannel(SoundChannel.wordCollected);

  Future<void> playRainCatchClick() =>
      _playChannel(SoundChannel.rainCatchClick);

  Future<void> playRainMiss() => _playChannel(SoundChannel.rainMiss);

  Future<void> playRockFalling() => _playChannel(SoundChannel.rockFalling);

  Future<void> playGameFailed() => _playChannel(SoundChannel.gameFailed);

  Future<void> playBreathClick() => _playChannel(SoundChannel.breathClick);

  Future<void> playGoalCreated() => _playChannel(SoundChannel.goalCreated);

  Future<void> playGoalCompleted() => _playChannel(SoundChannel.goalCompleted);

  Future<void> playAchievementCompleted() =>
      _playChannel(SoundChannel.achievementCompleted);
}
