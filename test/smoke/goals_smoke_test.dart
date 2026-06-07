import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/app/app_routes.dart';
import 'package:focusNexus/providers/goals_provider.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('smoke: goals screen loads empty active list', (tester) async {
    final container = await pumpFocusNexusApp(
      tester,
      initialRoute: AppRoutes.goals,
      storage: onboardedTestStorage(),
    );
    await pumpUntilFound(tester, find.text('Template (optional)'));

    expect(find.text('Goals'), findsOneWidget);

    final goals = container.read(goalsProvider);
    expect(goals.activeGoals, isEmpty);
    expect(goals.completedGoals, isEmpty);
  });
}
