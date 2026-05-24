import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Zen garden save blob plus shared wallet balance.
class GardenRepository {
  GardenRepository(this._storage, {required PointsRepository points})
      : _points = points;

  final KeyValueStorage _storage;
  final PointsRepository _points;

  Future<GardenState> load() async {
    final wallet = await _points.ensureInitialized();
    final raw = await _storage.read(key: StorageKeys.zenGardenSave);
    return GardenPersistence.decodeZenGarden(raw, wallet);
  }

  Future<void> save(GardenState garden) async {
    await _points.writeBalance(garden.pointsBalance);
    await _storage.write(
      key: StorageKeys.zenGardenSave,
      value: GardenPersistence.encodeZenGarden(garden),
    );
  }
}
