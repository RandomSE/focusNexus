import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/builtin_goal_templates.dart';
import 'package:focusNexus/utils/common_utils.dart';

void main() {
  testWidgets('scrollable dialog body avoids overflow at dyslexia font 24', (
    tester,
  ) async {
    const dyslexiaStyle = TextStyle(
      fontSize: 24,
      fontFamily: 'OpenDyslexic',
      height: 1.35,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final groupNameController = TextEditingController();

    await tester.binding.setSurfaceSize(const Size(360, 640));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFFF2EFE6),
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    title: Text(
                      'Select Multiple Templates',
                      style: dyslexiaStyle,
                    ),
                    content: CommonUtils.scrollableDialogBody(
                      context: ctx,
                      children: [
                        CommonUtils.buildTextFormField(
                          groupNameController,
                          'Group Name (required to save/update)',
                          dyslexiaStyle,
                          const Color(0xFFF2EFE6),
                          true,
                          (v) => null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Select Templates to Create Goals:',
                          style: dyslexiaStyle,
                        ),
                        ...builtinGoalTemplates.keys.map(
                          (name) => CommonUtils.buildCheckboxListTile(
                            title: name,
                            textStyle: dyslexiaStyle,
                            value: false,
                            activeColor: Colors.black87,
                            checkColor: const Color(0xFFF2EFE6),
                            onChanged: (_) {},
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            CommonUtils.buildTextButton(
                              () {},
                              'Cancel',
                              dyslexiaStyle,
                            ),
                            CommonUtils.buildTextButton(
                              () {},
                              'Save/Update Group',
                              dyslexiaStyle,
                            ),
                          ],
                        ),
                        CommonUtils.buildElevatedButton(
                          'Create Goals',
                          Colors.black87,
                          const Color(0xFFF2EFE6),
                          dyslexiaStyle,
                          0,
                          0,
                          () {},
                        ),
                      ],
                    ),
                    actions: const [],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Morning routine group',
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Multiple Templates'), findsOneWidget);
    expect(find.text('Save/Update Group'), findsOneWidget);
    expect(tester.takeException(), isNull);

    addTearDown(() => tester.binding.setSurfaceSize(null));
    groupNameController.dispose();
  });
}
