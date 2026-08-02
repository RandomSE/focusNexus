import 'package:focusNexus/services/achievement_service.dart';

import 'in_memory_key_value_storage.dart';

/// Catalog size after a clean [AchievementService.initialize] seed.
///
/// Prefer this over hardcoding N so mini-game ensure paths can grow without
/// updating magic literals in open-streak (and similar) tests.
Future<int> freshAchievementCatalogSize() async {
  final probe = AchievementService(storage: InMemoryKeyValueStorage());
  await probe.initialize();
  return probe.all.length;
}
