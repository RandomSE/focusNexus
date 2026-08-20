import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/common_utils.dart';

void main() {
  testWidgets(
    'form field error text wraps fully at font size 24',
    (tester) async {
      final formKey = GlobalKey<FormState>();
      final deadline = TextEditingController(text: '130');
      const style = TextStyle(fontSize: 24, fontFamily: 'OpenDyslexic');
      const message = 'Deadline must be greater than time required.';

      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        deadline.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    CommonUtils.buildTextFormField(
                      deadline,
                      'Hours to complete (optional)',
                      style,
                      Colors.white,
                      true,
                      (_) => message,
                      keyboardType: TextInputType.number,
                    ),
                    ElevatedButton(
                      onPressed: () => formKey.currentState!.validate(),
                      child: const Text('check'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      final errorText = tester.widget<Text>(find.text(message));
      // Flutter InputDecorator hardcodes overflow: ellipsis, but raises maxLines
      // from errorMaxLines so long validators wrap instead of single-line cut-off.
      expect(errorText.maxLines, greaterThanOrEqualTo(4));
      final errorSize = tester.getSize(find.text(message));
      expect(errorSize.height, greaterThan(style.fontSize! * 1.5));
    },
  );
}
