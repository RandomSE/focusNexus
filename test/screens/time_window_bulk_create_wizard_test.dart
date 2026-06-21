import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/goals/time_window_bulk_create_wizard.dart';

import '../helpers/test_provider_scope.dart';

Finder _nextButton() => find.widgetWithText(ElevatedButton, 'Next');

Future<void> _tapWizardNext(WidgetTester tester) async {
  final button = _nextButton();
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bulk wizard offers per-goal window and repeat editors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = await createTestContainer(
      storage: onboardedTestStorage(),
    );
    addTearDown(container.dispose);
    await lightTestBootstrap(container);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: TimeWindowBulkCreateWizard()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('5-minute walk'));
    await tester.tap(find.text('Take a shower'));
    await tester.pumpAndSettle();
    await _tapWizardNext(tester);

    expect(find.text('Configure slots'), findsOneWidget);
    expect(find.text('Apply slot to all'), findsOneWidget);
    expect(find.text('Customize each goal'), findsOneWidget);
    expect(find.text('5-minute walk'), findsOneWidget);
    expect(find.text('Take a shower'), findsOneWidget);

    await _tapWizardNext(tester);

    expect(find.text('Configure repeats'), findsOneWidget);
    expect(find.text('Apply repeat to all'), findsOneWidget);
    expect(find.text('Customize each goal'), findsOneWidget);

    final repeatSwitches = find.widgetWithText(SwitchListTile, 'Repeat');
    expect(repeatSwitches, findsNWidgets(3));
    expect(tester.widget<SwitchListTile>(repeatSwitches.at(1)).value, isFalse);

    await tester.tap(repeatSwitches.at(2));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(repeatSwitches.at(1)).value, isFalse);
    expect(tester.widget<SwitchListTile>(repeatSwitches.at(2)).value, isTrue);
  });
}
