import 'package:focusNexus/progressive_visuals/cherry_blossom_unlock.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/repositories/progressive_visuals_points_repository.dart';
import 'package:focusNexus/services/storage/key_value_storage.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

/// Zen garden save blob plus shared wallet and progressive-visuals wallets.
class GardenRepository {
  GardenRepository(
    this._storage, {
    required PointsRepository points,
    ProgressiveVisualsPointsRepository? progressiveVisualsPoints,
  })  : _points = points,
        _pvPoints =
            progressiveVisualsPoints ?? ProgressiveVisualsPointsRepository(_storage);

  final KeyValueStorage _storage;
  final PointsRepository _points;
  final ProgressiveVisualsPointsRepository _pvPoints;

  Future<GardenState> load() async {
    final wallet = await _points.ensureInitialized();
    final pv = await _pvPoints.ensureInitialized();
    final raw = await _storage.read(key: StorageKeys.zenGardenSave);
    var garden = GardenPersistence.decodeZenGarden(
      raw,
      wallet,
      progressiveVisualsPointsFromWallet: pv,
    );
    final walletLife = await _points.readLifetimeSpent();
    final zenLife = garden.lifetimeZenPointsSpent;
    final merged = walletLife > zenLife ? walletLife : zenLife;
    if (merged != zenLife) {
      garden = evaluateCherryBlossomUnlock(
        garden.copyWith(lifetimeZenPointsSpent: merged),
      );
    }
    if (zenLife > walletLife) {
      await _points.ensureLifetimeSpentAtLeast(zenLife);
    }
    return garden;
  }

  Future<void> save(GardenState garden) async {
    await _points.writeBalance(garden.pointsBalance);
    await _pvPoints.writeBalance(garden.progressiveVisualsPointsBalance);
    await _points.ensureLifetimeSpentAtLeast(garden.lifetimeZenPointsSpent);
    await _storage.write(
      key: StorageKeys.zenGardenSave,
      value: GardenPersistence.encodeZenGarden(garden),
    );
  }
}
