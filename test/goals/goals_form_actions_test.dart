import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/screens/goals/goals_form_actions.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/utils/theme_styles.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

ThemeBundle _testBundle() {
  const primary = Colors.black87;
  const secondary = Colors.white;
  const accent = Colors.teal;
  final textStyle = ThemeStyles.buildTextStyle(
    primaryColor: primary,
    fontSize: 14,
    useDyslexiaFont: false,
  );
  return ThemeBundle(
    themeData: ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: secondary,
    ),
    primaryColor: primary,
    secondaryColor: secondary,
    accentColor: accent,
    textStyle: textStyle,
    buttonStyle: ElevatedButton.styleFrom(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsFormActions', () {
    late ProviderContainer container;
    late GlobalKey<FormState> formKey;
    late TextEditingController titleController;
    late TextEditingController timeController;
    late TextEditingController deadlineController;
    late TextEditingController stepsController;
    late GoalsFormActions actions;

    setUp(() async {
      container = await createTestContainer(storage: onboardedTestStorage());
      await lightTestBootstrap(container);
      await container.read(goalsProvider.notifier).load();

      formKey = GlobalKey<FormState>();
      titleController = TextEditingController();
      timeController = TextEditingController();
      deadlineController = TextEditingController();
      stepsController = TextEditingController(text: '1');

      actions = GoalsFormActions(
        goalsNotifier: container.read(goalsProvider.notifier),
        getUiState: () => container.read(goalsScreenUiProvider),
        anchorDate: DateTime(2026, 6, 3, 12),
        formKey: formKey,
        titleController: titleController,
        timeController: timeController,
        deadlineController: deadlineController,
        stepsController: stepsController,
        resetControllers: () {
          titleController.clear();
          timeController.clear();
          deadlineController.clear();
          stepsController.text = '1';
        },
      );
    });

    tearDown(() {
      titleController.dispose();
      timeController.dispose();
      deadlineController.dispose();
      stepsController.dispose();
      container.dispose();
    });

    Future<void> pumpFormHarness(
      WidgetTester tester, {
      required VoidCallback onSubmit,
      VoidCallback? onClear,
    }) async {
      await tester.pumpWidget(
        testUncontrolledScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: timeController,
                        decoration: const InputDecoration(labelText: 'Time'),
                        validator: (v) {
                          final parsed = int.tryParse(v?.trim() ?? '');
                          if (parsed == null || parsed < 1) return 'Invalid';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: stepsController,
                        decoration: const InputDecoration(labelText: 'Steps'),
                      ),
                      ElevatedButton(
                        onPressed: onSubmit,
                        child: const Text('Submit goal'),
                      ),
                      if (onClear != null)
                        ElevatedButton(
                          onPressed: onClear,
                          child: const Text('Clear active'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('createGoal shows snackbar and clears title field', (
      tester,
    ) async {
      titleController.text = 'Snack Goal';
      timeController.text = '10';

      await pumpFormHarness(
        tester,
        onSubmit:
            () => actions.createGoal(
              context: tester.element(find.byType(Scaffold)),
              bundle: _testBundle(),
              soundService: SoundService(InMemoryKeyValueStorage()),
              syncGoalsCompletedToday: () {},
              isMounted: () => true,
            ),
      );

      await tester.tap(find.text('Submit goal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Goal "Snack Goal" created!'), findsOneWidget);
      expect(titleController.text, isEmpty);
      expect(
        container.read(goalsProvider).activeGoals.any(
          (g) => g.title == 'Snack Goal',
        ),
        isTrue,
      );
    });

    testWidgets('clearGoals removes active goals without repeat dialog', (
      tester,
    ) async {
      await container.read(goalsProvider.notifier).createGoal(
        title: 'To clear',
        category: 'Health',
        complexity: 'Low',
        effort: 'Low',
        motivation: 'Low',
        time: '5',
        steps: '1',
        deadlineHours: 0,
        anchor: DateTime(2026, 6, 3, 12),
      );
      expect(container.read(goalsProvider).activeGoals, isNotEmpty);

      await pumpFormHarness(
        tester,
        onSubmit: () {},
        onClear:
            () => actions.clearGoals(
              context: tester.element(find.byType(Scaffold)),
              bundle: _testBundle(),
              isMounted: () => true,
            ),
      );

      await tester.tap(find.text('Clear active'));
      await tester.pumpAndSettle();

      expect(container.read(goalsProvider).activeGoals, isEmpty);
    });
  });
}
