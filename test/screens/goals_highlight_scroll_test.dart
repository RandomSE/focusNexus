import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/screens/goals_screen.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification highlight scrolls highlighted goal into view', (
    tester,
  ) async {
    final container = await createTestContainer(
      storage: onboardedTestStorage(),
    );
    addTearDown(container.dispose);
    await lightTestBootstrap(container);

    final useCase = container.read(appRepositoriesProvider).goalsUseCase;
    var active = <GoalSet>[];
    for (var i = 0; i < 9; i++) {
      final goal = await useCase.createGoal(
        title: 'Filler goal $i',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
        activeSnapshot: active,
      );
      active = [...active, goal];
    }
    final highlight = await useCase.createGoal(
      title: 'Notification target',
      category: 'Health',
      complexity: 'Low',
      effort: 'Low',
      motivation: 'Low',
      time: '5',
      steps: '1',
      deadlineHours: 0,
      anchor: DateTime(2026, 6, 3, 12),
      activeSnapshot: active,
    );
    await container.read(goalsProvider.notifier).load();

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: MaterialApp(
          home: GoalsScreen(highlightGoalId: highlight.goalId),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('Add Goal'));

    final scrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    ).first;

    var pixels = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      pixels = tester.state<ScrollableState>(scrollable).position.pixels;
      if (pixels > 700) break;
    }
    expect(pixels, greaterThan(700));

    await tester.scrollUntilVisible(
      find.text('Notification target'),
      40,
      scrollable: scrollable,
    );

    final targetY = tester.getTopLeft(find.text('Notification target')).dy;
    expect(targetY, greaterThan(0));
    expect(
      targetY,
      lessThan(
        tester.view.physicalSize.height / tester.view.devicePixelRatio + 8,
      ),
    );
  });
}
