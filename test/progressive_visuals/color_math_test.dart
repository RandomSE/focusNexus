import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/color_math.dart';
import 'package:focusNexus/progressive_visuals/mutation_kind.dart';
import 'package:focusNexus/progressive_visuals/visual_bridge.dart';

void main() {
  group('invertArgb32', () {
    test('preserves alpha and inverts rgb', () {
      const argb = 0x80112233;
      final inverted = invertArgb32(argb);
      expect((inverted >> 24) & 0xFF, 0x80);
      expect(inverted & 0xFF, 0xCC);
      expect((inverted >> 16) & 0xFF, 0xEE);
      expect((inverted >> 8) & 0xFF, 0xDD);
    });

    test('double inversion returns original rgb with same alpha', () {
      const argb = 0xFF0A1B2C;
      expect(invertArgb32(invertArgb32(argb)), argb);
    });
  });

  group('applyMutationTint', () {
    test('returns base color when mutation is null', () {
      const base = Color(0xFF336699);
      expect(applyMutationTint(base: base, mutation: null), base);
    });

    test('inverts rgb for invertedColors mutation', () {
      const base = Color(0xFF112233);
      final tinted = applyMutationTint(
        base: base,
        mutation: MutationKind.invertedColors,
      );
      expect((tinted.r * 255).round(), 0xEE);
      expect((tinted.g * 255).round(), 0xDD);
      expect((tinted.b * 255).round(), 0xCC);
      expect(tinted.a, base.a);
    });
  });
}
