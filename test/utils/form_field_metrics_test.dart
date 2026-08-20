import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

void main() {
  test('needsExpandedLabelLayout is true for dyslexia or large font size', () {
    const dyslexia = TextStyle(fontSize: 14, fontFamily: 'OpenDyslexic');
    const large = TextStyle(fontSize: 24);
    const regular = TextStyle(fontSize: 14);
    const threshold = TextStyle(fontSize: kExpandedLabelFontSizeThreshold);

    expect(needsExpandedLabelLayout(dyslexia), isTrue);
    expect(needsExpandedLabelLayout(large), isTrue);
    expect(needsExpandedLabelLayout(threshold), isTrue);
    expect(needsExpandedLabelLayout(regular), isFalse);
  });

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

  test('formInputDecoration allows multi-line error text', () {
    const style = TextStyle(fontSize: 14);
    const large = TextStyle(fontSize: 24, fontFamily: 'OpenDyslexic');
    final normal = formInputDecoration(label: 'Hours', textStyle: style);
    final expanded = formInputDecoration(label: 'Hours', textStyle: large);

    expect(normal.errorMaxLines, greaterThanOrEqualTo(4));
    expect(expanded.errorMaxLines, greaterThanOrEqualTo(6));
    expect(normal.errorStyle?.fontSize, 14);
    expect(expanded.errorStyle?.fontFamily, 'OpenDyslexic');
  });
}
