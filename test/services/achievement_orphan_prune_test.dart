import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/repositories/achievement_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/in_memory_key_value_storage.dart';

Achievement _orphanAchievement(String id, String title) => Achievement(
      id: id,
      title: title,
      reward: '100 points',
      task: 'Retired assistant create',
      isSecret: true,
    );

void main() {
  test('initialize prunes orphaned assistant achievements and counters', () async {
    final storage = InMemoryKeyValueStorage();
    final repository = AchievementRepository(storage);
    await repository.saveAll([
      _orphanAchievement('105', 'Perfectly balanced'),
      _orphanAchievement('106', 'Delegated I'),
      _orphanAchievement('111', 'Full Delegation'),
    ]);
    await storage.write(key: 'goalsCreatedViaAssistant', value: '3');
    await storage.write(key: 'assistantCreateKindsUsed', value: '7');

    final service = AchievementService(
      storage: storage,
      repository: repository,
      soundService: SoundService(InMemoryKeyValueStorage()),
    );
    await service.setInitializationPrerequisites();
    await service.initialize();

    expect(service.getById('105'), isNotNull);
    expect(service.getById('106'), isNull);
    expect(service.getById('111'), isNull);
    expect(await storage.read(key: 'goalsCreatedViaAssistant'), isNull);
    expect(await storage.read(key: 'assistantCreateKindsUsed'), isNull);

    final raw = await storage.read(key: StorageKeys.achievements);
    final decoded = jsonDecode(raw!) as List<dynamic>;
    final ids = decoded.map((e) => (e as Map)['id'] as String).toList();
    expect(ids, contains('105'));
    expect(ids, isNot(contains('106')));
    expect(ids, isNot(contains('111')));
  });
}
