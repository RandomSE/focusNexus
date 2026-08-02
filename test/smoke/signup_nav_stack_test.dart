import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/screens/dashboard_screen.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'FU-2: pushNamedAndRemoveUntil clears Welcome under dashboard',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: 'auth',
          routes: {
            'auth': (_) => Scaffold(
              appBar: AppBar(title: const Text('Welcome to FocusNexus')),
              body: const SizedBox.shrink(),
            ),
            'dashboard': (_) => Scaffold(
              appBar: AppBar(title: const Text('Dashboard')),
              body: const PopScope(canPop: false, child: SizedBox.shrink()),
            ),
          },
        ),
      );
      expect(find.text('Welcome to FocusNexus'), findsOneWidget);

      final ctx = tester.element(find.byType(Navigator));
      Navigator.of(ctx).pushNamedAndRemoveUntil('dashboard', (_) => false);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to FocusNexus'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
    },
  );

  testWidgets(
    'FU-2: Dashboard has no back affordance and PopScope blocks pop',
    (tester) async {
      await pumpFocusNexusApp(
        tester,
        initialRoute: AppRoutes.dashboard,
        storage: onboardedTestStorage(),
      );
      await pumpUntilFound(tester, find.text('Dashboard'));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
      expect(popScope.canPop, isFalse);
    },
  );
}
