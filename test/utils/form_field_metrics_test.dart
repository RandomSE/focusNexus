import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

void main() {
  test('dyslexia form fields use taller min heights than default', () {
    const dyslexia = TextStyle(
      fontSize: 24,
      fontFamily: 'OpenDyslexic',
      height: 1.35,
    );
    const regular = TextStyle(fontSize: 24);

    expect(formFieldMinHeight(dyslexia), greaterThan(formFieldMinHeight(regular)));
    expect(
      dropdownButtonClosedHeight(dyslexia),
      greaterThan(dropdownButtonClosedHeight(regular)),
    );
    expect(dropdownItemHeight(dyslexia), dropdownButtonClosedHeight(dyslexia));
    expect(
      formFloatingLabelBehavior(dyslexia),
      FloatingLabelBehavior.never,
    );
    expect(formFieldBottomSpacing(dyslexia), greaterThan(0));
  });

  test('non-dyslexia dropdown labels match textStyle instead of theme gray', () {
    const style = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple,
    );
    final decoration = formInputDecoration(
      label: 'Font Size',
      textStyle: style,
      isDropdown: true,
    );

    expect(decoration.labelStyle, style);
    expect(decoration.floatingLabelStyle, style);
    expect(decoration.labelText, 'Font Size');
  });

  test('non-dyslexia dropdown value centers below floating label', () {
    const style = TextStyle(fontSize: 12);
    expect(
      formDropdownSelectedAlignment(style),
      AlignmentDirectional.centerStart,
    );
    final padding = formFieldContentPadding(style, isDropdown: true);
    expect(padding.top, greaterThan(padding.bottom));
  });

  test('dyslexia dropdown value stays top-aligned for wrapped text', () {
    const style = TextStyle(fontSize: 12, fontFamily: 'OpenDyslexic');
    expect(
      formDropdownSelectedAlignment(style),
      AlignmentDirectional.topStart,
    );
  });

  test('form rows get an outline wrapper for visual separation', () {
    const style = TextStyle(fontSize: 16, color: Colors.black);
    const child = Text('Template A');

    final wrapped = outlinedFormRow(child, style);
    expect(wrapped, isA<Padding>());
    expect((wrapped as Padding).child, isA<DecoratedBox>());
  });
}
