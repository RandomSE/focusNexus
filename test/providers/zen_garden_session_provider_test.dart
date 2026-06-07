import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/providers/key_value_storage_provider.dart';
import 'package:focusNexus/providers/zen_garden_session_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  test('applyWalletBalance updates garden points from wallet', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '4000'},
    );
    final container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    container.read(goalNotifierWiringProvider);
    final notifier = container.read(zenGardenSessionProvider.notifier);

    expect(container.read(zenGardenSessionProvider).garden.pointsBalance, 0);

    notifier.applyWalletBalance(4000);
    expect(container.read(zenGardenSessionProvider).garden.pointsBalance, 4000);

    await notifier.syncWalletBalance();
    expect(container.read(zenGardenSessionProvider).garden.pointsBalance, 4000);
  });
}
