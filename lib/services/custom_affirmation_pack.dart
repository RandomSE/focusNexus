import 'dart:convert';
import 'dart:math';

import 'package:focusNexus/motivators/adhd_motivator_pack.dart';
import 'package:focusNexus/services/phrase_queue_positions.dart';
import 'package:focusNexus/utils/affirmation_selector.dart';

/// Separate customization surfaces (never mixed).
enum PhrasePackKind {
  dashboardMotivator('dashboard_motivator'),
  dailyAffirmation('daily_affirmation');

  const PhrasePackKind(this.storageValue);
  final String storageValue;

  String get label => switch (this) {
        PhrasePackKind.dashboardMotivator => 'Dashboard motivators',
        PhrasePackKind.dailyAffirmation => 'Daily affirmations',
      };
}

/// Playback for a phrase pack.
enum PhrasePlaybackMode {
  sequence('sequence'),
  random('random');

  const PhrasePlaybackMode(this.storageValue);
  final String storageValue;

  static PhrasePlaybackMode parse(String? raw) {
    if (raw == PhrasePlaybackMode.random.storageValue) {
      return PhrasePlaybackMode.random;
    }
    return PhrasePlaybackMode.sequence;
  }
}

/// Library message origin within one pack.
enum PhraseOrigin {
  baseline('baseline'),
  custom('custom');

  const PhraseOrigin(this.storageValue);
  final String storageValue;

  bool get isBaseline => this == PhraseOrigin.baseline;
  bool get isCustom => this == PhraseOrigin.custom;

  static PhraseOrigin parse(String? raw, {String? id}) {
    if (raw == PhraseOrigin.baseline.storageValue ||
        raw == 'baselineMotivator' ||
        raw == 'baselineAffirmation') {
      return PhraseOrigin.baseline;
    }
    if (raw == PhraseOrigin.custom.storageValue) return PhraseOrigin.custom;
    if (id != null && (id.startsWith('bm_') || id.startsWith('ba_'))) {
      return PhraseOrigin.baseline;
    }
    return PhraseOrigin.custom;
  }
}

/// Named queue snapshot (preset).
class PhrasePreset {
  const PhrasePreset({
    required this.id,
    required this.name,
    required this.queueIds,
  });

  final String id;
  final String name;
  final List<String> queueIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'queue': queueIds,
      };

  static PhrasePreset? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      return null;
    }
    final queueRaw = json['queue'];
    final queue = <String>[];
    if (queueRaw is List) {
      for (final item in queueRaw) {
        if (item is String) queue.add(item);
      }
    }
    if (queue.isEmpty) return null;
    return PhrasePreset(id: id, name: name.trim(), queueIds: queue);
  }
}

/// One line in a pack library.
class PhraseMessage {
  const PhraseMessage({
    required this.id,
    required this.text,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.origin = PhraseOrigin.custom,
  });

  final String id;
  final String text;
  final int createdAtMs;
  final int updatedAtMs;
  final PhraseOrigin origin;

  PhraseMessage copyWith({
    String? text,
    int? updatedAtMs,
    PhraseOrigin? origin,
  }) {
    return PhraseMessage(
      id: id,
      text: text ?? this.text,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      origin: origin ?? this.origin,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAtMs': createdAtMs,
        'updatedAtMs': updatedAtMs,
        'origin': origin.storageValue,
      };

  static PhraseMessage? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'];
    final text = json['text'];
    if (id is! String || id.isEmpty || text is! String) return null;
    return PhraseMessage(
      id: id,
      text: text,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (json['updatedAtMs'] as num?)?.toInt() ?? 0,
      origin: PhraseOrigin.parse(json['origin'] as String?, id: id),
    );
  }
}

/// Persisted pack for one [PhrasePackKind].
class PhrasePackData {
  const PhrasePackData({
    required this.enabled,
    required this.mode,
    required this.messages,
    required this.queueIds,
    required this.presets,
  });

  static const empty = PhrasePackData(
    enabled: false,
    mode: PhrasePlaybackMode.sequence,
    messages: <PhraseMessage>[],
    queueIds: <String>[],
    presets: <PhrasePreset>[],
  );

  final bool enabled;
  final PhrasePlaybackMode mode;
  final List<PhraseMessage> messages;
  final List<String> queueIds;
  final List<PhrasePreset> presets;

  bool get hasMessages => messages.isNotEmpty;
  bool get hasBaselineMessages => messages.any((m) => m.origin.isBaseline);
  bool get hasCustomMessages => messages.any((m) => m.origin.isCustom);

  List<PhraseMessage> messagesOf(PhraseOrigin origin) =>
      messages.where((m) => m.origin == origin).toList(growable: false);

  /// Active playback queue (known ids only); falls back to library order.
  List<String> get effectiveQueue {
    final known = {for (final m in messages) m.id};
    final filtered = queueIds.where(known.contains).toList(growable: false);
    if (filtered.isNotEmpty) return filtered;
    return messages.map((m) => m.id).toList(growable: false);
  }

  /// Messages in queue order (duplicates allowed when queue repeats ids).
  List<PhraseMessage> get playbackMessages {
    final out = <PhraseMessage>[];
    for (final id in effectiveQueue) {
      final msg = messageById(id);
      if (msg != null) out.add(msg);
    }
    return out;
  }

  String? textById(String id) {
    for (final m in messages) {
      if (m.id == id) return m.text;
    }
    return null;
  }

  PhraseMessage? messageById(String id) {
    for (final m in messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  PhrasePackData copyWith({
    bool? enabled,
    PhrasePlaybackMode? mode,
    List<PhraseMessage>? messages,
    List<String>? queueIds,
    List<PhrasePreset>? presets,
  }) {
    return PhrasePackData(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      messages: messages ?? this.messages,
      queueIds: queueIds ?? this.queueIds,
      presets: presets ?? this.presets,
    );
  }
}

/// Spend / seed / id rules.
abstract final class PhrasePackRules {
  PhrasePackRules._();

  static const int pointCost = 100;
  static const int maxTextLength = 160;

  static String? normalizeText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= maxTextLength) return trimmed;
    return trimmed.substring(0, maxTextLength);
  }

  static String newMessageId([int? nowMs]) {
    final ms = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return 'm_$ms';
  }

  static String newPresetId([int? nowMs]) {
    final ms = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return 'p_$ms';
  }

  static List<PhraseMessage> seedBaselines(
    PhrasePackKind kind, {
    int? nowMs,
  }) {
    final now = nowMs ?? 0;
    switch (kind) {
      case PhrasePackKind.dashboardMotivator:
        return [
          for (var i = 0; i < AdhdMotivatorPack.lines.length; i++)
            PhraseMessage(
              id: 'bm_$i',
              text: AdhdMotivatorPack.lines[i],
              createdAtMs: now,
              updatedAtMs: now,
              origin: PhraseOrigin.baseline,
            ),
        ];
      case PhrasePackKind.dailyAffirmation:
        final cores = AffirmationSelector.cores;
        return [
          for (var i = 0; i < cores.length; i++)
            PhraseMessage(
              id: 'ba_$i',
              text: cores[i],
              createdAtMs: now,
              updatedAtMs: now,
              origin: PhraseOrigin.baseline,
            ),
        ];
    }
  }
}

/// JSON codec for [PhrasePackData].
abstract final class PhrasePackCodec {
  PhrasePackCodec._();

  static PhrasePackData decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return PhrasePackData.empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return PhrasePackData.empty;
      final map = Map<String, dynamic>.from(decoded);
      final messages = <PhraseMessage>[];
      final messagesRaw = map['messages'];
      if (messagesRaw is List) {
        for (final item in messagesRaw) {
          if (item is Map) {
            final msg = PhraseMessage.fromJson(Map<String, dynamic>.from(item));
            if (msg != null) messages.add(msg);
          }
        }
      }
      // Legacy shared-pack migration: map old origins.
      final known = {for (final m in messages) m.id};
      final queue = <String>[];
      final queueRaw = map['queue'] ?? map['playlist'];
      if (queueRaw is List) {
        for (final item in queueRaw) {
          if (item is String && known.contains(item)) queue.add(item);
        }
      }
      final presets = <PhrasePreset>[];
      final presetsRaw = map['presets'];
      if (presetsRaw is List) {
        for (final item in presetsRaw) {
          if (item is Map) {
            final preset =
                PhrasePreset.fromJson(Map<String, dynamic>.from(item));
            if (preset != null) {
              final filtered =
                  preset.queueIds.where(known.contains).toList(growable: false);
              if (filtered.isNotEmpty) {
                presets.add(
                  PhrasePreset(
                    id: preset.id,
                    name: preset.name,
                    queueIds: filtered,
                  ),
                );
              }
            }
          }
        }
      }
      var enabled = map['enabled'] == true;
      if (enabled && messages.isEmpty) enabled = false;
      return PhrasePackData(
        enabled: enabled,
        mode: PhrasePlaybackMode.parse(map['mode'] as String?),
        messages: List.unmodifiable(messages),
        queueIds: List.unmodifiable(queue),
        presets: List.unmodifiable(presets),
      );
    } catch (_) {
      return PhrasePackData.empty;
    }
  }

  static String encode(PhrasePackData data) {
    return jsonEncode({
      'enabled': data.enabled,
      'mode': data.mode.storageValue,
      'messages': data.messages.map((m) => m.toJson()).toList(),
      'queue': data.queueIds,
      'presets': data.presets.map((p) => p.toJson()).toList(),
    });
  }
}

/// Selection for dashboard / notification bodies.
abstract final class PhrasePackSelector {
  PhrasePackSelector._();

  /// 0-based playback index for [date] after a queue of [queueLength].
  static int indexForDate({
    required int queueLength,
    required PhrasePlaybackMode mode,
    required DateTime date,
  }) {
    if (queueLength <= 0) return 0;
    if (mode == PhrasePlaybackMode.random) {
      final day = DateTime(date.year, date.month, date.day);
      final seed = Object.hash(day.year, day.month, day.day, queueLength);
      return Random(seed).nextInt(queueLength);
    }
    return AdhdMotivatorPack.seedForDate(date) % queueLength;
  }

  /// 1-based add slot so today's refresh / next affirmation is the new line.
  static int defaultInsertPosition1Based({
    required int currentQueueLength,
    required PhrasePlaybackMode mode,
    required DateTime now,
  }) {
    return indexForDate(
          queueLength: currentQueueLength + 1,
          mode: mode,
          date: now,
        ) +
        1;
  }

  static String? customCoreForDate(PhrasePackData pack, DateTime date) {
    if (!pack.enabled) return null;
    final queue = pack.effectiveQueue;
    if (queue.isEmpty) return null;
    final index = indexForDate(
      queueLength: queue.length,
      mode: pack.mode,
      date: date,
    );
    return pack.textById(queue[index]);
  }

  static String lineAtQueueIndex(PhrasePackData pack, int index) {
    final queue = pack.effectiveQueue;
    if (queue.isEmpty) return AdhdMotivatorPack.lineAt(index);
    final i = index % queue.length;
    final id = queue[i < 0 ? i + queue.length : i];
    return pack.textById(id) ?? AdhdMotivatorPack.lineAt(index);
  }

  /// Alias for older call sites / tests.
  static String lineAtPlaylistIndex(PhrasePackData pack, int index) =>
      lineAtQueueIndex(pack, index);

  static String dashboardLineForDate(PhrasePackData pack, DateTime date) {
    if (!pack.enabled || pack.effectiveQueue.isEmpty) {
      return AdhdMotivatorPack.forDate(date);
    }
    return customCoreForDate(pack, date) ?? AdhdMotivatorPack.forDate(date);
  }

  static int sequenceIndexForDate(PhrasePackData pack, DateTime date) {
    return indexForDate(
      queueLength: pack.effectiveQueue.length,
      mode: PhrasePlaybackMode.sequence,
      date: date,
    );
  }

  static int nextRandomIndex({
    required int count,
    required int currentIndex,
    required Random random,
  }) {
    if (count <= 1) return 0;
    var next = random.nextInt(count);
    if (next == currentIndex) next = (next + 1) % count;
    return next;
  }

  static int nextRandomMessageIndex({
    required int messageCount,
    required int currentIndex,
    required Random random,
  }) =>
      nextRandomIndex(
        count: messageCount,
        currentIndex: currentIndex,
        random: random,
      );

  static int indexForText(PhrasePackData pack, String text) {
    final queue = pack.effectiveQueue;
    for (var i = 0; i < queue.length; i++) {
      if (pack.textById(queue[i]) == text) return i;
    }
    return 0;
  }

  static int messageIndexForText(PhrasePackData pack, String text) =>
      indexForText(pack, text);
}

/// Insert helpers bound to pack queue semantics.
abstract final class PhrasePackQueue {
  PhrasePackQueue._();

  static List<String> insertMessage({
    required List<String> queue,
    required String id,
    required int position1Based,
  }) {
    return PhraseQueuePositions.insertAt(
      queue: queue,
      id: id,
      position1Based: position1Based,
    );
  }

  static List<String> moveSlot({
    required List<String> queue,
    required int fromIndex,
    required int position1Based,
  }) {
    return PhraseQueuePositions.moveIndexToPosition(
      queue: queue,
      fromIndex: fromIndex,
      position1Based: position1Based,
    );
  }

  /// Split a legacy shared pack into one kind's library + queue.
  static PhrasePackData migrateLegacy(PhrasePackData legacy, PhrasePackKind kind) {
    final keep = <PhraseMessage>[];
    for (final m in legacy.messages) {
      if (m.origin.isCustom) {
        keep.add(m);
        continue;
      }
      final isMotivatorId = m.id.startsWith('bm_');
      final isAffirmationId = m.id.startsWith('ba_');
      if (kind == PhrasePackKind.dashboardMotivator &&
          (isMotivatorId || (!isAffirmationId && !isMotivatorId))) {
        // Baseline without ba_ prefix: treat as motivator when splitting.
        if (!isAffirmationId) keep.add(m);
      } else if (kind == PhrasePackKind.dailyAffirmation && isAffirmationId) {
        keep.add(m);
      } else if (kind == PhrasePackKind.dailyAffirmation &&
          !isMotivatorId &&
          !isAffirmationId) {
        // Unprefixed baseline: skip for affirmations (seed will refill).
      }
    }
    final known = {for (final m in keep) m.id};
    final queue = legacy.effectiveQueue.where(known.contains).toList();
    final presets = <PhrasePreset>[];
    for (final p in legacy.presets) {
      final filtered = p.queueIds.where(known.contains).toList(growable: false);
      if (filtered.isNotEmpty) {
        presets.add(
          PhrasePreset(id: p.id, name: p.name, queueIds: filtered),
        );
      }
    }
    return PhrasePackData(
      enabled: legacy.enabled && keep.isNotEmpty,
      mode: legacy.mode,
      messages: List.unmodifiable(keep),
      queueIds: List.unmodifiable(queue),
      presets: List.unmodifiable(presets),
    );
  }
}

// --- Backward-compatible aliases used by older call sites during migration ---

typedef CustomAffirmationPlaybackMode = PhrasePlaybackMode;
typedef CustomAffirmationOrigin = PhraseOrigin;
typedef CustomAffirmationMessage = PhraseMessage;
typedef CustomAffirmationPackData = PhrasePackData;
typedef CustomAffirmationPackRules = PhrasePackRules;
typedef CustomAffirmationPackCodec = PhrasePackCodec;
typedef CustomAffirmationPackSelector = PhrasePackSelector;
