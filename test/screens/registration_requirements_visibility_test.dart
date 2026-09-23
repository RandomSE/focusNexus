import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/registration_screen.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('setup requirements appear only after Continue is tapped', (
    tester,
  ) async {
    final container = await createTestContainer();
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: RegistrationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification Frequency'), findsNothing);
    expect(find.textContaining('to continue'), findsNothing);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.textContaining('to continue'), findsOneWidget);
    expect(find.textContaining('notification frequency'), findsNothing);
  });
}
