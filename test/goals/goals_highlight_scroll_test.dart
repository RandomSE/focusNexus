import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/goal_set.dart';
import 'package:focusNexus/screens/goals/goals_highlight_scroll.dart';

GoalSet _goal({required int id, required String title}) => GoalSet(
      title: title,
      category: 'Health',
      complexity: 'Low',
      effort: 'Low',
      motivation: 'Low',
      time: 10,
      steps: 1,
      points: 5,
      goalId: id,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsHighlightScrollCoordinator', () {
    test('notifyFilteredGoals is a no-op when highlight already scrolled', () {
      final coordinator = GoalsHighlightScrollCoordinator(
        scrollController: ScrollController(),
        highlightTileKey: GlobalKey(),
      );
      coordinator.highlightGoalId = 7;
      coordinator.scrolledToHighlight = true;

      coordinator.notifyFilteredGoals([_goal(id: 7, title: 'Focus')]);

      expect(coordinator.scrolledToHighlight, isTrue);
    });

    test('notifyFilteredGoals is a no-op when goal not in filtered list', () {
      final coordinator = GoalsHighlightScrollCoordinator(
        scrollController: ScrollController(),
        highlightTileKey: GlobalKey(),
      );
      coordinator.highlightGoalId = 99;

      coordinator.notifyFilteredGoals([_goal(id: 1, title: 'Other')]);

      expect(coordinator.scrolledToHighlight, isFalse);
    });

    testWidgets('notifyFilteredGoals scrolls highlight tile into view', (
      tester,
    ) async {
      final scrollController = ScrollController();
      final highlightKey = GlobalKey();
      final coordinator = GoalsHighlightScrollCoordinator(
        scrollController: scrollController,
        highlightTileKey: highlightKey,
      );
      coordinator.highlightGoalId = 42;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 180,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 600)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    key: highlightKey,
                    height: 48,
                    child: const Text('Highlighted goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(scrollController.offset, 0);
      expect(coordinator.scrolledToHighlight, isFalse);

      coordinator.notifyFilteredGoals([_goal(id: 42, title: 'Highlighted goal')]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(coordinator.scrolledToHighlight, isTrue);
      expect(scrollController.offset, greaterThan(0));
      expect(find.text('Highlighted goal'), findsOneWidget);
    });
  });
}
