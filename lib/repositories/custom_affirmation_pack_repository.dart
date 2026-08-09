import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/custom_affirmation_pack.dart';
import 'package:focusNexus/services/phrase_queue_positions.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Outcome of a pack mutation that may spend points.
class PhrasePackMutationResult {
  const PhrasePackMutationResult._({
    required this.ok,
    this.error,
    this.balance,
    this.data,
  });

  factory PhrasePackMutationResult.success({
    required PhrasePackData data,
    int? balance,
  }) {
    return PhrasePackMutationResult._(
      ok: true,
      balance: balance,
      data: data,
    );
  }

  factory PhrasePackMutationResult.fail(
    String error, {
    int? balance,
  }) {
    return PhrasePackMutationResult._(
      ok: false,
      error: error,
      balance: balance,
    );
  }

  final bool ok;
  final String? error;
  final int? balance;
  final PhrasePackData? data;

  static const insufficientPoints = 'insufficient_points';
  static const emptyText = 'empty_text';
  static const minOne = 'min_one';
  static const notFound = 'not_found';
  static const emptyName = 'empty_name';
}

typedef CustomAffirmationPackMutationResult = PhrasePackMutationResult;

/// Persists separate phrase packs (dashboard motivators vs daily affirmations).
class PhrasePackRepository {
  PhrasePackRepository(this._storage, {PointsRepository? points})
      : _points = points;

  final KeyValueStorage _storage;
  final PointsRepository? _points;

  String _keyFor(PhrasePackKind kind) => switch (kind) {
        PhrasePackKind.dashboardMotivator =>
          StorageKeys.dashboardMotivatorPack,
        PhrasePackKind.dailyAffirmation => StorageKeys.dailyAffirmationPack,
      };

  Future<PhrasePackData> read(PhrasePackKind kind) async {
    final key = _keyFor(kind);
    final raw = await _storage.read(key: key);
    if (raw != null && raw.trim().isNotEmpty) {
      return PhrasePackCodec.decode(raw);
    }
    // One-time migrate from legacy shared pack key.
    final legacyRaw =
        await _storage.read(key: StorageKeys.customAffirmationPack);
    if (legacyRaw == null || legacyRaw.trim().isEmpty) {
      return PhrasePackData.empty;
    }
    final legacy = PhrasePackCodec.decode(legacyRaw);
    final migrated = PhrasePackQueue.migrateLegacy(legacy, kind);
    if (migrated.hasMessages) {
      await write(kind, migrated);
    }
    return migrated;
  }

  Future<void> write(PhrasePackKind kind, PhrasePackData data) async {
    await _storage.write(
      key: _keyFor(kind),
      value: PhrasePackCodec.encode(data),
    );
  }

  Future<bool> readEnabled(PhrasePackKind kind) async =>
      (await read(kind)).enabled;

  /// Ensures kind-specific baselines exist as editable copies (free).
  Future<PhrasePackData> ensureSeeded(PhrasePackKind kind) async {
    final current = await read(kind);
    if (current.hasMessages) return current;
    final seeded = PhrasePackRules.seedBaselines(
      kind,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    final next = current.copyWith(
      messages: seeded,
      queueIds: seeded.map((m) => m.id).toList(),
      enabled: false,
    );
    await write(kind, next);
    return next;
  }

  Future<PhrasePackMutationResult> trySetEnabled(
    PhrasePackKind kind,
    bool enabled,
  ) async {
    var current = await read(kind);
    if (enabled && !current.hasMessages) {
      current = await ensureSeeded(kind);
    }
    final next = current.copyWith(enabled: enabled);
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next);
  }

  Future<PhrasePackMutationResult> tryAddMessage(
    PhrasePackKind kind,
    String rawText, {
    int? position1Based,
  }) async {
    final text = PhrasePackRules.normalizeText(rawText);
    if (text == null) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.emptyText);
    }
    final points = _points;
    if (points == null) {
      return PhrasePackMutationResult.fail(
        PhrasePackMutationResult.insufficientPoints,
      );
    }
    final spent = await points.trySpend(PhrasePackRules.pointCost);
    if (spent == null) {
      return PhrasePackMutationResult.fail(
        PhrasePackMutationResult.insufficientPoints,
        balance: await points.readBalance(),
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = PhrasePackRules.newMessageId(now);
    final current = await read(kind);
    final message = PhraseMessage(
      id: id,
      text: text,
      createdAtMs: now,
      updatedAtMs: now,
      origin: PhraseOrigin.custom,
    );
    final queue = current.effectiveQueue;
    final pos = position1Based ?? PhraseQueuePositions.maxInsertPosition(queue.length);
    final nextQueue = PhrasePackQueue.insertMessage(
      queue: queue,
      id: id,
      position1Based: pos,
    );
    final next = current.copyWith(
      messages: [...current.messages, message],
      queueIds: nextQueue,
    );
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next, balance: spent);
  }

  /// Update text and/or move a queue slot. Text changes cost points.
  Future<PhrasePackMutationResult> tryUpdateQueueSlot(
    PhrasePackKind kind, {
    required int slotIndex,
    String? rawText,
    int? position1Based,
  }) async {
    final current = await read(kind);
    final queue = [...current.effectiveQueue];
    if (slotIndex < 0 || slotIndex >= queue.length) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.notFound);
    }
    final id = queue[slotIndex];
    final msgIndex = current.messages.indexWhere((m) => m.id == id);
    if (msgIndex < 0) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.notFound);
    }

    var messages = current.messages;
    int? spentBalance;
    if (rawText != null) {
      final text = PhrasePackRules.normalizeText(rawText);
      if (text == null) {
        return PhrasePackMutationResult.fail(PhrasePackMutationResult.emptyText);
      }
      final existing = messages[msgIndex];
      if (existing.text != text) {
        final points = _points;
        if (points == null) {
          return PhrasePackMutationResult.fail(
            PhrasePackMutationResult.insufficientPoints,
          );
        }
        final spent = await points.trySpend(PhrasePackRules.pointCost);
        if (spent == null) {
          return PhrasePackMutationResult.fail(
            PhrasePackMutationResult.insufficientPoints,
            balance: await points.readBalance(),
          );
        }
        spentBalance = spent;
        final now = DateTime.now().millisecondsSinceEpoch;
        messages = [...messages];
        messages[msgIndex] = existing.copyWith(text: text, updatedAtMs: now);
      }
    }

    var nextQueue = queue;
    if (position1Based != null) {
      nextQueue = PhrasePackQueue.moveSlot(
        queue: queue,
        fromIndex: slotIndex,
        position1Based: position1Based,
      );
    }

    final next = current.copyWith(messages: messages, queueIds: nextQueue);
    await write(kind, next);
    return PhrasePackMutationResult.success(
      data: next,
      balance: spentBalance,
    );
  }

  Future<PhrasePackMutationResult> tryUpdateMessage(
    PhrasePackKind kind, {
    required String id,
    required String rawText,
  }) async {
    final text = PhrasePackRules.normalizeText(rawText);
    if (text == null) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.emptyText);
    }
    final current = await read(kind);
    final index = current.messages.indexWhere((m) => m.id == id);
    if (index < 0) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.notFound);
    }
    final existing = current.messages[index];
    if (existing.text == text) {
      return PhrasePackMutationResult.success(data: current);
    }

    final points = _points;
    if (points == null) {
      return PhrasePackMutationResult.fail(
        PhrasePackMutationResult.insufficientPoints,
      );
    }
    final spent = await points.trySpend(PhrasePackRules.pointCost);
    if (spent == null) {
      return PhrasePackMutationResult.fail(
        PhrasePackMutationResult.insufficientPoints,
        balance: await points.readBalance(),
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final messages = [...current.messages];
    messages[index] = existing.copyWith(text: text, updatedAtMs: now);
    final next = current.copyWith(messages: messages);
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next, balance: spent);
  }

  Future<PhrasePackMutationResult> tryRemoveQueueSlot(
    PhrasePackKind kind,
    int index,
  ) async {
    final current = await read(kind);
    final queue = [...current.effectiveQueue];
    if (index < 0 || index >= queue.length) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.notFound);
    }
    final removedId = queue.removeAt(index);
    final stillReferenced = queue.contains(removedId);
    var messages = current.messages;
    if (!stillReferenced) {
      if (messages.length <= 1) {
        return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
      }
      messages = messages.where((m) => m.id != removedId).toList();
    }
    if (queue.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final next = current.copyWith(
      messages: messages,
      queueIds: queue,
      enabled: current.enabled && messages.isNotEmpty,
    );
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next);
  }

  Future<PhrasePackMutationResult> tryDeleteMessage(
    PhrasePackKind kind,
    String id,
  ) async {
    final current = await read(kind);
    if (!current.messages.any((m) => m.id == id)) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.notFound);
    }
    if (current.messages.length <= 1) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final messages = current.messages.where((m) => m.id != id).toList();
    final queue = current.effectiveQueue.where((entry) => entry != id).toList();
    if (queue.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final next = current.copyWith(
      messages: messages,
      queueIds: queue,
      enabled: current.enabled && messages.isNotEmpty,
    );
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next);
  }

  /// Replaces the active queue with [orderedIds] (must be known + non-empty).
  Future<PhrasePackMutationResult> tryReplaceQueue(
    PhrasePackKind kind,
    List<String> orderedIds,
  ) async {
    if (orderedIds.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final current = await read(kind);
    final known = {for (final m in current.messages) m.id};
    final filtered = orderedIds.where(known.contains).toList();
    if (filtered.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final next = current.copyWith(queueIds: filtered);
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next);
  }

  /// Builds a queue from picked library ids + 1-based positions.
  Future<PhrasePackMutationResult> tryBuildQueueFromPicks(
    PhrasePackKind kind,
    List<({String id, int position1Based})> picks,
  ) async {
    if (picks.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final current = await read(kind);
    final known = {for (final m in current.messages) m.id};
    final sorted = [...picks]..sort(
        (a, b) => a.position1Based.compareTo(b.position1Based),
      );
    var queue = <String>[];
    for (final pick in sorted) {
      if (!known.contains(pick.id)) continue;
      queue = PhrasePackQueue.insertMessage(
        queue: queue,
        id: pick.id,
        position1Based: pick.position1Based,
      );
    }
    if (queue.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final next = current.copyWith(queueIds: queue);
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next);
  }

  Future<PhrasePackMutationResult> trySavePreset(
    PhrasePackKind kind,
    String rawName, {
    List<String>? queueOverride,
  }) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.emptyName);
    }
    final current = await read(kind);
    final queue = queueOverride ?? current.effectiveQueue;
    if (queue.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final known = {for (final m in current.messages) m.id};
    final filtered = queue.where(known.contains).toList();
    if (filtered.isEmpty) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.minOne);
    }
    final preset = PhrasePreset(
      id: PhrasePackRules.newPresetId(),
      name: name,
      queueIds: filtered,
    );
    final next = current.copyWith(presets: [...current.presets, preset]);
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next);
  }

  Future<PhrasePackMutationResult> tryApplyPreset(
    PhrasePackKind kind,
    String presetId,
  ) async {
    final current = await read(kind);
    PhrasePreset? match;
    for (final p in current.presets) {
      if (p.id == presetId) {
        match = p;
        break;
      }
    }
    if (match == null) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.notFound);
    }
    return tryReplaceQueue(kind, match.queueIds);
  }

  Future<PhrasePackMutationResult> tryDeletePreset(
    PhrasePackKind kind,
    String presetId,
  ) async {
    final current = await read(kind);
    if (!current.presets.any((p) => p.id == presetId)) {
      return PhrasePackMutationResult.fail(PhrasePackMutationResult.notFound);
    }
    final next = current.copyWith(
      presets: current.presets.where((p) => p.id != presetId).toList(),
    );
    await write(kind, next);
    return PhrasePackMutationResult.success(data: next);
  }

  Future<void> writeMode(PhrasePackKind kind, PhrasePlaybackMode mode) async {
    final current = await read(kind);
    await write(kind, current.copyWith(mode: mode));
  }

  Future<void> reorderQueue(
    PhrasePackKind kind,
    int oldIndex,
    int newIndex,
  ) async {
    final current = await read(kind);
    final queue = [...current.effectiveQueue];
    if (oldIndex < 0 || oldIndex >= queue.length) return;
    if (newIndex < 0 || newIndex >= queue.length) return;
    // Indices match Flutter ReorderableListView.onReorderItem (already
    // corrected for the removed item).
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    await write(kind, current.copyWith(queueIds: queue));
  }
}

/// Back-compat name; prefer [PhrasePackRepository] with an explicit kind.
typedef CustomAffirmationPackRepository = PhrasePackRepository;
