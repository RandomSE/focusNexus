import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/widgets/appearance_settings_section.dart';

void main() {
  group('clampUserFontSize', () {
    test('clamps to 10 minimum', () {
      expect(clampUserFontSize(5), kMinFontSize);
      expect(clampUserFontSize(9), kMinFontSize);
    });

    test('clamps to 24 maximum', () {
      expect(clampUserFontSize(25), kMaxFontSize);
      expect(clampUserFontSize(30), kMaxFontSize);
    });

    test('preserves values inside range', () {
      expect(clampUserFontSize(14), 14);
      expect(clampUserFontSize(22), 22);
    });

    test('step deltas from 22 respect caps', () {
      expect(clampUserFontSize(22 + 5), kMaxFontSize);
      expect(clampUserFontSize(kMinFontSize - 1), kMinFontSize);
    });
  });
}
