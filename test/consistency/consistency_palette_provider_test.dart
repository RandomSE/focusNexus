import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:focusNexus/providers/consistency_palette_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/in_memory_key_value_storage.dart';
import 'package:focusNexus/providers/key_value_storage_provider.dart';

void main() {
  test('selecting a palette persists storage value', () async {
    final storage = InMemoryKeyValueStorage();
    final container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(consistencyPaletteProvider),
      ConsistencyPaletteId.coolTealDepth,
    );

    await container
        .read(consistencyPaletteProvider.notifier)
        .select(ConsistencyPaletteId.softPurple);

    expect(
      container.read(consistencyPaletteProvider),
      ConsistencyPaletteId.softPurple,
    );
    expect(
      await storage.read(key: StorageKeys.consistencyPalette),
      ConsistencyPaletteId.softPurple.storageValue,
    );
  });

  test('hydrates from storage', () async {
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.consistencyPalette:
            ConsistencyPaletteId.goldenHour.storageValue,
      },
    );
    final container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    container.read(consistencyPaletteProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(consistencyPaletteProvider),
      ConsistencyPaletteId.goldenHour,
    );
  });
}
