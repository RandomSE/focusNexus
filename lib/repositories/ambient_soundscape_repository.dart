import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/ambient_soundscape.dart';
import 'package:focusNexus/services/sound_channel.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Persists owned ambient tracks and global / per-section selection.
class AmbientSoundscapeRepository {
  AmbientSoundscapeRepository(this._storage, {PointsRepository? points})
      : _points = points;

  final KeyValueStorage _storage;
  final PointsRepository? _points;

  bool? _cachedEnabled;
  AmbientSelectionMode? _cachedMode;
  String? _cachedGlobalTrackId;
  Map<String, String>? _cachedSectionMap;
  Set<String>? _cachedOwnedIds;

  @visibleForTesting
  int resolveStorageReadCount = 0;

  void invalidateSelectionCache() {
    _cachedEnabled = null;
    _cachedMode = null;
    _cachedGlobalTrackId = null;
    _cachedSectionMap = null;
    _cachedOwnedIds = null;
  }

  /// Account wipe: drop caches and restore ambient defaults on disk.
  Future<void> resetForAccountWipe() async {
    invalidateSelectionCache();
    await writeEnabled(false);
    await writeOwnedIds({});
    await writeSelectionMode(AmbientSelectionMode.global);
    await writeGlobalTrackId(AmbientSoundscapeCatalog.noneTrackId);
    await writeSectionTrackIds({
      for (final section in AmbientAppSection.values)
        section.storageValue: AmbientSoundscapeCatalog.noneTrackId,
    });
  }

  Future<Set<String>> readOwnedIds() async {
    if (_cachedOwnedIds != null) return Set<String>.from(_cachedOwnedIds!);
    resolveStorageReadCount += 1;
    final owned = AmbientSoundscapeCodec.decodeOwned(
      await _storage.read(key: StorageKeys.ownedAmbientSounds),
    );
    _cachedOwnedIds = owned;
    return Set<String>.from(owned);
  }

  Future<void> writeOwnedIds(Set<String> ids) async {
    final owned = <String>{
      ...AmbientSoundscapeCatalog.freeTrackIds,
      ...ids,
    };
    await _storage.write(
      key: StorageKeys.ownedAmbientSounds,
      value: AmbientSoundscapeCodec.encodeOwned(owned),
    );
    _cachedOwnedIds = Set<String>.from(owned);
  }

  /// Master on/off for ambient playback. Default false (off).
  Future<bool> readEnabled() async {
    if (_cachedEnabled != null) return _cachedEnabled!;
    resolveStorageReadCount += 1;
    final raw = await _storage.read(key: StorageKeys.ambientEnabled);
    final enabled = bool.tryParse(raw ?? 'false') ?? false;
    _cachedEnabled = enabled;
    return enabled;
  }

  Future<void> writeEnabled(bool enabled) async {
    await _storage.write(
      key: StorageKeys.ambientEnabled,
      value: enabled.toString(),
    );
    _cachedEnabled = enabled;
  }

  Future<AmbientSelectionMode> readSelectionMode() async {
    if (_cachedMode != null) return _cachedMode!;
    resolveStorageReadCount += 1;
    final mode = AmbientSelectionMode.parse(
      await _storage.read(key: StorageKeys.ambientSelectionMode),
    );
    _cachedMode = mode;
    return mode;
  }

  Future<void> writeSelectionMode(AmbientSelectionMode mode) async {
    await _storage.write(
      key: StorageKeys.ambientSelectionMode,
      value: mode.storageValue,
    );
    _cachedMode = mode;
  }

  Future<String> readGlobalTrackId() async {
    if (_cachedGlobalTrackId != null) return _cachedGlobalTrackId!;
    resolveStorageReadCount += 1;
    final raw = await _storage.read(key: StorageKeys.ambientGlobalTrackId);
    final id = raw ?? AmbientSoundscapeCatalog.noneTrackId;
    _cachedGlobalTrackId = id;
    return id;
  }

  Future<void> writeGlobalTrackId(String trackId) async {
    await _storage.write(
      key: StorageKeys.ambientGlobalTrackId,
      value: trackId,
    );
    _cachedGlobalTrackId = trackId;
  }

  Future<Map<String, String>> readSectionTrackIds() async {
    if (_cachedSectionMap != null) {
      return Map<String, String>.from(_cachedSectionMap!);
    }
    resolveStorageReadCount += 1;
    final map = AmbientSoundscapeCodec.decodeSectionMap(
      await _storage.read(key: StorageKeys.ambientSectionTracks),
    );
    _cachedSectionMap = map;
    return Map<String, String>.from(map);
  }

  Future<void> writeSectionTrackIds(Map<String, String> map) async {
    await _storage.write(
      key: StorageKeys.ambientSectionTracks,
      value: AmbientSoundscapeCodec.encodeSectionMap(map),
    );
    _cachedSectionMap = Map<String, String>.from(map);
  }

  /// Applies [trackId] to every section and switches mode to global.
  /// Pass [AmbientSoundscapeCatalog.noneTrackId] to clear playback.
  Future<void> applyTrackToAllSections(String trackId) async {
    if (!AmbientSoundscapeCatalog.isSpecialSelection(trackId)) {
      final owned = await readOwnedIds();
      if (!owned.contains(trackId)) return;
    }
    await writeSelectionMode(AmbientSelectionMode.global);
    await writeGlobalTrackId(trackId);
    await writeSectionTrackIds({
      for (final section in AmbientAppSection.values)
        section.storageValue: trackId,
    });
  }

  /// Sets one section override and switches mode to per-section.
  Future<void> applyTrackToSection({
    required AmbientAppSection section,
    required String trackId,
  }) async {
    if (!AmbientSoundscapeCatalog.isSpecialSelection(trackId)) {
      final owned = await readOwnedIds();
      if (!owned.contains(trackId)) return;
    }
    await writeSelectionMode(AmbientSelectionMode.perSection);
    final map = await readSectionTrackIds();
    map[section.storageValue] = trackId;
    await writeSectionTrackIds(map);
  }

  Future<SoundChannel?> resolveForSection(AmbientAppSection section) async {
    if (!await readEnabled()) return null;
    final mode = await readSelectionMode();
    final globalId = await readGlobalTrackId();
    final sectionMap = await readSectionTrackIds();
    final owned = await readOwnedIds();
    return AmbientSoundscapeCatalog.resolveChannel(
      mode: mode,
      globalTrackId: globalId,
      sectionTrackIds: sectionMap,
      section: section,
      ownedIds: owned,
    );
  }

  Future<String> resolveSelectionIdForSection(AmbientAppSection section) async {
    final mode = await readSelectionMode();
    final globalId = await readGlobalTrackId();
    final sectionMap = await readSectionTrackIds();
    return AmbientSoundscapeCatalog.resolveSelectionId(
      mode: mode,
      globalTrackId: globalId,
      sectionTrackIds: sectionMap,
      section: section,
    );
  }

  /// Whether progressive-visuals feature BGM (zen/cherry/bonsai) should stay off.
  Future<bool> shouldSuppressFeatureBgm(AmbientAppSection section) async {
    if (!await readEnabled()) return false;
    if (section != AmbientAppSection.progressiveVisuals) return false;
    final id = await resolveSelectionIdForSection(section);
    return AmbientSoundscapeCatalog.suppressesFeatureBgm(id);
  }

  /// Spends points to unlock [trackId]. Returns new balance, or null on fail.
  /// Already-owned is a no-op that returns the current balance.
  Future<int?> tryUnlock(String trackId) async {
    final entry = AmbientSoundscapeCatalog.entryForId(trackId);
    if (entry == null) return null;

    final owned = await readOwnedIds();
    final points = _points;
    if (points == null) return null;

    if (owned.contains(trackId)) {
      return points.readBalance();
    }
    if (entry.isFree) {
      owned.add(trackId);
      await writeOwnedIds(owned);
      return points.readBalance();
    }

    final spent = await points.trySpend(entry.pointCost);
    if (spent == null) return null;
    owned.add(trackId);
    await writeOwnedIds(owned);
    return spent;
  }
}
