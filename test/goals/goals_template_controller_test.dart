import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/goals_provider.dart';
import 'package:focusNexus/providers/goals_screen_ui_provider.dart';
import 'package:focusNexus/repositories/app_repositories.dart';
import 'package:focusNexus/screens/goals/goals_template_controller.dart';

import '../helpers/in_memory_key_value_storage.dart';
import '../helpers/test_provider_scope.dart';

GoalsTemplateController _controller({
  required AppRepositories repos,
  required GoalsScreenUiNotifier uiNotifier,
  required GoalsNotifier goalsNotifier,
  Map<String, Map<String, dynamic>>? templateDetails,
  GoalsScreenUiState Function()? getUiState,
}) {
  return GoalsTemplateController(
    repos: repos,
    uiNotifier: uiNotifier,
    goalsNotifier: goalsNotifier,
    templateDetails: templateDetails ?? createBuiltinTemplateDetails(),
    categories: const ['Health', 'Productivity'],
    levels: const ['Low', 'Medium', 'High'],
    anchorDate: DateTime(2026, 6, 3, 12),
    templateNameController: TextEditingController(),
    templateTimeController: TextEditingController(),
    templateStepsController: TextEditingController(),
    templateDeadlineController: TextEditingController(),
    titleController: TextEditingController(),
    timeController: TextEditingController(),
    deadlineController: TextEditingController(),
    stepsController: TextEditingController(),
    getUiState: getUiState ?? () => uiNotifier.state,
    isMounted: () => false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsTemplateController', () {
    late AppRepositories repos;
    late ProviderContainer container;

    setUp(() async {
      final storage = InMemoryKeyValueStorage();
      repos = AppRepositories(storage);
      container = await createTestContainer(storage: storage);
      addTearDown(container.dispose);
      await lightTestBootstrap(container);
      await container.read(goalsProvider.notifier).load();
    });

    test('buildBulkCreateInputs maps builtin and user templates', () {
      final uiNotifier = container.read(goalsScreenUiProvider.notifier);
      uiNotifier.update(
        (state) => state.copyWith(
          userTemplates: {
            'Evening wind-down': {
              'category': 'Health',
              'complexity': 'Low',
              'effort': 'Low',
              'motivation': 'Medium',
              'time': '15',
              'Hours to complete': '12',
              'steps': '2',
            },
          },
        ),
      );

      final controller = _controller(
        repos: repos,
        uiNotifier: uiNotifier,
        goalsNotifier: container.read(goalsProvider.notifier),
      );

      final inputs = controller.buildBulkCreateInputs(
        templateNames: ['5-minute walk', 'Evening wind-down'],
        userTemplates: uiNotifier.state.userTemplates,
      );

      expect(inputs, hasLength(2));
      expect(inputs[0].title, '5-minute walk');
      expect(inputs[0].category, 'Health');
      expect(inputs[0].deadlineHours, 24);
      expect(inputs[1].title, 'Evening wind-down');
      expect(inputs[1].steps, '2');
      expect(inputs[1].deadlineHours, 12);
    });

    test('pruneTemplateGroups removes stale template names and persists', () async {
      final uiNotifier = container.read(goalsScreenUiProvider.notifier);
      uiNotifier.update(
        (state) => state.copyWith(
          templateGroups: {
            'Morning': ['5-minute walk', 'Deleted template'],
            'Empty soon': ['Missing only'],
          },
        ),
      );
      await repos.templates.writeTemplateGroups(uiNotifier.state.templateGroups);

      final controller = _controller(
        repos: repos,
        uiNotifier: uiNotifier,
        goalsNotifier: container.read(goalsProvider.notifier),
      );

      final result = await controller.pruneTemplateGroups();

      expect(result.removedGroupNames, contains('Empty soon'));
      expect(result.rebuiltGroups.keys, contains('Morning'));
      expect(
        uiNotifier.state.templateGroups['Morning'],
        ['5-minute walk'],
      );

      final stored = await repos.templates.readTemplateGroups();
      expect(stored['Morning'], ['5-minute walk']);
      expect(stored.containsKey('Empty soon'), isFalse);
    });
  });
}
