import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/sound_channel.dart';

void main() {
  test('channels are grouped by function for the sound effects page', () {
    expect(SoundChannel.forGroup(SoundChannelGroup.music).map((c) => c.id), [
      'breath_background',
      'zen_garden_music',
      'cherry_stage_1_music',
      'cherry_stage_2_music',
      'cherry_balance_music',
      'cherry_peace_music',
      'cherry_power_music',
      'bonsai_music',
    ]);
    expect(SoundChannel.forGroup(SoundChannelGroup.goals).map((c) => c.id), [
      'goal_created',
      'goal_completed',
    ]);
    expect(
      SoundChannel.forGroup(SoundChannelGroup.achievements).map((c) => c.id),
      ['achievement_completed'],
    );
    expect(
      SoundChannel.forGroup(SoundChannelGroup.miniGames).map((c) => c.id),
      [
        'firefly_click',
        'rock_falling',
        'game_failed',
        'breath_click',
        'meteor_click',
        'word_bloom_click',
        'word_collected',
        'rain_catch_click',
        'rain_miss',
      ],
    );
  });

  test('music channels live under sounds/music/', () {
    for (final channel in SoundChannel.values.where((c) => c.isMusic)) {
      expect(channel.assetPath.startsWith('sounds/music/'), isTrue);
    }
    expect(
      SoundChannel.breathBackground.assetPath,
      'sounds/music/breath_background.mp3',
    );
  });

  test('codec round-trips channel enable and volume', () {
    final encoded = SoundChannelCodec.encode({
      SoundChannel.fireflyClick: const SoundChannelSettings(
        enabled: false,
        volumePercent: 40,
      ),
    });
    final decoded = SoundChannelCodec.decode(encoded);
    expect(decoded[SoundChannel.fireflyClick]!.enabled, isFalse);
    expect(decoded[SoundChannel.fireflyClick]!.volumePercent, 40);
    expect(decoded[SoundChannel.goalCreated]!.enabled, isTrue);
  });
}
