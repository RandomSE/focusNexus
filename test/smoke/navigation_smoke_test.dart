import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';

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

    await tester.tap(find.text('Settings'));
    await pumpUntilFound(tester, find.text('Reward Type'));

    expect(find.text('Notification Frequency'), findsOneWidget);
  });
}
