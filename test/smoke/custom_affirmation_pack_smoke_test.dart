import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/services/custom_affirmation_pack.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

String _todayKey() {
  final today = DateTime.now();
  return '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';
}

Future<void> _quietDailyOpen(dynamic storage) async {
  await storage.write(key: StorageKeys.lastAppOpenGrantDate, value: _todayKey());
  await storage.write(key: StorageKeys.consecutiveDaysAppOpened, value: '1');
  await storage.write(key: StorageKeys.points, value: '500');
}

PhrasePackData _singleLinePack({
  required String text,
  bool enabled = true,
}) {
  return PhrasePackData(
    enabled: enabled,
    mode: PhrasePlaybackMode.sequence,
    messages: [
      PhraseMessage(
        id: 'a',
        text: text,
        createdAtMs: 1,
        updatedAtMs: 1,
        origin: PhraseOrigin.custom,
      ),
    ],
    queueIds: const ['a'],
    presets: const [],
  );
}

void main() {
  testWidgets('motivator pack replaces dashboard baseline when enabled', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    final pack = _singleLinePack(text: 'My custom motivator line');
    await storage.write(
      key: StorageKeys.dashboardMotivatorPack,
      value: PhrasePackCodec.encode(pack),
    );

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My custom motivator line'), findsOneWidget);
  });

  testWidgets('motivatorsDisabled hides dashboard banner', (tester) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    await storage.write(key: StorageKeys.motivatorsDisabled, value: 'true');

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Dashboard'));
    await tester.pump();

    expect(find.byTooltip('Dismiss'), findsNothing);
    expect(find.text('Goals'), findsOneWidget);
  });

  testWidgets('daily affirmation editor shows mode chips and add action', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    final pack = _singleLinePack(
      text: 'Editor layout check line',
      enabled: false,
    );
    await storage.write(
      key: StorageKeys.dailyAffirmationPack,
      value: PhrasePackCodec.encode(pack),
    );

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dailyAffirmationPack,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Daily affirmations'));
    await pumpUntilFound(tester, find.textContaining('Add ('));
    await pumpUntilFound(tester, find.text('Sequence'));
    await pumpUntilFound(tester, find.text('Random'));

    expect(tester.takeException(), isNull);
    expect(find.byType(FilterChip), findsWidgets);
  });

  testWidgets('Active queue stays single-line at large font', (tester) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    await storage.write(key: StorageKeys.fontSize, value: '24');
    final pack = _singleLinePack(
      text: 'Large font queue layout line',
      enabled: false,
    );
    await storage.write(
      key: StorageKeys.dashboardMotivatorPack,
      value: PhrasePackCodec.encode(pack),
    );

    // Tall surface so large font controls stay in the built tree.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboardMotivatorPack,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Build set'), maxPumps: 80);
    expect(find.text('Active queue'), findsOneWidget);
    await tester.pump();

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.text('Active queue'));
    // One-char-per-line for "Active queue" at 24px would be far taller.
    expect(size.height, lessThan(72));
    expect(size.width, greaterThan(80));

    // Save preset / Build set sit above Active queue.
    final saveY = tester.getTopLeft(find.text('Save preset')).dy;
    final queueY = tester.getTopLeft(find.text('Active queue')).dy;
    expect(saveY, lessThan(queueY));
    expect(find.byType(OutlinedButton), findsWidgets);
    // Custom-only queue hides Library.
    expect(find.text('Library'), findsNothing);
  });

  testWidgets('build set save does not dispose controllers mid-rebuild', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    final pack = PhrasePackData(
      enabled: false,
      mode: PhrasePlaybackMode.sequence,
      messages: [
        const PhraseMessage(
          id: 'bm_0',
          text: 'Base line one',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.baseline,
        ),
        const PhraseMessage(
          id: 'c1',
          text: 'Custom line one',
          createdAtMs: 2,
          updatedAtMs: 2,
          origin: PhraseOrigin.custom,
        ),
      ],
      queueIds: const ['bm_0', 'c1'],
      presets: const [],
    );
    await storage.write(
      key: StorageKeys.dashboardMotivatorPack,
      value: PhrasePackCodec.encode(pack),
    );

    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboardMotivatorPack,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Build set'));
    await tester.ensureVisible(find.text('Build set'));
    await tester.tap(find.text('Build set'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await pumpUntilFound(tester, find.text('Save set'));
    // Add / remove / re-add (set size changes; previously busted ValueKeys).
    final addButtons = find.text('Add to set');
    expect(addButtons, findsWidgets);
    await tester.tap(addButtons.at(0));
    await tester.pump();
    await tester.tap(find.byTooltip('Remove instance'));
    await tester.pump();
    await tester.tap(addButtons.at(0));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Save set'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Active queue updated'), findsOneWidget);
  });

  testWidgets('build set can enqueue the same message twice', (tester) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    final pack = PhrasePackData(
      enabled: false,
      mode: PhrasePlaybackMode.sequence,
      messages: [
        const PhraseMessage(
          id: 'bm_0',
          text: 'Repeatable base line',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.baseline,
        ),
      ],
      queueIds: const ['bm_0'],
      presets: const [],
    );
    await storage.write(
      key: StorageKeys.dashboardMotivatorPack,
      value: PhrasePackCodec.encode(pack),
    );

    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboardMotivatorPack,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Build set'));
    await tester.ensureVisible(find.text('Build set'));
    await tester.tap(find.text('Build set'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, find.text('Save set'));

    final addButton = find.text('Add to set');
    await tester.tap(addButton);
    await tester.pump();
    await tester.tap(addButton);
    await tester.pump();
    expect(find.text('2 in set'), findsOneWidget);

    await tester.tap(find.text('Save set'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Active queue updated'), findsOneWidget);
    expect(find.text('Repeatable base line'), findsNWidgets(2));
    expect(find.byType(ReorderableListView), findsOneWidget);
  });

  testWidgets('active queue exposes drag reorder handles', (tester) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    final pack = PhrasePackData(
      enabled: false,
      mode: PhrasePlaybackMode.sequence,
      messages: [
        const PhraseMessage(
          id: 'a',
          text: 'Queue line A',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.custom,
        ),
        const PhraseMessage(
          id: 'b',
          text: 'Queue line B',
          createdAtMs: 2,
          updatedAtMs: 2,
          origin: PhraseOrigin.custom,
        ),
      ],
      queueIds: const ['a', 'b', 'a'],
      presets: const [],
    );
    await storage.write(
      key: StorageKeys.dailyAffirmationPack,
      value: PhrasePackCodec.encode(pack),
    );

    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dailyAffirmationPack,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Active queue'));
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    expect(find.text('Queue line A'), findsNWidgets(2));
    expect(find.text('Pos'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor never shows Library section', (tester) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    final pack = PhrasePackData(
      enabled: false,
      mode: PhrasePlaybackMode.sequence,
      messages: [
        const PhraseMessage(
          id: 'bm_0',
          text: 'Visible base library line',
          createdAtMs: 1,
          updatedAtMs: 1,
          origin: PhraseOrigin.baseline,
        ),
      ],
      queueIds: const ['bm_0'],
      presets: const [],
    );
    await storage.write(
      key: StorageKeys.dashboardMotivatorPack,
      value: PhrasePackCodec.encode(pack),
    );

    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboardMotivatorPack,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Active queue'));
    expect(find.text('Library'), findsNothing);
  });

  testWidgets('customization shows phrase packs when settings allow', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    await storage.write(
      key: StorageKeys.rewardTypes,
      value: '["Customization"]',
    );
    await storage.write(key: StorageKeys.dailyAffirmations, value: 'true');
    await storage.write(key: StorageKeys.motivatorsDisabled, value: 'false');

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.customization,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Customization'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Dashboard motivators pack'), findsOneWidget);
    expect(find.text('Edit dashboard motivators'), findsOneWidget);
    expect(find.text('Daily affirmations pack'), findsOneWidget);
    expect(find.text('Edit daily affirmations'), findsOneWidget);
  });

  testWidgets('customization hides packs when settings disable them', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await _quietDailyOpen(storage);
    await storage.write(
      key: StorageKeys.rewardTypes,
      value: '["Customization"]',
    );
    await storage.write(key: StorageKeys.dailyAffirmations, value: 'false');
    await storage.write(key: StorageKeys.motivatorsDisabled, value: 'true');

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.customization,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Customization'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Dashboard motivators pack'), findsNothing);
    expect(find.text('Edit dashboard motivators'), findsNothing);
    expect(find.text('Daily affirmations pack'), findsNothing);
    expect(find.text('Edit daily affirmations'), findsNothing);
  });
}
