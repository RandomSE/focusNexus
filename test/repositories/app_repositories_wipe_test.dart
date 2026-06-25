import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  test('wipeAllUserData clears storage and resets points to default', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '9999'},
    );
    final repos = AppRepositories(storage);
    await repos.points.readBalance();
    expect(await repos.points.readBalance(), 9999);

    await repos.wipeAllUserData();

    expect(storage.snapshot[StorageKeys.points], '50');
    expect(await repos.points.readBalance(), PointsRepository.defaultBalance);
  });
}
