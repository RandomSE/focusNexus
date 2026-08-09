import 'dart:convert';

import 'package:focusNexus/services/sound_channel.dart';

/// App areas that can play a selected ambient soundscape.
enum AmbientAppSection {
  dashboard('dashboard', 'Dashboard'),
  goals('goals', 'Goals'),
  achievements('achievements', 'Achievements'),
  progressiveVisuals('progressive_visuals', 'Progressive visuals'),
  miniGames('mini_games', 'Mini-games'),
  aiChat('ai_chat', 'AI chat'),
  customization('customization', 'Customization'),
  settings('settings', 'Settings'),
  music('music', 'Music');

  const AmbientAppSection(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static AmbientAppSection? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final section in values) {
      if (section.storageValue == raw) return section;
    }
    return null;
  }
}

/// Whether one track applies everywhere or each section has its own.
enum AmbientSelectionMode {
  global('global'),
  perSection('per_section');

  const AmbientSelectionMode(this.storageValue);
  final String storageValue;

  static AmbientSelectionMode parse(String? raw) {
    if (raw == AmbientSelectionMode.perSection.storageValue) {
      return AmbientSelectionMode.perSection;
    }
    return AmbientSelectionMode.global;
  }
}

/// Points-shop entry for a customization ambient track.
class AmbientCatalogEntry {
  const AmbientCatalogEntry({
    required this.channel,
    required this.pointCost,
  });

  final SoundChannel channel;
  final int pointCost;

  bool get isFree => pointCost <= 0;
  String get id => channel.id;
  String get label => channel.label;
}

/// Catalog, defaults, and pure resolution for ambient soundscapes.
abstract final class AmbientSoundscapeCatalog {
  /// Sentinel: no custom ambient (feature BGM still allowed).
  static const String noneTrackId = '';

  /// Progressive visuals only: silence ambient and suppress zen/cherry/bonsai BGM.
  static const String muteAllTrackId = 'mute_all';

  /// Prefer [noneTrackId]; kept for catalog docs / migrations.
  static const String defaultTrackId = noneTrackId;

  static bool isSpecialSelection(String id) =>
      id.isEmpty || id == muteAllTrackId;

  static bool suppressesFeatureBgm(String id) => id == muteAllTrackId;

  static final List<AmbientCatalogEntry> entries = [
    AmbientCatalogEntry(
      channel: SoundChannel.ambientRunningWater,
      pointCost: 0,
    ),
    AmbientCatalogEntry(
      channel: SoundChannel.ambientWhiteNoise,
      pointCost: 0,
    ),
    AmbientCatalogEntry(
      channel: SoundChannel.ambientForestAtNight,
      pointCost: 200,
    ),
    AmbientCatalogEntry(
      channel: SoundChannel.ambientOceanWaves,
      pointCost: 300,
    ),
    AmbientCatalogEntry(
      channel: SoundChannel.ambientPinkNoise,
      pointCost: 400,
    ),
    AmbientCatalogEntry(
      channel: SoundChannel.ambientWindChimes,
      pointCost: 500,
    ),
    AmbientCatalogEntry(
      channel: SoundChannel.ambientDistantThunder,
      pointCost: 700,
    ),
    AmbientCatalogEntry(
      channel: SoundChannel.ambientPiano,
      pointCost: 1000,
    ),
  ];

  static Set<String> get freeTrackIds => {
        for (final entry in entries)
          if (entry.isFree) entry.id,
      };

  static AmbientCatalogEntry? entryForId(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  static SoundChannel? channelForId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final entry in entries) {
      if (entry.id == id) return entry.channel;
    }
    return null;
  }

  static bool isAmbientChannel(SoundChannel channel) =>
      channel.isMusic && channel.musicSection == SoundMusicSection.ambient;

  /// Resolves which unlocked track plays for [section], or null if none /
  /// silence / mute-all / not yet chosen.
  static SoundChannel? resolveChannel({
    required AmbientSelectionMode mode,
    required String? globalTrackId,
    required Map<String, String> sectionTrackIds,
    required AmbientAppSection section,
    required Set<String> ownedIds,
  }) {
    final rawId = mode == AmbientSelectionMode.global
        ? (globalTrackId ?? noneTrackId)
        : (sectionTrackIds[section.storageValue] ?? noneTrackId);
    if (rawId.isEmpty || rawId == muteAllTrackId) return null;
    if (!ownedIds.contains(rawId)) return null;
    return channelForId(rawId);
  }

  /// Raw selection id for [section] (may be [noneTrackId] or [muteAllTrackId]).
  static String resolveSelectionId({
    required AmbientSelectionMode mode,
    required String? globalTrackId,
    required Map<String, String> sectionTrackIds,
    required AmbientAppSection section,
  }) {
    if (mode == AmbientSelectionMode.global) {
      return globalTrackId ?? noneTrackId;
    }
    return sectionTrackIds[section.storageValue] ?? noneTrackId;
  }
}

/// JSON helpers for owned ids and per-section maps.
abstract final class AmbientSoundscapeCodec {
  static Set<String> decodeOwned(String? raw) {
    if (raw == null || raw.isEmpty) {
      return Set<String>.from(AmbientSoundscapeCatalog.freeTrackIds);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return Set<String>.from(AmbientSoundscapeCatalog.freeTrackIds);
      }
      final owned = <String>{
        for (final item in decoded)
          if (item is String && item.isNotEmpty) item,
      };
      owned.addAll(AmbientSoundscapeCatalog.freeTrackIds);
      return owned;
    } catch (_) {
      return Set<String>.from(AmbientSoundscapeCatalog.freeTrackIds);
    }
  }

  static String encodeOwned(Iterable<String> ids) {
    final owned = <String>{
      ...AmbientSoundscapeCatalog.freeTrackIds,
      ...ids,
    };
    return jsonEncode(owned.toList()..sort());
  }

  static Map<String, String> decodeSectionMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {
        for (final section in AmbientAppSection.values)
          section.storageValue: AmbientSoundscapeCatalog.noneTrackId,
      };
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {
          for (final section in AmbientAppSection.values)
            section.storageValue: AmbientSoundscapeCatalog.noneTrackId,
        };
      }
      final out = <String, String>{
        for (final section in AmbientAppSection.values)
          section.storageValue: AmbientSoundscapeCatalog.noneTrackId,
      };
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value?.toString();
        if (AmbientAppSection.tryParse(key) != null && value != null) {
          out[key] = value;
        }
      }
      return out;
    } catch (_) {
      return {
        for (final section in AmbientAppSection.values)
          section.storageValue: AmbientSoundscapeCatalog.noneTrackId,
      };
    }
  }

  static String encodeSectionMap(Map<String, String> map) {
    return jsonEncode({
      for (final section in AmbientAppSection.values)
        section.storageValue:
            map[section.storageValue] ?? AmbientSoundscapeCatalog.noneTrackId,
    });
  }
}
