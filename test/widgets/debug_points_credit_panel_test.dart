import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/consistency/consistency_aggregator.dart';
import 'package:focusNexus/services/daily_open_reward_service.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';
import 'package:focusNexus/utils/goals_codec.dart';
import 'package:focusNexus/widgets/debug_points_credit_panel.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('credits typed points then hides until next streak day', (
    tester,
  ) async {
    final now = DateTime(2026, 8, 16, 15);
    final storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '50'},
    );

    await tester.pumpWidget(
      testProviderScope(
        storage: storage,
        child: MaterialApp(
          home: Scaffold(
            body: DebugPointsCreditPanel(now: now, random: Random(1)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Credit debug points'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '250');
    await tester.tap(find.text('Credit debug points'));
    await tester.pumpAndSettle();

    expect(find.text('Credit debug points'), findsNothing);
    expect(await storage.read(key: StorageKeys.points), '300');
    expect(
      await storage.read(key: StorageKeys.debugPointsCreditDate),
      DailyOpenRewardService.formatLocalDay(now),
    );

    final completed = GoalsCodec.decodeList(
      await storage.read(key: StorageKeys.completedGoals),
    );
    expect(completed, isNotEmpty);
    final counts = ConsistencyAggregator.countsForMonth(completed, 2026, 8);
    var zeroDays = 0;
    for (var day = 1; day <= 31; day++) {
      final count = counts[DateTime(2026, 8, day)] ?? 0;
      if (count == 0) {
        zeroDays += 1;
      } else {
        expect(count, inInclusiveRange(1, 50));
      }
    }
    expect(zeroDays, 1);
  });

  testWidgets('stays hidden when already credited today', (tester) async {
    final now = DateTime(2026, 8, 16, 15);
    final storage = InMemoryKeyValueStorage(
      initial: {
        StorageKeys.debugPointsCreditDate:
            DailyOpenRewardService.formatLocalDay(now),
      },
    );

    await tester.pumpWidget(
      testProviderScope(
        storage: storage,
        child: MaterialApp(
          home: Scaffold(
            body: DebugPointsCreditPanel(now: now),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Credit debug points'), findsNothing);
  });

  testWidgets('rejects 100 million and does not credit', (tester) async {
    final storage = InMemoryKeyValueStorage(
      initial: {StorageKeys.points: '50'},
    );

    await tester.pumpWidget(
      testProviderScope(
        storage: storage,
        child: MaterialApp(
          home: Scaffold(
            body: DebugPointsCreditPanel(now: DateTime(2026, 8, 16)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '100000000');
    await tester.tap(find.text('Credit debug points'));
    await tester.pumpAndSettle();

    expect(find.text('Must be below 100 million'), findsOneWidget);
    expect(await storage.read(key: StorageKeys.points), '50');
    expect(await storage.read(key: StorageKeys.completedGoals), isNull);
  });
}
