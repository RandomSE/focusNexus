import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/goals/widgets/goals_template_manager_dialog.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets(
    'Save Template with invalid form shows inline validation in the dialog',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final name = TextEditingController();
      final time = TextEditingController();
      final steps = TextEditingController(text: '1');
      final deadline = TextEditingController();

      await tester.pumpWidget(
        testProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () {
                      GoalsTemplateManagerDialog.show(
                        context,
                        templateFormKey: formKey,
                        templateNameController: name,
                        templateTimeController: time,
                        templateStepsController: steps,
                        templateDeadlineController: deadline,
                        categories: const ['Health', 'Productivity'],
                        levels: const ['Low', 'Medium', 'High'],
                        templateDetails: const {},
                        onSaveTemplate: (key) async {
                          if (!key.currentState!.validate()) {
                            return 'Please fill or fix: Template Name and Time (minutes).';
                          }
                          return null;
                        },
                        onDismiss: (dialogContext) =>
                            Navigator.pop(dialogContext),
                        onDeleteUserTemplate: (_) async {},
                        onTemplateSelected: (_, __) {},
                      );
                    },
                    child: const Text('open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Templates'), findsOneWidget);
      final saveFinder = find.text('Save Template');
      await tester.ensureVisible(saveFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Please fill or fix: Template Name and Time (minutes).'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      name.dispose();
      time.dispose();
      steps.dispose();
      deadline.dispose();
    },
  );
}
