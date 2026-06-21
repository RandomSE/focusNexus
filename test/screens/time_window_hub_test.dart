import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/goals/time_window_goals_hub_screen.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('TimeSlotGoalsHub shows inline create and bulk action', (
    tester,
  ) async {
    final container = await createTestContainer(
      storage: onboardedTestStorage(),
    );
    addTearDown(container.dispose);
    await lightTestBootstrap(container);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: TimeWindowGoalsHubScreen()),
      ),
    );
    await pumpUntilFound(tester, find.text('Create a time-slot goal'));
    await tester.scrollUntilVisible(
      find.text('Active repeating goals'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Time-slot goals'), findsOneWidget);
    expect(find.text('Create time-slot goal'), findsOneWidget);
    expect(find.text('Create multiple goals'), findsOneWidget);
    expect(find.text('Active repeating goals'), findsOneWidget);
    expect(find.text('Create goal manually'), findsNothing);
  });
}
