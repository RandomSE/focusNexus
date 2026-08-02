import 'dart:convert';

import 'package:focusNexus/mini_games/mini_game_definition.dart';
import 'package:focusNexus/mini_games/mini_game_progress.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Persists unlock / high-score / free-entry state per mini-game id.
class MiniGameProgressRepository {
  MiniGameProgressRepository(this._storage);

  final KeyValueStorage _storage;

  Future<Map<String, MiniGameProgress>> loadAll() async {
    final raw = await _storage.read(key: StorageKeys.miniGamesProgress);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, MiniGameProgress>{};
      var migrated = false;
      for (final entry in decoded.entries) {
        final value = entry.value;
        final Map<String, dynamic> map;
        if (value is Map<String, dynamic>) {
          map = value;
        } else if (value is Map) {
          map = Map<String, dynamic>.from(value);
        } else {
          continue;
        }
        final priorVersion = (map['schemaVersion'] as num?)?.toInt() ?? 1;
        final progress = MiniGameProgress.fromJson(map);
        if (priorVersion < MiniGameProgress.currentSchema) {
          migrated = true;
        }
        out[entry.key.toString()] = progress;
      }
      if (migrated) {
        await _writeAll(out);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<MiniGameProgress> progressFor(String gameId) async {
    final all = await loadAll();
    return all[gameId] ?? MiniGameProgress.empty;
  }

  /// Free unlock ([MiniGameDefinition.unlockCost] `<= 0`) or persisted unlock.
  Future<bool> isUnlocked(MiniGameDefinition definition) async {
    if (definition.isFreeUnlock) return true;
    final progress = await progressFor(definition.id);
    return progress.unlocked;
  }

  Future<void> _writeAll(Map<String, MiniGameProgress> all) async {
    final encoded = jsonEncode({
      for (final e in all.entries) e.key: e.value.toJson(),
    });
    await _storage.write(key: StorageKeys.miniGamesProgress, value: encoded);
  }

  /// Marks [gameId] unlocked (caller spends points separately when needed).
  ///
  /// On the first unlock transition, grants one free Duration and one free
  /// Endless entry ([MiniGameProgress.welcomeFreeEntriesPerMode] each).
  Future<MiniGameProgress> unlock(String gameId) async {
    final all = await loadAll();
    final current = all[gameId] ?? MiniGameProgress.empty;
    if (current.unlocked) {
      return current;
    }
    final grant = MiniGameProgress.welcomeFreeEntriesPerMode;
    final next = current.copyWith(
      unlocked: true,
      freeDurationEntries: current.freeDurationEntries + grant,
      freeEndlessEntries: current.freeEndlessEntries + grant,
    );
    all[gameId] = next;
    await _writeAll(all);
    return next;
  }

  /// For free-unlock catalog games, persist unlock + welcome free entries once.
  Future<MiniGameProgress> ensureWelcomeUnlock(
    MiniGameDefinition definition,
  ) async {
    if (!definition.isFreeUnlock) {
      return progressFor(definition.id);
    }
    final current = await progressFor(definition.id);
    if (current.unlocked) return current;
    return unlock(definition.id);
  }

  /// Updates [lastPlayedAt] for [gameId] (Start or finish).
  Future<MiniGameProgress> markLastPlayed(String gameId) async {
    final all = await loadAll();
    final current = all[gameId] ?? MiniGameProgress.empty;
    final next = current.copyWith(lastPlayedAt: DateTime.now());
    all[gameId] = next;
    await _writeAll(all);
    return next;
  }

  /// Game id with the newest [MiniGameProgress.lastPlayedAt], or null if none.
  Future<String?> mostRecentlyPlayedGameId() async {
    final all = await loadAll();
    String? bestId;
    DateTime? bestAt;
    for (final entry in all.entries) {
      final at = entry.value.lastPlayedAt;
      if (at == null) continue;
      if (bestAt == null || at.isAfter(bestAt)) {
        bestAt = at;
        bestId = entry.key;
      }
    }
    return bestId;
  }

  /// Consumes one free entry for [endless] mode when available.
  /// Returns true when a free entry was used (caller should skip [trySpend]).
  Future<bool> tryConsumeFreeEntry(
    String gameId, {
    required bool endless,
  }) async {
    final all = await loadAll();
    final current = all[gameId] ?? MiniGameProgress.empty;
    if (endless) {
      if (current.freeEndlessEntries <= 0) return false;
      all[gameId] = current.copyWith(
        freeEndlessEntries: current.freeEndlessEntries - 1,
      );
    } else {
      if (current.freeDurationEntries <= 0) return false;
      all[gameId] = current.copyWith(
        freeDurationEntries: current.freeDurationEntries - 1,
      );
    }
    await _writeAll(all);
    return true;
  }

  /// Records the raw in-round score after a game ends; keeps the best per mode.
  ///
  /// [difficulty] is accepted for call-site compatibility and ignored for
  /// leaderboard storage (high scores are raw catch/height counts).
  Future<MiniGameProgress> recordScore(
    String gameId,
    num rawScore,
    num difficulty, {
    bool endless = false,
  }) async {
    final score = rawScore.round();
    final all = await loadAll();
    final current = all[gameId] ?? MiniGameProgress.empty;
    final MiniGameProgress next;
    if (endless) {
      final nextHigh =
          score > current.endlessHighScore ? score : current.endlessHighScore;
      next = current.copyWith(
        endlessHighScore: nextHigh,
        lastPlayedAt: DateTime.now(),
        schemaVersion: MiniGameProgress.currentSchema,
      );
    } else {
      final nextHigh = score > current.highScore ? score : current.highScore;
      next = current.copyWith(
        highScore: nextHigh,
        lastPlayedAt: DateTime.now(),
        schemaVersion: MiniGameProgress.currentSchema,
      );
    }
    all[gameId] = next;
    await _writeAll(all);
    return next;
  }
}
