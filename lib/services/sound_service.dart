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
  AudioPlayer? _ambientPlayer;
  AudioPlayer? _ambientStandbyPlayer;
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
  bool _ambientRequested = false;
  bool _ambientDucked = false;
  bool _ambientStartInFlight = false;
  SoundChannel? _ambientChannel;
  SoundChannel? _activeFeatureMusic;
  SoundChannel? _featureMusicBeforeBackground;
  bool _suspendedForBackground = false;
  int _ambientGeneration = 0;
  static bool _audioContextConfigured = false;
  String? _bgmPreparedPath;
  String? _ambientPreparedPath;
  String? _ambientStandbyPreparedPath;
  bool _bgmPlayerPrepared = false;
  bool _ambientPlayerPrepared = false;
  bool _ambientStandbyPrepared = false;

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

  /// Linear fade for ambient start/stop/duck. Keep short so track switches feel instant.
  @visibleForTesting
  static Duration ambientFadeDuration = const Duration(milliseconds: 120);

  /// Artificial delay inside [startAmbient] for race tests (zero in production).
  @visibleForTesting
  static Duration ambientStartDelayForTesting = Duration.zero;

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
  int ambientStartCount = 0;

  @visibleForTesting
  int ambientStopCount = 0;

  @visibleForTesting
  int ambientDuckCount = 0;

  @visibleForTesting
  int ambientUnduckCount = 0;

  /// Counts cold music [setSource] / prepare loads (ambient + feature BGM).
  @visibleForTesting
  int musicAssetSetSourceCount = 0;

  @visibleForTesting
  String? get ambientPreparedPathForTesting => _ambientPreparedPath;

  @visibleForTesting
  String? get ambientStandbyPreparedPathForTesting =>
      _ambientStandbyPreparedPath;

  @visibleForTesting
  String? get bgmPreparedPathForTesting => _bgmPreparedPath;

  @visibleForTesting
  bool get isBreathBackgroundRequested => _breathBackgroundRequested;

  @visibleForTesting
  bool get isAmbientRequested => _ambientRequested;

  /// True while zen/cherry/bonsai/breath (or other feature) BGM is requested.
  bool get hasActiveFeatureMusic =>
      _activeFeatureMusic != null || _breathBackgroundRequested;

  /// Feature BGM channel currently requested (zen/cherry/bonsai/breath), if any.
  SoundChannel? get activeFeatureMusic => _activeFeatureMusic;

  @visibleForTesting
  SoundChannel? get activeFeatureMusicForTesting => _activeFeatureMusic;

  @visibleForTesting
  bool get isSuspendedForBackgroundForTesting => _suspendedForBackground;

  @visibleForTesting
  bool get isAmbientDucked => _ambientDucked;

  @visibleForTesting
  SoundChannel? get activeAmbientChannelForTesting => _ambientChannel;

  /// Unit tests: skip native audioplayers (MissingPluginException / zone noise).
  @visibleForTesting
  static bool suppressNativePlaybackForTesting = false;

  AudioPlayer get _oneshot => _oneshotPlayer ??= AudioPlayer();

  AudioPlayer get _bgm => _bgmPlayer ??= AudioPlayer();

  AudioPlayer get _ambient => _ambientPlayer ??= AudioPlayer();

  AudioPlayer get _ambientStandby => _ambientStandbyPlayer ??= AudioPlayer();

  AudioPlayer get _breathClick => _breathClickPlayer ??= AudioPlayer();

  void _swapAmbientPlayers() {
    final active = _ambientPlayer;
    final standby = _ambientStandbyPlayer;
    _ambientPlayer = standby;
    _ambientStandbyPlayer = active;
    final activePath = _ambientPreparedPath;
    _ambientPreparedPath = _ambientStandbyPreparedPath;
    _ambientStandbyPreparedPath = activePath;
    final activeReady = _ambientPlayerPrepared;
    _ambientPlayerPrepared = _ambientStandbyPrepared;
    _ambientStandbyPrepared = activeReady;
  }

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
  ///
  /// When [reusePrepared] is true and [assetPath] matches the last prepared
  /// source on this player, skips [setSource] (major latency win on page switches).
  Future<void> _startAsset(
    AudioPlayer player,
    String assetPath, {
    Duration startTimeout = sfxPlaybackStartTimeout,
    bool reusePrepared = false,
    String? preparedPath,
    void Function(String path)? onPrepared,
    Duration startAt = Duration.zero,
  }) async {
    final canReuse = reusePrepared && preparedPath == assetPath;
    if (!canReuse) {
      try {
        await player.stop().timeout(const Duration(milliseconds: 400));
      } catch (_) {}
    }
    try {
      if (!canReuse) {
        await player.setSource(AssetSource(assetPath)).timeout(startTimeout);
        onPrepared?.call(assetPath);
        musicAssetSetSourceCount += 1;
      }
      if (startAt > Duration.zero) {
        try {
          await player.seek(startAt).timeout(const Duration(milliseconds: 800));
        } catch (_) {}
      }
      await player.resume().timeout(startTimeout);
    } on TimeoutException {
      debugLog('sound start timed out ($assetPath)');
    } catch (error) {
      debugLog('sound setSource/resume failed ($assetPath): $error');
      try {
        await player.play(
          AssetSource(assetPath),
          position: startAt > Duration.zero ? startAt : null,
        ).timeout(startTimeout);
        onPrepared?.call(assetPath);
      } catch (fallbackError) {
        debugLog('sound play fallback failed ($assetPath): $fallbackError');
      }
    }
  }

  /// Optional seek past leading silence for known tracks (tune offline).
  static Duration musicStartOffsetFor(SoundChannel channel) {
    return switch (channel) {
      // Soft pads / nature beds often have a short quiet head.
      SoundChannel.cherryPeaceMusic ||
      SoundChannel.cherryPowerMusic ||
      SoundChannel.cherryBalanceMusic ||
      SoundChannel.zenGardenMusic ||
      SoundChannel.bonsaiMusic =>
        const Duration(milliseconds: 350),
      SoundChannel.ambientRunningWater ||
      SoundChannel.ambientOceanWaves ||
      SoundChannel.ambientForestAtNight ||
      SoundChannel.ambientWindChimes ||
      SoundChannel.ambientPiano =>
        const Duration(milliseconds: 200),
      _ => Duration.zero,
    };
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
  ///
  /// Returns false when master/channel settings prevent playback (caller should
  /// fall back to customization ambient on feature screens).
  Future<bool> startMusic(
    SoundChannel channel, {
    bool loop = true,
  }) async {
    assert(channel.isMusic, 'startMusic requires a music channel');
    await _ensurePlaybackCache();
    if (!(_cachedSoundEnabled! && _cachedVolume! > 0.0)) return false;
    final channelSettings =
        _cachedChannels?[channel] ?? const SoundChannelSettings();
    if (!channelSettings.enabled || channelSettings.volumePercent <= 0) {
      return false;
    }
    final gain =
        (_cachedVolume ?? 0.0) *
        _musicMasterGain() *
        (channelSettings.volumePercent / 100.0);
    if (gain <= 0) return false;

    _activeFeatureMusic = channel;
    await _startBgmInternal(
      assetPath: channel.assetPath,
      loop: loop,
      gain: gain,
      listenForComplete: false,
      trackBreathCounters: channel == SoundChannel.breathBackground,
      startAt: musicStartOffsetFor(channel),
    );
    return true;
  }

  /// Whether [channel] would pass the same gates as [startMusic] (no I/O side effects
  /// beyond warming the prefs cache).
  Future<bool> isMusicChannelAudible(SoundChannel channel) async {
    assert(channel.isMusic, 'isMusicChannelAudible requires a music channel');
    await _ensurePlaybackCache();
    if (!(_cachedSoundEnabled! && _cachedVolume! > 0.0)) return false;
    final channelSettings =
        _cachedChannels?[channel] ?? const SoundChannelSettings();
    if (!channelSettings.enabled || channelSettings.volumePercent <= 0) {
      return false;
    }
    final gain =
        (_cachedVolume ?? 0.0) *
        _musicMasterGain() *
        (channelSettings.volumePercent / 100.0);
    return gain > 0;
  }

  /// Stops current BGM (zen / cherry / breath / bonsai).
  Future<void> stopMusic() => _stopBreathBackground(clearRequest: true);

  /// Stops feature BGM only when [channel] is still the active track.
  ///
  /// Disposing screens must use this so a lagged [stopMusic] cannot kill the
  /// destination screen's newly started theme (zen after cherry pop).
  Future<void> stopMusicIfChannel(SoundChannel channel) async {
    if (_activeFeatureMusic != channel) return;
    await stopMusic();
  }

  /// Preloads an ambient asset onto the standby player (volume 0) so the next
  /// [startAmbient] can swap without a cold [setSource].
  Future<void> prepareAmbient(SoundChannel channel) async {
    assert(
      channel.isMusic && channel.musicSection == SoundMusicSection.ambient,
      'prepareAmbient requires an ambient music channel',
    );
    if (_ambientPreparedPath == channel.assetPath ||
        _ambientStandbyPreparedPath == channel.assetPath) {
      return;
    }
    if (suppressNativePlaybackForTesting) {
      _ambientStandbyPreparedPath = channel.assetPath;
      _ambientStandbyPrepared = true;
      musicAssetSetSourceCount += 1;
      return;
    }
    final player = _ambientStandby;
    try {
      if (!_ambientStandbyPrepared) {
        await _preparePlayer(
          player,
          0.0,
          audioContext: _ambientAudioContext(),
        );
        _ambientStandbyPrepared = true;
      } else {
        try {
          await player.setVolume(0).timeout(const Duration(milliseconds: 400));
        } catch (_) {}
      }
      await player.setReleaseMode(ReleaseMode.loop);
      await player
          .setSource(AssetSource(channel.assetPath))
          .timeout(backgroundPlaybackStartTimeout);
      _ambientStandbyPreparedPath = channel.assetPath;
      musicAssetSetSourceCount += 1;
    } catch (error) {
      debugLog('ambient prepare failed (${channel.id}): $error');
    }
  }

  /// Preloads feature BGM so [startMusic] can reuse the prepared source.
  Future<void> prepareMusic(SoundChannel channel) async {
    assert(channel.isMusic, 'prepareMusic requires a music channel');
    if (_bgmPreparedPath == channel.assetPath) return;
    if (suppressNativePlaybackForTesting) {
      _bgmPreparedPath = channel.assetPath;
      _bgmPlayerPrepared = true;
      musicAssetSetSourceCount += 1;
      return;
    }
    final player = _bgm;
    try {
      if (!_bgmPlayerPrepared) {
        await _preparePlayer(
          player,
          0.0,
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
        _bgmPlayerPrepared = true;
      } else {
        try {
          await player.setVolume(0).timeout(const Duration(milliseconds: 400));
        } catch (_) {}
      }
      await player
          .setSource(AssetSource(channel.assetPath))
          .timeout(backgroundPlaybackStartTimeout);
      _bgmPreparedPath = channel.assetPath;
      musicAssetSetSourceCount += 1;
    } catch (error) {
      debugLog('bgm prepare failed (${channel.id}): $error');
    }
  }

  /// Starts ambient soundscape on the dedicated ambient player.
  Future<void> startAmbient(SoundChannel channel, {bool loop = true}) async {
    assert(
      channel.isMusic && channel.musicSection == SoundMusicSection.ambient,
      'startAmbient requires an ambient music channel',
    );
    // Feature BGM screens own audio; do not layer customization ambient.
    if (hasActiveFeatureMusic) {
      return;
    }
    await _ensurePlaybackCache();
    if (hasActiveFeatureMusic) return;
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

    if (_ambientRequested &&
        _ambientChannel == channel &&
        !_ambientDucked &&
        !_ambientStartInFlight) {
      return;
    }

    final gen = ++_ambientGeneration;
    ambientStartCount += 1;
    _ambientRequested = true;
    _ambientChannel = channel;
    _ambientDucked = false;
    _ambientStartInFlight = true;

    if (ambientStartDelayForTesting > Duration.zero) {
      await Future<void>.delayed(ambientStartDelayForTesting);
      if (gen != _ambientGeneration || hasActiveFeatureMusic) {
        if (hasActiveFeatureMusic && gen == _ambientGeneration) {
          _ambientRequested = false;
          _ambientChannel = null;
          _ambientStartInFlight = false;
        }
        return;
      }
    }

    if (suppressNativePlaybackForTesting) {
      if (gen != _ambientGeneration) return;
      // Honor prepare-ahead swaps in tests without native I/O.
      if (_ambientStandbyPreparedPath == channel.assetPath &&
          _ambientPreparedPath != channel.assetPath) {
        _swapAmbientPlayers();
      } else if (_ambientPreparedPath != channel.assetPath) {
        _ambientPreparedPath = channel.assetPath;
        musicAssetSetSourceCount += 1;
      }
      lastAppliedGain = gain;
      _ambientStartInFlight = false;
      return;
    }

    final startAt = musicStartOffsetFor(channel);
    try {
      // Standby already holds the next track: swap and go audible immediately.
      if (_ambientStandbyPreparedPath == channel.assetPath &&
          _ambientPreparedPath != channel.assetPath) {
        final previous = _ambientPlayer;
        final previousGain = lastAppliedGain ?? 0.0;
        _swapAmbientPlayers();
        final player = _ambient;
        await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
        try {
          await player.setVolume(0).timeout(const Duration(milliseconds: 400));
        } catch (_) {}
        if (startAt > Duration.zero) {
          try {
            await player.seek(startAt).timeout(const Duration(milliseconds: 800));
          } catch (_) {}
        }
        await player.resume().timeout(backgroundPlaybackStartTimeout);
        if (gen != _ambientGeneration) return;
        await _fadeVolume(player, 0.0, gain);
        if (gen != _ambientGeneration) return;
        lastAppliedGain = gain;
        _ambientStartInFlight = false;
        if (previous != null) {
          unawaited(() async {
            try {
              await _fadeVolume(previous, previousGain, 0.0);
              await previous.stop().timeout(const Duration(milliseconds: 400));
            } catch (_) {}
          }());
        }
        return;
      }

      final player = _ambient;
      final reusePath = _ambientPreparedPath == channel.assetPath;
      if (_ambientPlayer != null && !reusePath) {
        final previousGain = lastAppliedGain ?? 0.0;
        await _fadeVolume(player, previousGain, 0.0);
        if (gen != _ambientGeneration) return;
        try {
          await player.stop().timeout(const Duration(milliseconds: 400));
        } catch (_) {}
      }
      if (gen != _ambientGeneration) return;
      if (!_ambientPlayerPrepared) {
        await _preparePlayer(
          player,
          reusePath ? gain : 0.0,
          audioContext: _ambientAudioContext(),
        );
        _ambientPlayerPrepared = true;
      } else if (reusePath) {
        try {
          await player
              .setVolume(gain.clamp(0.0, 1.0))
              .timeout(const Duration(milliseconds: 400));
        } catch (_) {}
      }
      if (gen != _ambientGeneration) return;
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      if (reusePath) {
        await _startAsset(
          player,
          channel.assetPath,
          startTimeout: backgroundPlaybackStartTimeout,
          reusePrepared: true,
          preparedPath: _ambientPreparedPath,
          onPrepared: (path) => _ambientPreparedPath = path,
          startAt: startAt,
        );
        if (gen != _ambientGeneration) return;
        lastAppliedGain = gain;
        _ambientStartInFlight = false;
        return;
      }
      await _startAsset(
        player,
        channel.assetPath,
        startTimeout: backgroundPlaybackStartTimeout,
        reusePrepared: false,
        preparedPath: _ambientPreparedPath,
        onPrepared: (path) => _ambientPreparedPath = path,
        startAt: startAt,
      );
      if (gen != _ambientGeneration) return;
      // Short fade-in; do not leave the track silent for a full second.
      await _fadeVolume(player, 0.0, gain);
      if (gen != _ambientGeneration) return;
      lastAppliedGain = gain;
      _ambientStartInFlight = false;
    } catch (error) {
      debugLog('ambient start failed (${channel.id}): $error');
      if (gen == _ambientGeneration) {
        _ambientStartInFlight = false;
      }
    }
  }

  /// Stops ambient playback (with optional fade).
  Future<void> stopAmbient({bool fade = true}) async {
    _ambientGeneration++;
    _ambientStartInFlight = false;
    if (!_ambientRequested && _ambientPlayer == null) return;
    if (_ambientRequested) {
      ambientStopCount += 1;
    }
    _ambientRequested = false;
    _ambientDucked = false;
    _ambientChannel = null;

    if (suppressNativePlaybackForTesting) return;

    final player = _ambientPlayer;
    if (player == null) return;
    try {
      if (fade) {
        await _fadeVolume(player, lastAppliedGain ?? 0.0, 0.0);
      }
      await player.stop().timeout(const Duration(milliseconds: 400));
    } catch (_) {}
  }

  /// Preview an ambient track (locked or unlocked). Audible even if master off.
  Future<void> previewAmbient(SoundChannel channel) async {
    assert(
      channel.isMusic && channel.musicSection == SoundMusicSection.ambient,
      'previewAmbient requires an ambient music channel',
    );
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

    ambientStartCount += 1;
    _ambientRequested = true;
    _ambientChannel = channel;
    _ambientDucked = false;

    if (suppressNativePlaybackForTesting) {
      lastAppliedGain = gain;
      return;
    }

    final player = _ambient;
    try {
      try {
        await player.stop().timeout(const Duration(milliseconds: 400));
      } catch (_) {}
      await _preparePlayer(
        player,
        0.0,
        audioContext: _ambientAudioContext(),
      );
      await player.setReleaseMode(ReleaseMode.loop);
      await _startAsset(
        player,
        channel.assetPath,
        startTimeout: backgroundPlaybackStartTimeout,
      );
      await _fadeVolume(player, 0.0, gain);
      lastAppliedGain = gain;
    } catch (error) {
      debugLog('ambient preview failed (${channel.id}): $error');
    }
  }

  /// Fades ambient out while feature BGM plays; keeps selection for resume.
  Future<void> duckAmbientForFeatureBgm() async {
    if (!_ambientRequested || _ambientDucked) return;
    ambientDuckCount += 1;
    _ambientDucked = true;
    if (suppressNativePlaybackForTesting) return;

    final player = _ambientPlayer;
    if (player == null) return;
    try {
      await _fadeVolume(player, lastAppliedGain ?? 0.0, 0.0);
      await player.pause().timeout(const Duration(milliseconds: 400));
    } catch (_) {}
  }

  /// Resumes ambient after feature BGM stops, if still requested.
  Future<void> unduckAmbientAfterFeatureBgm() async {
    if (!_ambientRequested || !_ambientDucked) return;
    final channel = _ambientChannel;
    if (channel == null) return;
    ambientUnduckCount += 1;
    _ambientDucked = false;

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

    if (suppressNativePlaybackForTesting) {
      lastAppliedGain = gain;
      return;
    }

    final player = _ambientPlayer;
    if (player == null) return;
    try {
      await player.resume().timeout(const Duration(milliseconds: 800));
      await _fadeVolume(player, 0.0, gain);
      lastAppliedGain = gain;
    } catch (error) {
      debugLog('ambient unduck failed (${channel.id}): $error');
      // Fallback: restart the loop.
      _ambientDucked = false;
      await startAmbient(channel);
    }
  }

  static AudioContext _ambientAudioContext() => AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      );

  Future<void> _fadeVolume(
    AudioPlayer player,
    double from,
    double to,
  ) async {
    if (suppressNativePlaybackForTesting) {
      lastAppliedGain = to;
      return;
    }
    const steps = 10;
    final stepMs = (ambientFadeDuration.inMilliseconds / steps)
        .round()
        .clamp(1, 200);
    final stepDuration = Duration(milliseconds: stepMs);
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final volume = from + (to - from) * t;
      try {
        await player
            .setVolume(volume.clamp(0.0, 1.0))
            .timeout(const Duration(milliseconds: 300));
      } catch (_) {}
      await Future<void>.delayed(stepDuration);
    }
  }

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
    Duration startAt = Duration.zero,
  }) async {
    if (trackBreathCounters) {
      breathBackgroundStartCount += 1;
    }
    // Do not await ambient fade - that added ~1s before feature BGM could start.
    await stopAmbient(fade: false);
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
      final reusePath = _bgmPreparedPath == assetPath;
      if (!_bgmPlayerPrepared) {
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
        _bgmPlayerPrepared = true;
      } else {
        try {
          await player
              .setVolume(gain.clamp(0.0, 1.0))
              .timeout(const Duration(milliseconds: 400));
        } catch (_) {}
      }
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _startAsset(
        player,
        assetPath,
        startTimeout: backgroundPlaybackStartTimeout,
        reusePrepared: reusePath,
        preparedPath: _bgmPreparedPath,
        onPrepared: (path) => _bgmPreparedPath = path,
        startAt: startAt,
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
      _activeFeatureMusic = null;
    }
    await _bgmCompleteSub?.cancel();
    _bgmCompleteSub = null;
    final player = _bgmPlayer;
    if (player != null) {
      try {
        await player.stop().timeout(const Duration(milliseconds: 400));
      } catch (_) {}
    }
    // Do not auto-unduck ambient: feature BGM hard-stops ambient. Route
    // observer / coordinator.resume restarts ambient when appropriate.
  }

  /// Pauses/stops all looping music when the app is backgrounded (home button).
  Future<void> pauseAllMusicForAppBackground() async {
    if (_suspendedForBackground) return;
    _suspendedForBackground = true;
    _featureMusicBeforeBackground = _activeFeatureMusic;
    if (suppressNativePlaybackForTesting) {
      await stopMusic();
      await stopAmbient(fade: false);
      return;
    }
    // Prefer pause over stop+reload so resume is near-instant.
    try {
      await _bgmPlayer?.pause().timeout(const Duration(milliseconds: 400));
    } catch (_) {}
    try {
      await _ambientPlayer?.pause().timeout(const Duration(milliseconds: 400));
    } catch (_) {}
    try {
      await _ambientStandbyPlayer?.pause().timeout(
        const Duration(milliseconds: 400),
      );
    } catch (_) {}
  }

  /// Restores feature BGM after foreground if it was playing before suspend.
  /// Ambient is restored by [AmbientPlaybackCoordinator.resume] when needed.
  Future<void> resumeAfterAppForeground() async {
    if (!_suspendedForBackground) return;
    _suspendedForBackground = false;
    final feature = _featureMusicBeforeBackground;
    _featureMusicBeforeBackground = null;
    if (feature == null) return;
    if (suppressNativePlaybackForTesting) {
      await startMusic(feature);
      return;
    }
    // Same prepared source: resume without cold setSource.
    if (_bgmPreparedPath == feature.assetPath && _bgmPlayer != null) {
      _activeFeatureMusic = feature;
      _breathBackgroundRequested = true;
      try {
        await _bgmPlayer!.resume().timeout(const Duration(milliseconds: 800));
        return;
      } catch (_) {}
    }
    await startMusic(feature);
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
