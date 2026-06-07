import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('smoke: registration screen shows required fields', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.auth,
      lightBootstrap: false,
    );
    await pumpUntilFound(tester, find.text('Get started'));

    await tester.tap(find.text('Get started'));
    await pumpUntilFound(tester, find.text('Set up FocusNexus'));

    expect(find.text('Notification Frequency'), findsOneWidget);
    expect(find.text('Reward type'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
