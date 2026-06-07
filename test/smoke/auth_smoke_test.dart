import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('smoke: auth welcome screen', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.auth,
      lightBootstrap: false,
    );
    await pumpSettleWithTimeout(tester);

    expect(find.text('Welcome to FocusNexus'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
