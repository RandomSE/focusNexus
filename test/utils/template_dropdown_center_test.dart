import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/common_utils.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

void main() {
  testWidgets('template optional dropdown matches other goal fields', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 14, color: Colors.black);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommonUtils.buildDropdownButtonFormField<String>(
            'Template (optional)',
            'Focus block',
            const ['Focus block'],
            style,
            Colors.white,
            (_) {},
            pinLabelToTop: true,
          ),
        ),
      ),
    );

    final field = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(field.decoration.labelText, 'Template (optional)');
    expect(field.decoration.floatingLabelBehavior, FloatingLabelBehavior.always);

    final valueText = tester.widget<Text>(find.text('Focus block').first);
    expect(valueText.textAlign, isNot(TextAlign.center));
    expect(
      formDropdownSelectedAlignment(style),
      AlignmentDirectional.centerStart,
    );
  });
}
