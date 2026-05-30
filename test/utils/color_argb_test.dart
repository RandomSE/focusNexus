import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/color_argb.dart';

void main() {
  test('colorToArgb32 round-trips standard colors', () {
    const color = Color(0xFF112233);
    expect(colorToArgb32(color), 0xFF112233);
    expect(Color(colorToArgb32(color)), color);
  });
}
