import 'dart:convert';

/// Functional grouping for the Sound effects settings page.
enum SoundChannelGroup {
  music('Music'),
  goals('Goals'),
  achievements('Achievements'),
  miniGames('Mini-games');

  const SoundChannelGroup(this.label);
  final String label;
}

/// Sub-sections inside the Music group (shown with dividers).
enum SoundMusicSection {
  ambient('Background music'),
  miniGames('Mini-games'),
  zenGarden('Zen garden'),
  cherryBlossom('Cherry blossom');

  const SoundMusicSection(this.label);
  final String label;
}

/// Per-channel settings under the master sound toggle (SFX + music).
enum SoundChannel {
  // --- Music (looping BGM) ---
  breathBackground(
    id: 'breath_background',
    label: 'Breath background',
    assetPath: 'sounds/music/breath_background.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.miniGames,
    isMusic: true,
  ),
  zenGardenMusic(
    id: 'zen_garden_music',
    label: 'Zen garden',
    assetPath: 'sounds/music/zen_garden.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.zenGarden,
    isMusic: true,
  ),
  cherryStage1Music(
    id: 'cherry_stage_1_music',
    label: 'Cherry stages 1-3',
    assetPath: 'sounds/music/stage_1.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.cherryBlossom,
    isMusic: true,
  ),
  cherryStage2Music(
    id: 'cherry_stage_2_music',
    label: 'Cherry Deep Twilight / Aurora',
    assetPath: 'sounds/music/stage_2.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.cherryBlossom,
    isMusic: true,
  ),
  cherryBalanceMusic(
    id: 'cherry_balance_music',
    label: 'Living Canopy',
    assetPath: 'sounds/music/balance_tree.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.cherryBlossom,
    isMusic: true,
  ),
  cherryPeaceMusic(
    id: 'cherry_peace_music',
    label: 'Peace tree',
    assetPath: 'sounds/music/peace_tree.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.cherryBlossom,
    isMusic: true,
  ),
  cherryPowerMusic(
    id: 'cherry_power_music',
    label: 'Power tree',
    assetPath: 'sounds/music/power_tree.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.cherryBlossom,
    isMusic: true,
  ),
  bonsaiMusic(
    id: 'bonsai_music',
    label: 'Bonsai garden',
    assetPath: 'sounds/music/bonsai.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.cherryBlossom,
    isMusic: true,
  ),
  ambientRunningWater(
    id: 'running_water',
    label: 'Running water',
    assetPath: 'sounds/music/customization/running_stream.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),
  ambientWhiteNoise(
    id: 'white_noise',
    label: 'White noise',
    assetPath: 'sounds/music/customization/white_noise.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),
  ambientForestAtNight(
    id: 'forest_at_night',
    label: 'Forest at night',
    assetPath: 'sounds/music/customization/forest_at_night.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),
  ambientOceanWaves(
    id: 'ocean_waves',
    label: 'Ocean waves',
    assetPath: 'sounds/music/customization/ocean_waves.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),
  ambientPinkNoise(
    id: 'pink_noise',
    label: 'Pink noise',
    assetPath: 'sounds/music/customization/pink_noise.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),
  ambientWindChimes(
    id: 'wind_chimes',
    label: 'Wind chimes',
    assetPath: 'sounds/music/customization/wind_chimes.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),
  ambientDistantThunder(
    id: 'distant_thunder',
    label: 'Distant thunder',
    assetPath: 'sounds/music/customization/distant_thunder.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),
  ambientPiano(
    id: 'piano',
    label: 'Piano',
    assetPath: 'sounds/music/customization/piano.mp3',
    group: SoundChannelGroup.music,
    musicSection: SoundMusicSection.ambient,
    isMusic: true,
  ),

  // --- SFX ---
  goalCreated(
    id: 'goal_created',
    label: 'Goal creation',
    assetPath: 'sounds/goal_created.mp3',
    group: SoundChannelGroup.goals,
  ),
  goalCompleted(
    id: 'goal_completed',
    label: 'Goal completion',
    assetPath: 'sounds/goal_completed.mp3',
    group: SoundChannelGroup.goals,
  ),
  achievementCompleted(
    id: 'achievement_completed',
    label: 'Achievement completion',
    assetPath: 'sounds/achievement_completed.mp3',
    group: SoundChannelGroup.achievements,
  ),
  fireflyClick(
    id: 'firefly_click',
    label: 'Firefly click',
    assetPath: 'sounds/firefly_click.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  rockFalling(
    id: 'rock_falling',
    label: 'Stone landing',
    assetPath: 'sounds/rock_falling.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  gameFailed(
    id: 'game_failed',
    label: 'Game failed',
    assetPath: 'sounds/game_failed.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  breathClick(
    id: 'breath_click',
    label: 'Breath click',
    assetPath: 'sounds/breath_click.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  meteorClick(
    id: 'meteor_click',
    label: 'Meteor click',
    assetPath: 'sounds/meteor_click.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  wordBloomClick(
    id: 'word_bloom_click',
    label: 'Word Bloom click',
    assetPath: 'sounds/word_bloom_click.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  wordCollected(
    id: 'word_collected',
    label: 'Word collected',
    assetPath: 'sounds/word_collected.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  rainCatchClick(
    id: 'rain_catch_click',
    label: 'Rain catch',
    assetPath: 'sounds/rain_catch_click.mp3',
    group: SoundChannelGroup.miniGames,
  ),
  rainMiss(
    id: 'rain_miss',
    label: 'Rain miss',
    assetPath: 'sounds/rain_miss.mp3',
    group: SoundChannelGroup.miniGames,
  );

  const SoundChannel({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.group,
    this.musicSection,
    this.isMusic = false,
  });

  final String id;
  final String label;
  final String assetPath;
  final SoundChannelGroup group;
  final SoundMusicSection? musicSection;
  final bool isMusic;

  static List<SoundChannel> forGroup(SoundChannelGroup group) =>
      values.where((c) => c.group == group).toList(growable: false);

  static List<SoundChannel> musicForSection(SoundMusicSection section) => values
      .where((c) => c.isMusic && c.musicSection == section)
      .toList(growable: false);
}

class SoundChannelSettings {
  const SoundChannelSettings({this.enabled = true, this.volumePercent = 100});

  final bool enabled;
  final int volumePercent;

  SoundChannelSettings copyWith({bool? enabled, int? volumePercent}) {
    return SoundChannelSettings(
      enabled: enabled ?? this.enabled,
      volumePercent: (volumePercent ?? this.volumePercent).clamp(0, 100),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'volume': volumePercent,
      };

  factory SoundChannelSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SoundChannelSettings();
    return SoundChannelSettings(
      enabled: json['enabled'] != false,
      volumePercent: (json['volume'] as num?)?.toInt().clamp(0, 100) ?? 100,
    );
  }
}

abstract final class SoundChannelCodec {
  static Map<SoundChannel, SoundChannelSettings> decode(String? raw) {
    final out = <SoundChannel, SoundChannelSettings>{
      for (final channel in SoundChannel.values)
        channel: const SoundChannelSettings(),
    };
    if (raw == null || raw.isEmpty) return out;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return out;
      for (final channel in SoundChannel.values) {
        final value = decoded[channel.id];
        if (value is Map<String, dynamic>) {
          out[channel] = SoundChannelSettings.fromJson(value);
        } else if (value is Map) {
          out[channel] = SoundChannelSettings.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
    } catch (_) {}
    return out;
  }

  static String encode(Map<SoundChannel, SoundChannelSettings> map) {
    return jsonEncode({
      for (final channel in SoundChannel.values)
        channel.id: (map[channel] ?? const SoundChannelSettings()).toJson(),
    });
  }
}
