import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/mini_games/firefly_jar/firefly_jar_constants.dart';
import 'package:focusNexus/screens/mini_games_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('smoke: dashboard navigates to goals screen', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Goals'));

    await tester.tap(find.text('Goals'));
    await pumpUntilFound(tester, find.text('Template (optional)'));

    expect(find.text('Category'), findsOneWidget);
  });

  testWidgets('smoke: dashboard navigates to settings screen', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Settings'));

    await tester.ensureVisible(find.text('Settings'));
    await tester.pump();
    await tester.tap(find.text('Settings'));
    await pumpUntilFound(tester, find.text('Reward types'));

    expect(find.text('Notification Frequency'), findsOneWidget);
  });

  testWidgets('smoke: dashboard shows a button per enabled reward type', (
    tester,
  ) async {
    final storage = onboardedTestStorage();
    await storage.write(
      key: StorageKeys.rewardTypes,
      value: '["Mini-games","Progressive visuals"]',
    );

    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: storage,
    );
    await pumpUntilFound(tester, find.text('Mini-games'));
    expect(find.text('Progressive visuals'), findsOneWidget);
    expect(find.text('Customization'), findsNothing);

    // Navigate Mini-games (not Progressive visuals): Zen garden persist schedules
    // a Riverpod zero-duration refresh timer that can outlive the test.
    await tester.ensureVisible(find.text('Mini-games'));
    await tester.pump();
    await tester.tap(find.text('Mini-games'));
    await pumpUntilFound(tester, find.text(FireflyJarConstants.title));
    expect(
      find.text(miniGamesLastPlayedButtonLabel(FireflyJarConstants.title)),
      findsOneWidget,
    );
  });
}
