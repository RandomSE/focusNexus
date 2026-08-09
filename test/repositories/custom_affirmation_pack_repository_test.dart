import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/motivators/adhd_motivator_pack.dart';
import 'package:focusNexus/repositories/custom_affirmation_pack_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/custom_affirmation_pack.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/affirmation_selector.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late PointsRepository points;
  late PhrasePackRepository repo;

  const motivator = PhrasePackKind.dashboardMotivator;
  const affirmation = PhrasePackKind.dailyAffirmation;

  setUp(() {
    storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '500'},
    );
    points = PointsRepository(storage);
    repo = PhrasePackRepository(storage, points: points);
  });

  test('defaults to disabled empty pack per kind', () async {
    final pack = await repo.read(motivator);
    expect(pack.enabled, isFalse);
    expect(pack.messages, isEmpty);
    expect(pack.queueIds, isEmpty);
    expect(pack.mode, PhrasePlaybackMode.sequence);
  });

  test('trySetEnabled seeds kind-specific baselines without spend', () async {
    final motivatorResult = await repo.trySetEnabled(motivator, true);
    expect(motivatorResult.ok, isTrue);
    expect(motivatorResult.data!.enabled, isTrue);
    expect(
      motivatorResult.data!.messages.length,
      AdhdMotivatorPack.lines.length,
    );
    expect(
      motivatorResult.data!.messages.every((m) => m.id.startsWith('bm_')),
      isTrue,
    );

    final affirmationResult = await repo.trySetEnabled(affirmation, true);
    expect(affirmationResult.ok, isTrue);
    expect(
      affirmationResult.data!.messages.length,
      AffirmationSelector.cores.length,
    );
    expect(
      affirmationResult.data!.messages.every((m) => m.id.startsWith('ba_')),
      isTrue,
    );
    expect(await points.readBalance(), 500);
  });

  test('disable keeps saved edits; playback disabled', () async {
    await repo.trySetEnabled(motivator, true);
    final id = (await repo.read(motivator)).messages.first.id;
    await repo.tryUpdateMessage(motivator, id: id, rawText: 'Edited built-in');
    expect(await points.readBalance(), 400);

    final off = await repo.trySetEnabled(motivator, false);
    expect(off.ok, isTrue);
    expect(off.data!.enabled, isFalse);
    expect(off.data!.messages.first.text, 'Edited built-in');
  });

  test('tryAddMessage spends 100 and inserts at position', () async {
    await repo.ensureSeeded(motivator);
    final before = await repo.read(motivator);
    final firstId = before.queueIds.first;
    final result = await repo.tryAddMessage(
      motivator,
      '  My line  ',
      position1Based: 1,
    );
    expect(result.ok, isTrue);
    expect(result.balance, 400);
    expect(result.data!.messages.length, before.messages.length + 1);
    expect(result.data!.messages.last.text, 'My line');
    expect(result.data!.messages.last.origin, PhraseOrigin.custom);
    expect(result.data!.queueIds.first, result.data!.messages.last.id);
    expect(result.data!.queueIds[1], firstId);
  });

  test('tryAddMessage fails without spending when insufficient points',
      () async {
    storage = InMemoryKeyValueStorage(initial: {StorageKeys.points: '50'});
    points = PointsRepository(storage);
    repo = PhrasePackRepository(storage, points: points);

    final result = await repo.tryAddMessage(affirmation, 'Nope');
    expect(result.ok, isFalse);
    expect(result.error, PhrasePackMutationResult.insufficientPoints);
    expect(await points.readBalance(), 50);
  });

  test('tryUpdateMessage spends when editing a baseline copy', () async {
    await repo.ensureSeeded(affirmation);
    final id = (await repo.read(affirmation)).messages.first.id;
    final changed = await repo.tryUpdateMessage(
      affirmation,
      id: id,
      rawText: 'Changed',
    );
    expect(changed.ok, isTrue);
    expect(await points.readBalance(), 400);
    expect((await repo.read(affirmation)).messages.first.text, 'Changed');
  });

  test('cannot delete last message; delete is free', () async {
    await repo.tryAddMessage(motivator, 'Only');
    final id = (await repo.read(motivator)).messages.single.id;
    final balanceBefore = await points.readBalance();

    final blocked = await repo.tryDeleteMessage(motivator, id);
    expect(blocked.ok, isFalse);
    expect(blocked.error, PhrasePackMutationResult.minOne);
    expect(await points.readBalance(), balanceBefore);

    await repo.tryAddMessage(motivator, 'Second');
    final afterAdd = await points.readBalance();
    final deleted = await repo.tryDeleteMessage(motivator, id);
    expect(deleted.ok, isTrue);
    expect(await points.readBalance(), afterAdd);
    expect((await repo.read(motivator)).messages, hasLength(1));
  });

  test('tryReplaceQueue and tryBuildQueueFromPicks update queue', () async {
    await repo.tryAddMessage(motivator, 'A');
    await repo.tryAddMessage(motivator, 'B');
    final ids = (await repo.read(motivator)).messages.map((m) => m.id).toList();
    final balance = await points.readBalance();

    final replaced = await repo.tryReplaceQueue(motivator, [ids[1], ids[0], ids[1]]);
    expect(replaced.ok, isTrue);
    expect((await repo.read(motivator)).queueIds, [ids[1], ids[0], ids[1]]);
    expect(await points.readBalance(), balance);

    final built = await repo.tryBuildQueueFromPicks(motivator, [
      (id: ids[0], position1Based: 1),
      (id: ids[1], position1Based: 2),
      (id: ids[0], position1Based: 3),
    ]);
    expect(built.ok, isTrue);
    expect((await repo.read(motivator)).queueIds, [ids[0], ids[1], ids[0]]);
    expect(await points.readBalance(), balance);
  });

  test('presets save, apply, and delete', () async {
    await repo.tryAddMessage(affirmation, 'A');
    await repo.tryAddMessage(affirmation, 'B');
    final ids =
        (await repo.read(affirmation)).messages.map((m) => m.id).toList();
    await repo.tryReplaceQueue(affirmation, [ids[0], ids[1]]);

    final saved = await repo.trySavePreset(affirmation, ' Morning ');
    expect(saved.ok, isTrue);
    expect(saved.data!.presets, hasLength(1));
    expect(saved.data!.presets.single.name, 'Morning');
    final presetId = saved.data!.presets.single.id;

    await repo.tryReplaceQueue(affirmation, [ids[1]]);
    final applied = await repo.tryApplyPreset(affirmation, presetId);
    expect(applied.ok, isTrue);
    expect((await repo.read(affirmation)).queueIds, [ids[0], ids[1]]);

    final deleted = await repo.tryDeletePreset(affirmation, presetId);
    expect(deleted.ok, isTrue);
    expect((await repo.read(affirmation)).presets, isEmpty);
  });

  test('kinds use separate storage keys', () async {
    await repo.tryAddMessage(motivator, 'Mot only');
    await repo.tryAddMessage(affirmation, 'Aff only');

    final motRaw = await storage.read(key: StorageKeys.dashboardMotivatorPack);
    final affRaw = await storage.read(key: StorageKeys.dailyAffirmationPack);
    expect(motRaw, isNotNull);
    expect(affRaw, isNotNull);
    expect(motRaw, isNot(affRaw));

    expect(
      (await repo.read(motivator)).messages.single.text,
      'Mot only',
    );
    expect(
      (await repo.read(affirmation)).messages.single.text,
      'Aff only',
    );
  });

  test('migrates legacy customAffirmationPack into kind keys', () async {
    final legacy = PhrasePackData(
      enabled: true,
      mode: PhrasePlaybackMode.sequence,
      messages: const [
        PhraseMessage(
          id: 'bm_0',
          text: 'Legacy mot',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.baseline,
        ),
        PhraseMessage(
          id: 'ba_0',
          text: 'Legacy aff',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.baseline,
        ),
        PhraseMessage(
          id: 'm_custom',
          text: 'Shared custom',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.custom,
        ),
      ],
      queueIds: const ['bm_0', 'ba_0', 'm_custom'],
      presets: const [],
    );
    await storage.write(
      key: StorageKeys.customAffirmationPack,
      value: PhrasePackCodec.encode(legacy),
    );

    final mot = await repo.read(motivator);
    expect(mot.messages.map((m) => m.id), ['bm_0', 'm_custom']);
    expect(
      await storage.read(key: StorageKeys.dashboardMotivatorPack),
      isNotNull,
    );

    final aff = await repo.read(affirmation);
    expect(aff.messages.map((m) => m.id), ['ba_0', 'm_custom']);
    expect(
      await storage.read(key: StorageKeys.dailyAffirmationPack),
      isNotNull,
    );
  });

  test('writeMode and reorderQueue are free', () async {
    await repo.tryAddMessage(motivator, 'A');
    await repo.tryAddMessage(motivator, 'B');
    final ids = (await repo.read(motivator)).queueIds;
    final balance = await points.readBalance();

    await repo.writeMode(motivator, PhrasePlaybackMode.random);
    expect((await repo.read(motivator)).mode, PhrasePlaybackMode.random);
    expect(await points.readBalance(), balance);

    await repo.reorderQueue(motivator, 1, 0);
    expect((await repo.read(motivator)).queueIds, [ids[1], ids[0]]);
    expect(await points.readBalance(), balance);

    // onReorderItem-style indices: move first item to last without +1 gap.
    await repo.reorderQueue(motivator, 0, 1);
    expect((await repo.read(motivator)).queueIds, [ids[0], ids[1]]);
    expect(await points.readBalance(), balance);
  });
}
