import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/screens/goals_screen.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scrolling past sort detaches goals to full-height list', (
    tester,
  ) async {
    final container = await createTestContainer(
      storage: onboardedTestStorage(),
    );
    addTearDown(container.dispose);
    await lightTestBootstrap(container);
    await container.read(appSettingsProvider.notifier).load();
    await container.read(goalsProvider.notifier).load();

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );
    await pumpUntilFound(tester, find.text('Add Goal'));

    for (var i = 0; i < 6; i++) {
      await container.read(goalsProvider.notifier).createGoal(
            title: 'Scroll Goal $i',
            category: 'Health',
            complexity: 'Low',
            effort: 'Low',
            motivation: 'Low',
            time: '5',
            steps: '1',
            deadlineHours: 0,
            anchor: DateTime(2026, 6, 3, 12),
          );
    }
    await tester.pumpAndSettle();
    expect(container.read(goalsProvider).activeGoals, hasLength(6));

    final scrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      find.text('Scroll Goal 0'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('Scroll Goal 0'), findsOneWidget);

    await tester.fling(scrollable, const Offset(0, -2000), 3000);
    await tester.pumpAndSettle();

    final pixelsAfterUp =
        tester.state<ScrollableState>(scrollable).position.pixels;
    expect(pixelsAfterUp, greaterThan(300));
    expect(find.text('Scroll Goal 0'), findsOneWidget);
    expect(find.text('Your goals'), findsOneWidget);

    await tester.fling(scrollable, const Offset(0, 2000), 3000);
    await tester.pumpAndSettle();

    final addGoal = find.text('Add Goal');
    await tester.scrollUntilVisible(addGoal, 100, scrollable: scrollable);
    expect(tester.getTopLeft(addGoal).dy, greaterThanOrEqualTo(0));
  });
}
