import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('smoke: settings screen shows core toggles', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Settings'));

    await tester.tap(find.text('Settings'));
    await pumpUntilFound(tester, find.text('Reward Type'));

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Notification Frequency'), findsOneWidget);
  });
}
