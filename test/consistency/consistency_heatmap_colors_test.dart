import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/consistency/consistency_heatmap_colors.dart';

void main() {
  group('ConsistencyHeatmapColors.rampT', () {
    test('intensifies within and across tiers', () {
      expect(
        ConsistencyHeatmapColors.rampT(4),
        greaterThan(ConsistencyHeatmapColors.rampT(1)),
      );
      expect(
        ConsistencyHeatmapColors.rampT(9),
        greaterThan(ConsistencyHeatmapColors.rampT(5)),
      );
      expect(
        ConsistencyHeatmapColors.rampT(25),
        greaterThan(ConsistencyHeatmapColors.rampT(10)),
      );
    });

    test('caps at 50 so 50 equals 80', () {
      expect(
        ConsistencyHeatmapColors.rampT(50),
        ConsistencyHeatmapColors.rampT(80),
      );
      expect(
        ConsistencyHeatmapColors.rampColor(count: 50, isDark: false),
        ConsistencyHeatmapColors.rampColor(count: 80, isDark: false),
      );
    });

    test('is monotonic for 1..50', () {
      var prev = ConsistencyHeatmapColors.rampT(1);
      for (var c = 2; c <= 50; c++) {
        final next = ConsistencyHeatmapColors.rampT(c);
        expect(
          next,
          greaterThanOrEqualTo(prev),
          reason: 'rampT($c) >= rampT(${c - 1})',
        );
        prev = next;
      }
    });
  });

  group('ConsistencyHeatmapColors palettes', () {
    test('default Cool Teal Depth light darkens as count rises', () {
      final a = ConsistencyHeatmapColors.rampColor(
        count: 1,
        isDark: false,
        palette: ConsistencyPaletteId.coolTealDepth,
      );
      final b = ConsistencyHeatmapColors.rampColor(
        count: 25,
        isDark: false,
        palette: ConsistencyPaletteId.coolTealDepth,
      );
      final c = ConsistencyHeatmapColors.rampColor(
        count: 50,
        isDark: false,
        palette: ConsistencyPaletteId.coolTealDepth,
      );
      expect(b.computeLuminance(), lessThan(a.computeLuminance()));
      expect(c.computeLuminance(), lessThan(b.computeLuminance()));
    });

    test('Soft Purple and Golden Hour light darken with count', () {
      for (final palette in [
        ConsistencyPaletteId.softPurple,
        ConsistencyPaletteId.goldenHour,
        ConsistencyPaletteId.forestGreens,
        ConsistencyPaletteId.oceanBlues,
        ConsistencyPaletteId.monochromeGreyscale,
      ]) {
        final a = ConsistencyHeatmapColors.rampColor(
          count: 1,
          isDark: false,
          palette: palette,
        );
        final b = ConsistencyHeatmapColors.rampColor(
          count: 50,
          isDark: false,
          palette: palette,
        );
        expect(
          b.computeLuminance(),
          lessThan(a.computeLuminance()),
          reason: palette.displayName,
        );
      }
    });

    test('dark mode brightens as count rises for Cool Teal', () {
      final a = ConsistencyHeatmapColors.rampColor(
        count: 1,
        isDark: true,
        palette: ConsistencyPaletteId.coolTealDepth,
      );
      final b = ConsistencyHeatmapColors.rampColor(
        count: 50,
        isDark: true,
        palette: ConsistencyPaletteId.coolTealDepth,
      );
      expect(b.computeLuminance(), greaterThan(a.computeLuminance()));
    });

    test('parse defaults unknown to Cool Teal Depth', () {
      expect(
        ConsistencyPaletteId.parse(null),
        ConsistencyPaletteId.coolTealDepth,
      );
      expect(
        ConsistencyPaletteId.parse('soft_purple'),
        ConsistencyPaletteId.softPurple,
      );
      expect(
        ConsistencyPaletteId.parse('golden_hour').displayName,
        'Golden Hour',
      );
      expect(
        ConsistencyPaletteId.parse('forest_greens').displayName,
        'Forest Greens',
      );
      expect(
        ConsistencyPaletteId.parse('ocean_blues').displayName,
        'Ocean Blues',
      );
      expect(
        ConsistencyPaletteId.parse('monochrome_greyscale').displayName,
        'Monochrome Greyscale',
      );
    });

    test('zero colour matches teal near-white', () {
      expect(
        ConsistencyHeatmapColors.zeroColor(
          isDark: false,
          palette: ConsistencyPaletteId.coolTealDepth,
        ),
        const Color(0xFFE8EEEE),
      );
      expect(
        ConsistencyHeatmapColors.zeroColor(
          isDark: false,
          palette: ConsistencyPaletteId.forestGreens,
        ),
        const Color(0xFFE8F4E8),
      );
    });

    test('selected chip label colour contrasts with primary fill', () {
      const fill = Color(0xFF1D2730);
      final label = ConsistencyHeatmapColors.dayNumberColor(fill);
      expect(label.computeLuminance(), greaterThan(0.5));
    });
  });

  group('ConsistencyCellSemantics', () {
    final today = DateTime(2026, 8, 3);

    test('future is futureEmpty; today-zero and past-zero are missed', () {
      expect(
        ConsistencyCellSemantics.kindFor(
          day: DateTime(2026, 8, 4),
          today: today,
          count: 0,
        ),
        ConsistencyCellKind.futureEmpty,
      );
      expect(
        ConsistencyCellSemantics.kindFor(
          day: today,
          today: today,
          count: 0,
        ),
        ConsistencyCellKind.missed,
      );
      expect(
        ConsistencyCellSemantics.kindFor(
          day: DateTime(2026, 8, 2),
          today: today,
          count: 0,
        ),
        ConsistencyCellKind.missed,
      );
    });

    test('missed fill uses palette zero only', () {
      final fill = ConsistencyCellSemantics.fillFor(
        kind: ConsistencyCellKind.missed,
        count: 0,
        isDark: false,
        palette: ConsistencyPaletteId.forestGreens,
      );
      expect(fill, const Color(0xFFE8F4E8));
      expect(
        fill,
        isNot(const Color(0xFFF3F6F4)),
      );
    });

    test('count >= 1 is active', () {
      expect(
        ConsistencyCellSemantics.kindFor(
          day: DateTime(2026, 8, 1),
          today: today,
          count: 3,
        ),
        ConsistencyCellKind.active,
      );
    });
  });
}
