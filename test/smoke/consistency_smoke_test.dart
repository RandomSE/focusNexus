import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('smoke: dashboard shows consistency section', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Dashboard'));
    expect(find.text('Consistency'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.textContaining('mock'), findsNothing);
  });

  testWidgets('smoke: consistency explorer route builds', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.consistencyExplorer,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Consistency'));
    expect(find.text('Select a day'), findsOneWidget);
  });

  testWidgets('smoke: explorer shows palette names and Preview', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.consistencyExplorer,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Consistency'));
    expect(find.text('Cool Teal Depth'), findsOneWidget);
    expect(find.text('Soft Purple'), findsOneWidget);
    expect(find.text('Golden Hour'), findsOneWidget);
    expect(find.text('Forest Greens'), findsOneWidget);
    expect(find.text('Ocean Blues'), findsOneWidget);
    expect(find.text('Monochrome Greyscale'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });

  testWidgets('smoke: Preview sits under Colour palette label', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.consistencyExplorer,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Colour palette'));
    final paletteBlock = find.ancestor(
      of: find.text('Colour palette'),
      matching: find.byType(Column),
    );
    expect(
      find.descendant(of: paletteBlock.first, matching: find.text('Preview')),
      findsWidgets,
    );
    // Not sharing a Row with the title (large-font squeeze guard).
    final titleRows = find.ancestor(
      of: find.text('Colour palette'),
      matching: find.byType(Row),
    );
    expect(titleRows, findsNothing);
  });

  testWidgets('smoke: preview toggles mock calendar', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.consistencyExplorer,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Preview'));
    await tester.ensureVisible(find.text('Preview'));
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.textContaining('preview'), findsWidgets);
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Consistency'), findsWidgets);
  });

  testWidgets('smoke: tap consistency day opens explorer', (tester) async {
    await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.dashboard,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Consistency'));
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    expect(find.text('Select a day').hitTestable(), findsNothing);
    expect(find.textContaining('Consistency'), findsWidgets);
  });
}
