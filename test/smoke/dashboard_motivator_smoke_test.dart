import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/motivators/adhd_motivator_pack.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('motivator does not block Goals navigation', (tester) async {
    final storage = onboardedTestStorage();
    // Already granted today so snackbar path stays quiet.
    final today = DateTime.now();
    final y = today.year.toString().padLeft(4, '0');
    final m = today.month.toString().padLeft(2, '0');
    final d = today.day.toString().padLeft(2, '0');
    await storage.write(key: StorageKeys.lastAppOpenGrantDate, value: '$y-$m-$d');
    await storage.write(key: StorageKeys.consecutiveDaysAppOpened, value: '1');
    await storage.write(key: StorageKeys.points, value: '100');

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Dashboard'));

    final motivator = AdhdMotivatorPack.forDate(DateTime.now());
    expect(find.text(motivator), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);

    await tester.tap(find.text('Goals'));
    await tester.pump();
    await pumpUntilFound(tester, find.widgetWithText(AppBar, 'Goals'));

    // Navigated; motivator must not prevent route push (may remain under stack).
    expect(find.widgetWithText(AppBar, 'Goals'), findsOneWidget);
  });

  testWidgets('dismiss removes motivator and keeps nav buttons', (tester) async {
    final storage = onboardedTestStorage();
    final today = DateTime.now();
    final dayKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    await storage.write(key: StorageKeys.lastAppOpenGrantDate, value: dayKey);
    await storage.write(key: StorageKeys.consecutiveDaysAppOpened, value: '1');

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Dashboard'));

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();

    expect(find.byTooltip('Dismiss'), findsNothing);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
  });

  testWidgets('tap swaps motivator line without disabling settings', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    final today = DateTime.now();
    final dayKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    await storage.write(key: StorageKeys.lastAppOpenGrantDate, value: dayKey);

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Dashboard'));

    final first = AdhdMotivatorPack.forDate(DateTime.now());
    final second = AdhdMotivatorPack.lineAt(
      AdhdMotivatorPack.seedForDate(DateTime.now()) + 1,
    );

    await tester.tap(find.text(first));
    await tester.pump();

    expect(find.text(second), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
