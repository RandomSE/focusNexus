import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/ambient_soundscape_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late PointsRepository points;
  late AmbientSoundscapeRepository repo;

  setUp(() {
    storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '1000'},
    );
    points = PointsRepository(storage);
    repo = AmbientSoundscapeRepository(storage, points: points);
  });

  test('defaults unlock free tracks but select no music until user chooses',
      () async {
    expect(await repo.readOwnedIds(), {'running_water', 'white_noise'});
    expect(await repo.readEnabled(), isFalse);
    expect(await repo.readSelectionMode(), AmbientSelectionMode.global);
    expect(await repo.readGlobalTrackId(), AmbientSoundscapeCatalog.noneTrackId);
    expect(
      await repo.resolveForSection(AmbientAppSection.dashboard),
      isNull,
    );
  });

  test('disabled master toggle keeps silence even with a selected track',
      () async {
    await repo.applyTrackToAllSections('running_water');
    await repo.writeEnabled(false);
    expect(
      await repo.resolveForSection(AmbientAppSection.dashboard),
      isNull,
    );
  });

  test('enabled master toggle plays selected track', () async {
    await repo.applyTrackToAllSections('running_water');
    await repo.writeEnabled(true);
    expect(
      await repo.resolveForSection(AmbientAppSection.dashboard),
      SoundChannel.ambientRunningWater,
    );
  });

  test('tryUnlock spends points and persists ownership', () async {
    final balance = await repo.tryUnlock('forest_at_night');
    expect(balance, 800);
    expect((await repo.readOwnedIds()).contains('forest_at_night'), isTrue);
  });

  test('tryUnlock is no-op when already owned', () async {
    await repo.tryUnlock('forest_at_night');
    final again = await repo.tryUnlock('forest_at_night');
    expect(again, 800);
  });

  test('tryUnlock leaves owned unchanged when insufficient points', () async {
    storage = InMemoryKeyValueStorage(initial: {StorageKeys.points: '50'});
    points = PointsRepository(storage);
    repo = AmbientSoundscapeRepository(storage, points: points);

    final result = await repo.tryUnlock('piano');
    expect(result, isNull);
    expect((await repo.readOwnedIds()).contains('piano'), isFalse);
    expect(await points.readBalance(), 50);
  });

  test('applyTrackToAllSections overwrites section map and sets global', () async {
    await repo.tryUnlock('forest_at_night');
    await repo.applyTrackToSection(
      section: AmbientAppSection.goals,
      trackId: 'white_noise',
    );
    expect(await repo.readSelectionMode(), AmbientSelectionMode.perSection);

    await repo.applyTrackToAllSections('forest_at_night');
    expect(await repo.readSelectionMode(), AmbientSelectionMode.global);
    expect(await repo.readGlobalTrackId(), 'forest_at_night');
    final map = await repo.readSectionTrackIds();
    for (final section in AmbientAppSection.values) {
      expect(map[section.storageValue], 'forest_at_night');
    }
  });

  test('applyTrackToSection does not apply locked tracks', () async {
    await repo.applyTrackToSection(
      section: AmbientAppSection.dashboard,
      trackId: 'piano',
    );
    expect(await repo.readSelectionMode(), AmbientSelectionMode.global);
    expect(
      await repo.resolveForSection(AmbientAppSection.dashboard),
      isNull,
    );
  });

  test('mute_all suppresses progressive visuals feature BGM only', () async {
    await repo.writeEnabled(true);
    await repo.applyTrackToSection(
      section: AmbientAppSection.progressiveVisuals,
      trackId: AmbientSoundscapeCatalog.muteAllTrackId,
    );
    expect(
      await repo.resolveForSection(AmbientAppSection.progressiveVisuals),
      isNull,
    );
    expect(
      await repo.shouldSuppressFeatureBgm(AmbientAppSection.progressiveVisuals),
      isTrue,
    );
    expect(
      await repo.shouldSuppressFeatureBgm(AmbientAppSection.dashboard),
      isFalse,
    );
  });

  test('garden music only keeps feature BGM', () async {
    await repo.writeEnabled(true);
    await repo.applyTrackToSection(
      section: AmbientAppSection.progressiveVisuals,
      trackId: AmbientSoundscapeCatalog.noneTrackId,
    );
    expect(
      await repo.shouldSuppressFeatureBgm(AmbientAppSection.progressiveVisuals),
      isFalse,
    );
  });

  test('explicit Use starts playback for a free track when enabled', () async {
    await repo.writeEnabled(true);
    await repo.applyTrackToAllSections('running_water');
    expect(
      await repo.resolveForSection(AmbientAppSection.dashboard),
      SoundChannel.ambientRunningWater,
    );
  });

  test('resolveForSection caches selection reads after first resolve', () async {
    await repo.writeEnabled(true);
    await repo.applyTrackToAllSections('running_water');
    repo.invalidateSelectionCache();
    repo.resolveStorageReadCount = 0;

    expect(
      await repo.resolveForSection(AmbientAppSection.dashboard),
      SoundChannel.ambientRunningWater,
    );
    final firstReads = repo.resolveStorageReadCount;
    expect(firstReads, greaterThanOrEqualTo(4));

    expect(
      await repo.resolveForSection(AmbientAppSection.goals),
      SoundChannel.ambientRunningWater,
    );
    expect(repo.resolveStorageReadCount, firstReads);
  });
}
