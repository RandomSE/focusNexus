import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/goals/time_window_bulk_create_wizard.dart';
import 'package:focusNexus/screens/goals/widgets/time_window_bulk_draft_card.dart';

import '../helpers/test_provider_scope.dart';

Future<void> _tapWizardNext(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.drag(scrollable, const Offset(0, -1200));
  await tester.pumpAndSettle();
  final button = find.widgetWithText(ElevatedButton, 'Next');
  await tester.ensureVisible(button);
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

    Future<void> selectTemplate(String name) async {
      final tile = find.widgetWithText(CheckboxListTile, name);
      await tester.ensureVisible(tile);
      if (tester.widget<CheckboxListTile>(tile).value != true) {
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }
      expect(tester.widget<CheckboxListTile>(tile).value, isTrue);
    }

    await selectTemplate('5-minute walk');
    await selectTemplate('Take a shower');
    final selectedCount = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .where((tile) => tile.value == true)
        .length;
    expect(selectedCount, 2);
    await _tapWizardNext(tester);

    expect(find.text('Configure slots'), findsOneWidget);
    expect(find.text('Apply slot to all'), findsOneWidget);
    expect(find.text('Customize each goal'), findsOneWidget);

    final windowsScrollable = find.byType(Scrollable).first;
    for (final name in ['5-minute walk', 'Take a shower']) {
      final title = find.descendant(
        of: find.byType(TimeWindowBulkDraftCard),
        matching: find.text(name),
      );
      await tester.scrollUntilVisible(title, 100, scrollable: windowsScrollable);
      expect(title, findsOneWidget);
    }

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
