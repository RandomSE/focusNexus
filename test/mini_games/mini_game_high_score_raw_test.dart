import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_progress.dart';
import 'package:focusNexus/mini_games/mini_game_progress_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late MiniGameProgressRepository repo;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repo = MiniGameProgressRepository(storage);
  });

  test('recordScore stores raw catch count, not difficulty-scaled', () async {
    await repo.recordScore('firefly_jar', 503, 3.6, endless: true);
    final progress = await repo.progressFor('firefly_jar');
    expect(progress.endlessHighScore, 503);
    expect(progress.highScore, 0);
  });

  test('recordScore keeps best raw score per mode', () async {
    await repo.recordScore('g', 40, 9.0, endless: true);
    await repo.recordScore('g', 30, 1.0, endless: true);
    await repo.recordScore('g', 12, 5.0, endless: false);
    final progress = await repo.progressFor('g');
    expect(progress.endlessHighScore, 40);
    expect(progress.highScore, 12);
  });

  test('loadAll migrates schema v1 scaled scores to raw schema v2', () async {
    await storage.write(
      key: StorageKeys.miniGamesProgress,
      value:
          '{"firefly_jar":{"unlocked":true,"highScore":15,"endlessHighScore":1804}}',
    );
    final all = await repo.loadAll();
    expect(all['firefly_jar']!.endlessHighScore, 0);
    expect(all['firefly_jar']!.highScore, 0);
    expect(all['firefly_jar']!.schemaVersion, MiniGameProgress.currentSchema);
  });
}
