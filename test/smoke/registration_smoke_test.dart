import 'package:flutter/material.dart';
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
    expect(find.text('Reward types'), findsOneWidget);
    expect(find.text('I confirm I am 13 or older'), findsOneWidget);
    expect(find.text('Add username (optional)'), findsOneWidget);
    expect(find.text('Username'), findsNothing);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('smoke: add username button reveals the optional field',
      (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.auth,
      lightBootstrap: false,
    );
    await pumpUntilFound(tester, find.text('Get started'));

    await tester.tap(find.text('Get started'));
    await pumpUntilFound(tester, find.text('Add username (optional)'));

    expect(find.text('Username'), findsNothing);
    await tester.tap(find.text('Add username (optional)'));
    await tester.pump();

    expect(find.text('Add username (optional)'), findsNothing);
    expect(find.text('Username'), findsOneWidget);
  });
}
