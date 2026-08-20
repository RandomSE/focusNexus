import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/legal/legal_documents.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('smoke: dashboard shows points and navigation', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Dashboard'));

    expect(find.textContaining('Points:'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Consistency'), findsWidgets);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(find.text('Join Discord'), findsOneWidget);
    final outlined = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Join Discord'),
    );
    final side = outlined.style?.side?.resolve({});
    expect(side?.color, const Color(kDiscordBrandBlueValue));
  });
}
