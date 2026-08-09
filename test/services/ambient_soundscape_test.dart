import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';

void main() {
  test('catalog prices and free defaults match product table', () {
    expect(
      AmbientSoundscapeCatalog.entries.map((e) => (e.id, e.pointCost)).toList(),
      [
        ('running_water', 0),
        ('white_noise', 0),
        ('forest_at_night', 200),
        ('ocean_waves', 300),
        ('pink_noise', 400),
        ('wind_chimes', 500),
        ('distant_thunder', 700),
        ('piano', 1000),
      ],
    );
    expect(
      AmbientSoundscapeCatalog.freeTrackIds,
      {'running_water', 'white_noise'},
    );
    expect(
      SoundChannel.ambientRunningWater.assetPath,
      'sounds/music/customization/running_stream.mp3',
    );
    expect(SoundChannel.ambientRunningWater.label, 'Running water');
  });

  test('empty owned codec seeds free tracks only', () {
    expect(
      AmbientSoundscapeCodec.decodeOwned(null),
      {'running_water', 'white_noise'},
    );
  });

  test('owned codec always keeps free tracks and round-trips extras', () {
    final encoded = AmbientSoundscapeCodec.encodeOwned(['forest_at_night']);
    final decoded = AmbientSoundscapeCodec.decodeOwned(encoded);
    expect(decoded.contains('running_water'), isTrue);
    expect(decoded.contains('white_noise'), isTrue);
    expect(decoded.contains('forest_at_night'), isTrue);
  });

  test('global mode with no selection resolves to silence', () {
    final channel = AmbientSoundscapeCatalog.resolveChannel(
      mode: AmbientSelectionMode.global,
      globalTrackId: null,
      sectionTrackIds: const {},
      section: AmbientAppSection.dashboard,
      ownedIds: AmbientSoundscapeCatalog.freeTrackIds,
    );
    expect(channel, isNull);
  });

  test('global mode plays only after explicit track id', () {
    final channel = AmbientSoundscapeCatalog.resolveChannel(
      mode: AmbientSelectionMode.global,
      globalTrackId: 'running_water',
      sectionTrackIds: const {},
      section: AmbientAppSection.dashboard,
      ownedIds: AmbientSoundscapeCatalog.freeTrackIds,
    );
    expect(channel, SoundChannel.ambientRunningWater);
  });

  test('per-section override wins over empty other sections', () {
    final channel = AmbientSoundscapeCatalog.resolveChannel(
      mode: AmbientSelectionMode.perSection,
      globalTrackId: AmbientSoundscapeCatalog.noneTrackId,
      sectionTrackIds: {
        AmbientAppSection.goals.storageValue: 'white_noise',
      },
      section: AmbientAppSection.goals,
      ownedIds: AmbientSoundscapeCatalog.freeTrackIds,
    );
    expect(channel, SoundChannel.ambientWhiteNoise);
  });

  test('per-section without override stays silent', () {
    final channel = AmbientSoundscapeCatalog.resolveChannel(
      mode: AmbientSelectionMode.perSection,
      globalTrackId: AmbientSoundscapeCatalog.noneTrackId,
      sectionTrackIds: const {},
      section: AmbientAppSection.dashboard,
      ownedIds: AmbientSoundscapeCatalog.freeTrackIds,
    );
    expect(channel, isNull);
  });

  test('resolve returns null when selected track is not owned', () {
    final channel = AmbientSoundscapeCatalog.resolveChannel(
      mode: AmbientSelectionMode.global,
      globalTrackId: 'piano',
      sectionTrackIds: const {},
      section: AmbientAppSection.dashboard,
      ownedIds: AmbientSoundscapeCatalog.freeTrackIds,
    );
    expect(channel, isNull);
  });

  test('section map codec defaults all sections to no track', () {
    final map = AmbientSoundscapeCodec.decodeSectionMap(null);
    expect(map.length, AmbientAppSection.values.length);
    for (final section in AmbientAppSection.values) {
      expect(map[section.storageValue], AmbientSoundscapeCatalog.noneTrackId);
    }
  });
}
