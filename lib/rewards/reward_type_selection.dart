import 'dart:convert';

import 'package:focusNexus/app/app_route.dart';

/// Canonical multi-select helpers for reward type storage strings.
abstract final class RewardTypeSelection {
  static const orderedStorageValues = <String>[
    'Mini-games',
    'Progressive visuals',
    'Customization',
  ];

  /// Keeps only known values in stable [orderedStorageValues] order.
  static List<String> orderKnown(Iterable<String> raw) {
    final set = raw.toSet();
    return orderedStorageValues.where(set.contains).toList();
  }

  /// Load-time normalize: drop unknowns; if empty, use Mini-games.
  static List<String> normalizeForLoad(Iterable<String> raw) {
    final ordered = orderKnown(raw);
    if (ordered.isEmpty) return [RewardKind.miniGames.storageValue];
    return ordered;
  }

  static String encode(Iterable<String> raw) =>
      jsonEncode(normalizeForLoad(raw));

  /// Decodes [rewardTypesJson]; unknown or empty input becomes Mini-games.
  static List<String> decode(String? rewardTypesJson) {
    if (rewardTypesJson != null && rewardTypesJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rewardTypesJson);
        if (decoded is List) {
          return normalizeForLoad(decoded.map((e) => e.toString()));
        }
      } catch (_) {
        // Fall through to default.
      }
    }
    return [RewardKind.miniGames.storageValue];
  }

  static bool contains(Iterable<String> raw, String storageValue) =>
      orderKnown(raw).contains(storageValue);

  static AppRoute routeForStorageValue(String storageValue) {
    return switch (RewardKind.parse(storageValue)) {
      RewardKind.miniGames => AppRoute.miniGames,
      RewardKind.progressiveVisuals => AppRoute.progressiveVisual,
      RewardKind.customization => AppRoute.customization,
    };
  }
}
