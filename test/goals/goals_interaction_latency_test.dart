import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/app_settings_provider.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/screens/goals_screen.dart';

import '../helpers/latency_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

/// End-to-end tap → goals list repaint (GoalsScreen + Riverpod).
///
/// Slow secure-storage timing is covered in [goals_view_latency_test.dart]
/// so this file does not block on [DeferredScreen] initial load.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpGoalsScreenReady(WidgetTester tester) async {
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
    return container;
  }

  group('GoalsScreen tap-to-visible latency', () {
    testWidgets('Add Goal shows new row within budget', (tester) async {
      await pumpGoalsScreenReady(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Fresh Goal');
      await tester.enterText(fields.at(1), '10');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -850));
      await tester.pumpAndSettle();

      final addGoal = find.text('Add Goal');
      await tester.ensureVisible(addGoal);
      await tester.pump();

      final stopwatch = Stopwatch()..start();
      await tester.tap(addGoal);
      while (stopwatch.elapsedMilliseconds < 1500) {
        await tester.pump();
        if (find.text('Fresh Goal').evaluate().isNotEmpty) break;
      }
      if (find.text('Fresh Goal').evaluate().isEmpty) {
        final scrollable = find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        ).first;
        await tester.scrollUntilVisible(
          find.text('Fresh Goal'),
          200,
          scrollable: scrollable,
        );
      }
      stopwatch.stop();

      expect(
        find.text('Fresh Goal'),
        findsWidgets,
        reason: 'goal title should appear in the list',
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(goalsWidgetUiUpdateBudgetMs));
    });

    testWidgets('Complete Goal removes row within budget', (tester) async {
      final container = await pumpGoalsScreenReady(tester);
      await container.read(goalsProvider.notifier).createGoal(
            title: 'Latency Goal',
            category: 'Health',
            complexity: 'Low',
            effort: 'Low',
            motivation: 'Low',
            time: '5',
            steps: '1',
            deadlineHours: 0,
            anchor: DateTime(2026, 6, 3, 12),
          );
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2800));
      await tester.pumpAndSettle();
      expect(find.text('Latency Goal'), findsOneWidget);

      final completeButton = find.byTooltip('Complete Goal');
      await tester.ensureVisible(completeButton);
      await tester.pump();

      final stopwatch = Stopwatch()..start();
      await tester.tap(completeButton);
      while (stopwatch.elapsedMilliseconds < 500) {
        await tester.pump();
        if (find.text('Latency Goal').evaluate().isEmpty) break;
      }
      stopwatch.stop();

      expect(find.text('Latency Goal'), findsNothing);
      expect(stopwatch.elapsedMilliseconds, lessThan(goalsWidgetUiUpdateBudgetMs));
    });
  });
}
