import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';

import 'helpers/test_provider_scope.dart';

void main() {
  testWidgets('Auth route shows welcome screen', (WidgetTester tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.auth,
      bootstrap: false,
    );
    await pumpSettleWithTimeout(tester);

    expect(find.text('Welcome to FocusNexus'), findsOneWidget);
    expect(find.text('Get started with FocusNexus'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Register'), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
