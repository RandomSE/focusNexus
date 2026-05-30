import 'dart:convert';

import 'decor_item.dart';
import 'garden_persisted_payload.dart';
import 'garden_state.dart';
import 'visual_theme_id.dart';

/// Persists layout and flags; [GardenState.pointsBalance] comes from the wallet.
class GardenPersistence {
  static GardenState decodeZenGarden(String? json, int pointsFromWallet) {
    if (json == null || json.isEmpty) {
      return GardenState(pointsBalance: pointsFromWallet);
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final normalized = Map<String, dynamic>.from(map);
      if (normalized['decorStash'] == null && normalized['stash'] != null) {
        normalized['decorStash'] = normalized['stash'];
      }
      if (!normalized.containsKey('legacyFreeFirst') &&
          normalized.containsKey('freeFirst')) {
        normalized['legacyFreeFirst'] = normalized['freeFirst'];
      }
      final payload = _applyLegacyMigration(
        GardenPersistedPayload.fromJson(normalized),
      );
      return GardenState(
        pointsBalance: pointsFromWallet,
        items: payload.items,
        decor: payload.decor,
        decorStash: const {},
        decorInventory: _mergeInventory(payload.decorInventory, payload.decorStash),
        plantInventory: payload.plantInventory,
        freeFirstGrowthEverConsumed: payload.freeFirstGrowthEverConsumed,
        freeFirstGrowthEligibleItemId: payload.freeFirstGrowthEligibleItemId,
      );
    } catch (_) {
      return GardenState(pointsBalance: pointsFromWallet);
    }
  }

  static String encodeZenGarden(GardenState state) {
    final payload = GardenPersistedPayload(
      items: state.items,
      decor: state.decor,
      decorInventory: state.decorInventory,
      plantInventory: state.plantInventory,
      freeFirstGrowthEverConsumed: state.freeFirstGrowthEverConsumed,
      freeFirstGrowthEligibleItemId: state.freeFirstGrowthEligibleItemId,
    );
    return jsonEncode(payload.toJson());
  }

  static GardenPersistedPayload _applyLegacyMigration(
    GardenPersistedPayload payload,
  ) {
    var everConsumed = payload.freeFirstGrowthEverConsumed;
    if (payload.legacyFreeFirst == false) {
      everConsumed = true;
    }

    var eligible = payload.freeFirstGrowthEligibleItemId;
    if (eligible == null &&
        !everConsumed &&
        payload.items.length == 1 &&
        payload.items.single.stageIndex == 0 &&
        payload.legacyFreeFirst != false) {
      eligible = payload.items.single.id;
    }

    return payload.copyWith(
      freeFirstGrowthEverConsumed: everConsumed,
      freeFirstGrowthEligibleItemId: eligible,
    );
  }

  static Map<String, int> _sanitizeStash(Map<String, int> raw) {
    return {
      for (final entry in raw.entries)
        if (entry.value > 0) entry.key: entry.value,
    };
  }

  static List<DecorItem> _mergeInventory(
    List<DecorItem> inventory,
    Map<String, int> legacyStash,
  ) {
    if (inventory.isNotEmpty) return inventory;
    final stash = _sanitizeStash(legacyStash);
    if (stash.isEmpty) return inventory;
    final migrated = <DecorItem>[];
    var seed = 0;
    for (final entry in stash.entries) {
      for (var i = 0; i < entry.value; i++) {
        migrated.add(
          DecorItem(
            id: 'inv_legacy_${entry.key}_$seed',
            themeId: VisualThemeId.zenGarden,
            kind: entry.key,
          ),
        );
        seed++;
      }
    }
    return migrated;
  }
}
