import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';
import 'package:focusNexus/providers/key_value_storage_provider.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Persisted consistency heatmap palette (default Cool Teal Depth).
class ConsistencyPaletteNotifier extends Notifier<ConsistencyPaletteId> {
  @override
  ConsistencyPaletteId build() {
    Future.microtask(_hydrate);
    return ConsistencyPaletteId.coolTealDepth;
  }

  Future<void> _hydrate() async {
    final raw = await ref
        .read(keyValueStorageProvider)
        .read(key: StorageKeys.consistencyPalette);
    final parsed = ConsistencyPaletteId.parse(raw);
    if (parsed != state) {
      state = parsed;
    }
  }

  Future<void> select(ConsistencyPaletteId id) async {
    if (state == id) return;
    state = id;
    await ref.read(keyValueStorageProvider).write(
          key: StorageKeys.consistencyPalette,
          value: id.storageValue,
        );
  }
}

final consistencyPaletteProvider =
    NotifierProvider<ConsistencyPaletteNotifier, ConsistencyPaletteId>(
  ConsistencyPaletteNotifier.new,
);
