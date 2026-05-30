import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/zen_garden/zen_garden_decor_painters.dart';

void main() {
  group('koiFishColors', () {
    test('assigns stable palette entry per fish', () {
      final a = koiFishColors(
        fishIndex: 0,
        pondId: 'pond-1',
        stageIndex: 2,
        mutated: false,
      );
      final b = koiFishColors(
        fishIndex: 0,
        pondId: 'pond-1',
        stageIndex: 2,
        mutated: false,
      );
      expect(a.body, equals(b.body));
    });

    test('different fish in same pond can differ', () {
      final colors = <Color>{
        for (var i = 0; i < 5; i++)
          koiFishColors(
            fishIndex: i,
            pondId: 'pond-colors',
            stageIndex: 3,
            mutated: false,
          ).body,
      };
      expect(colors.length, greaterThan(1));
    });

    test('mutated gold is distinct from normal orange', () {
      const normalOrange = Color(0xFFE65100);
      const mutatedGold = Color(0xFFCFB53B);
      expect(mutatedGold, isNot(equals(normalOrange)));
      for (var i = 0; i < 20; i++) {
        final mut = koiFishColors(
          fishIndex: i,
          pondId: 'gold-check',
          stageIndex: 2,
          mutated: true,
        );
        if (mut.body == mutatedGold) {
          expect(mut.body, isNot(equals(normalOrange)));
        }
      }
    });
  });
}
