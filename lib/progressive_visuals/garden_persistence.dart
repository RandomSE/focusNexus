import 'dart:convert';

import 'decor_item.dart';
import 'garden_item.dart';
import 'garden_state.dart';
import 'mutation_kind.dart';
import 'visual_theme_id.dart';

/// Persists layout and flags; [pointsBalance] always comes from the shared wallet.
class GardenPersistence {
  static GardenState decodeZenGarden(String? json, int pointsFromWallet) {
    if (json == null || json.isEmpty) {
      return GardenState(pointsBalance: pointsFromWallet, items: const []);
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final rawItems = map['items'] as List<dynamic>? ?? const [];
      final items = <GardenItem>[
        for (final e in rawItems)
          if (e is Map<String, dynamic>) _itemFromJson(e),
      ];
      final rawDecor = map['decor'] as List<dynamic>? ?? const [];
      final decor = <DecorItem>[
        for (final e in rawDecor)
          if (e is Map<String, dynamic>) _decorFromJson(e),
      ];
      final stashRaw = map['stash'] as Map<String, dynamic>?;
      final stash = <String, int>{};
      if (stashRaw != null) {
        for (final e in stashRaw.entries) {
          final n = (e.value as num?)?.toInt();
          if (n != null && n > 0) {
            stash[e.key] = n;
          }
        }
      }

      final bool? legacyFreeFirst = map['freeFirst'] as bool?;
      final bool everConsumed = map['freeFirstGrowthEverConsumed'] as bool? ??
          (legacyFreeFirst == false);
      String? eligible = map['freeFirstGrowthEligibleItemId'] as String?;
      if (eligible == null &&
          !everConsumed &&
          items.length == 1 &&
          items.single.stageIndex == 0 &&
          legacyFreeFirst != false) {
        eligible = items.single.id;
      }

      return GardenState(
        pointsBalance: pointsFromWallet,
        items: items,
        decor: decor,
        decorStash: stash,
        freeFirstGrowthEverConsumed: everConsumed,
        freeFirstGrowthEligibleItemId: eligible,
      );
    } catch (_) {
      return GardenState(pointsBalance: pointsFromWallet, items: const []);
    }
  }

  static String encodeZenGarden(GardenState state) {
    return jsonEncode({
      'items': state.items.map(_itemToJson).toList(),
      'decor': state.decor.map(_decorToJson).toList(),
      'stash': state.decorStash,
      'freeFirstGrowthEverConsumed': state.freeFirstGrowthEverConsumed,
      'freeFirstGrowthEligibleItemId': state.freeFirstGrowthEligibleItemId,
    });
  }

  static Map<String, dynamic> _decorToJson(DecorItem d) {
    return {
      'id': d.id,
      'themeId': d.themeId.name,
      'kind': d.kind,
      'positionX': d.positionX,
      'positionY': d.positionY,
      'stageIndex': d.stageIndex,
      'nextAdvanceAllowedAt': d.nextAdvanceAllowedAt?.toIso8601String(),
      'pendingSkipWaitCost': d.pendingSkipWaitCost,
      'mutation': d.mutation?.name,
      'awaitingRegrowthForRemutation': d.awaitingRegrowthForRemutation,
      'mutationRolledThisCycle': d.mutationRolledThisCycle,
    };
  }

  static DecorItem _decorFromJson(Map<String, dynamic> m) {
    final themeName = m['themeId'] as String? ?? VisualThemeId.zenGarden.name;
    final themeId = VisualThemeId.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => VisualThemeId.zenGarden,
    );
    final mutationName = m['mutation'] as String?;
    final mutation = mutationName == null
        ? null
        : MutationKind.values.firstWhere(
            (k) => k.name == mutationName,
            orElse: () => MutationKind.invertedColors,
          );
    final at = m['nextAdvanceAllowedAt'] as String?;
    return DecorItem(
      id: m['id'] as String,
      themeId: themeId,
      kind: m['kind'] as String,
      positionX: (m['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (m['positionY'] as num?)?.toDouble() ?? 0.5,
      stageIndex: (m['stageIndex'] as num?)?.toInt() ?? 0,
      nextAdvanceAllowedAt: at == null ? null : DateTime.tryParse(at),
      pendingSkipWaitCost: (m['pendingSkipWaitCost'] as num?)?.toInt(),
      mutation: mutation,
      awaitingRegrowthForRemutation:
          m['awaitingRegrowthForRemutation'] as bool? ?? false,
      mutationRolledThisCycle: m['mutationRolledThisCycle'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _itemToJson(GardenItem i) {
    return {
      'id': i.id,
      'themeId': i.themeId.name,
      'stageIndex': i.stageIndex,
      'positionX': i.positionX,
      'positionY': i.positionY,
      'nextAdvanceAllowedAt': i.nextAdvanceAllowedAt?.toIso8601String(),
      'pendingSkipWaitCost': i.pendingSkipWaitCost,
      'mutation': i.mutation?.name,
      'awaitingRegrowthForRemutation': i.awaitingRegrowthForRemutation,
      'mutationRolledThisCycle': i.mutationRolledThisCycle,
      'regrowthDiscountActive': i.regrowthDiscountActive,
    };
  }

  static GardenItem _itemFromJson(Map<String, dynamic> m) {
    final themeName = m['themeId'] as String? ?? VisualThemeId.zenGarden.name;
    final themeId = VisualThemeId.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => VisualThemeId.zenGarden,
    );
    final mutationName = m['mutation'] as String?;
    final mutation = mutationName == null
        ? null
        : MutationKind.values.firstWhere(
            (k) => k.name == mutationName,
            orElse: () => MutationKind.invertedColors,
          );
    final at = m['nextAdvanceAllowedAt'] as String?;
    return GardenItem(
      id: m['id'] as String,
      themeId: themeId,
      stageIndex: (m['stageIndex'] as num?)?.toInt() ?? 0,
      positionX: (m['positionX'] as num?)?.toDouble() ?? 0.5,
      positionY: (m['positionY'] as num?)?.toDouble() ?? 0.5,
      nextAdvanceAllowedAt: at == null ? null : DateTime.tryParse(at),
      pendingSkipWaitCost: (m['pendingSkipWaitCost'] as num?)?.toInt(),
      mutation: mutation,
      awaitingRegrowthForRemutation:
          m['awaitingRegrowthForRemutation'] as bool? ?? false,
      mutationRolledThisCycle: m['mutationRolledThisCycle'] as bool? ?? false,
      regrowthDiscountActive: m['regrowthDiscountActive'] as bool? ?? false,
    );
  }
}
