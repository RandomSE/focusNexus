import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_definition.dart';
import 'package:focusNexus/mini_games/mini_game_progress.dart';
import 'package:focusNexus/mini_games/mini_game_progress_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late MiniGameProgressRepository repo;

  const paid = MiniGameDefinition(
    id: 'paid',
    title: 'Paid',
    description: 'd',
    unlockCost: 50,
    playCost: 5,
    endlessCost: 2,
    defaultDurationSeconds: 60,
    baseDifficulty: 1,
    implemented: false,
  );

  const free = MiniGameDefinition(
    id: 'free',
    title: 'Free',
    description: 'd',
    unlockCost: 0,
    playCost: 5,
    endlessCost: 2,
    defaultDurationSeconds: 60,
    baseDifficulty: 1,
    implemented: false,
  );

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repo = MiniGameProgressRepository(storage);
  });

  test('progress defaults to empty', () async {
    final progress = await repo.progressFor('missing');
    expect(progress.unlocked, isFalse);
    expect(progress.highScore, 0);
    expect(progress.lastPlayedAt, isNull);
  });

  test('paid game locked until unlock', () async {
    expect(await repo.isUnlocked(paid), isFalse);
    await repo.unlock(paid.id);
    expect(await repo.isUnlocked(paid), isTrue);
    final raw = await storage.read(key: StorageKeys.miniGamesProgress);
    expect(raw, isNotNull);
  });

  test('first unlock grants one free Duration and Endless entry', () async {
    final unlocked = await repo.unlock(paid.id);
    expect(unlocked.unlocked, isTrue);
    expect(unlocked.freeDurationEntries, 1);
    expect(unlocked.freeEndlessEntries, 1);

    final again = await repo.unlock(paid.id);
    expect(again.freeDurationEntries, 1);
    expect(again.freeEndlessEntries, 1);
  });

  test('ensureWelcomeUnlock grants free entries for free catalog games', () async {
    final before = await repo.progressFor(free.id);
    expect(before.unlocked, isFalse);

    final granted = await repo.ensureWelcomeUnlock(free);
    expect(granted.unlocked, isTrue);
    expect(granted.freeDurationEntries, 1);
    expect(granted.freeEndlessEntries, 1);

    final second = await repo.ensureWelcomeUnlock(free);
    expect(second.freeDurationEntries, 1);
  });

  test('tryConsumeFreeEntry skips spend for that mode only', () async {
    await repo.unlock(paid.id);
    expect(
      await repo.tryConsumeFreeEntry(paid.id, endless: false),
      isTrue,
    );
    var progress = await repo.progressFor(paid.id);
    expect(progress.freeDurationEntries, 0);
    expect(progress.freeEndlessEntries, 1);

    expect(
      await repo.tryConsumeFreeEntry(paid.id, endless: false),
      isFalse,
    );
    expect(
      await repo.tryConsumeFreeEntry(paid.id, endless: true),
      isTrue,
    );
    progress = await repo.progressFor(paid.id);
    expect(progress.freeEndlessEntries, 0);
  });

  test('markLastPlayed drives mostRecentlyPlayedGameId', () async {
    expect(await repo.mostRecentlyPlayedGameId(), isNull);
    await repo.markLastPlayed(paid.id);
    expect(await repo.mostRecentlyPlayedGameId(), paid.id);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.markLastPlayed(free.id);
    expect(await repo.mostRecentlyPlayedGameId(), free.id);
  });

  test('recordScore updates most recently played', () async {
    await repo.recordScore(paid.id, 3, 1.0);
    expect(await repo.mostRecentlyPlayedGameId(), paid.id);
  });

  test('free unlock is always unlocked', () async {
    expect(await repo.isUnlocked(free), isTrue);
  });

  test('recordScore keeps best scaled score', () async {
    await repo.recordScore(paid.id, 10, 1.5);
    var progress = await repo.progressFor(paid.id);
    expect(progress.highScore, 10);
    expect(progress.endlessHighScore, 0);
    expect(progress.lastPlayedAt, isNotNull);

    await repo.recordScore(paid.id, 10, 1.0);
    progress = await repo.progressFor(paid.id);
    expect(progress.highScore, 10);

    await repo.recordScore(paid.id, 20, 1.0);
    progress = await repo.progressFor(paid.id);
    expect(progress.highScore, 20);
  });

  test('recordScore tracks duration and endless separately', () async {
    await repo.recordScore(paid.id, 10, 1.0, endless: false);
    await repo.recordScore(paid.id, 40, 1.0, endless: true);
    await repo.recordScore(paid.id, 12, 1.0, endless: false);
    await repo.recordScore(paid.id, 30, 1.0, endless: true);

    final progress = await repo.progressFor(paid.id);
    expect(progress.highScore, 12);
    expect(progress.endlessHighScore, 40);
    expect(progress.highScoreFor(endless: false), 12);
    expect(progress.highScoreFor(endless: true), 40);
  });

  test('round-trips JSON progress', () {
    final original = MiniGameProgress(
      unlocked: true,
      highScore: 42,
      endlessHighScore: 99,
      freeDurationEntries: 1,
      freeEndlessEntries: 2,
      lastPlayedAt: DateTime.utc(2026, 7, 22, 12),
    );
    final restored = MiniGameProgress.fromJson(original.toJson());
    expect(restored.unlocked, isTrue);
    expect(restored.highScore, 42);
    expect(restored.endlessHighScore, 99);
    expect(restored.freeDurationEntries, 1);
    expect(restored.freeEndlessEntries, 2);
    expect(restored.lastPlayedAt, original.lastPlayedAt);
  });

  test('fromJson defaults missing endlessHighScore to 0', () {
    final restored = MiniGameProgress.fromJson({
      'unlocked': true,
      'highScore': 7,
    });
    expect(restored.endlessHighScore, 0);
  });
}
