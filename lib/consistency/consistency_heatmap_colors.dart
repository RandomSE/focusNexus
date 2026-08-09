import 'package:flutter/material.dart';

/// Persisted consistency heatmap palette choice (display names for the picker).
enum ConsistencyPaletteId {
  coolTealDepth('cool_teal_depth', 'Cool Teal Depth'),
  softPurple('soft_purple', 'Soft Purple'),
  goldenHour('golden_hour', 'Golden Hour'),
  forestGreens('forest_greens', 'Forest Greens'),
  oceanBlues('ocean_blues', 'Ocean Blues'),
  monochromeGreyscale('monochrome_greyscale', 'Monochrome Greyscale');

  const ConsistencyPaletteId(this.storageValue, this.displayName);

  final String storageValue;
  final String displayName;

  static ConsistencyPaletteId parse(String? raw) {
    return ConsistencyPaletteId.values.firstWhere(
      (p) => p.storageValue == raw,
      orElse: () => ConsistencyPaletteId.coolTealDepth,
    );
  }
}

/// Continuous calm intensity ramp for one palette (stops at 1 / 5 / 10 / 25 / 50).
class ConsistencyPaletteRamp {
  const ConsistencyPaletteRamp({
    required this.zeroLight,
    required this.zeroDark,
    required this.lightStops,
    required this.darkStops,
    required this.futureHairlineLight,
    required this.futureHairlineDark,
  });

  final Color zeroLight;
  final Color zeroDark;
  final List<Color> lightStops;
  final List<Color> darkStops;
  final Color futureHairlineLight;
  final Color futureHairlineDark;

  Color zero({required bool isDark}) => isDark ? zeroDark : zeroLight;

  Color futureHairline({required bool isDark}) =>
      isDark ? futureHairlineDark : futureHairlineLight;
}

/// Discrete cell kinds and continuous intensity for the consistency grid.
abstract final class ConsistencyHeatmapColors {
  ConsistencyHeatmapColors._();

  static const int intensityCap = 50;
  static const List<int> stops = [1, 5, 10, 25, 50];

  static const coolTeal = ConsistencyPaletteRamp(
    zeroLight: Color(0xFFE8EEEE),
    zeroDark: Color(0xFF243030),
    lightStops: [
      Color(0xFFA8CCC8),
      Color(0xFF5AA8A0),
      Color(0xFF2A7870),
      Color(0xFF1F5E58),
      Color(0xFF164844),
    ],
    darkStops: [
      Color(0xFF3A6864),
      Color(0xFF4E9088),
      Color(0xFF6AB0A8),
      Color(0xFF8AC8C0),
      Color(0xFFA8DCD6),
    ],
    futureHairlineLight: Color(0xFFC5D0D0),
    futureHairlineDark: Color(0xFF3A4848),
  );

  static const softPurple = ConsistencyPaletteRamp(
    zeroLight: Color(0xFFEEECF4),
    zeroDark: Color(0xFF2A2438),
    lightStops: [
      Color(0xFFC4B8E0),
      Color(0xFF8A70C0),
      Color(0xFF5A3A9A),
      Color(0xFF452C78),
      Color(0xFF321F58),
    ],
    darkStops: [
      Color(0xFF4A3C6A),
      Color(0xFF6E58A0),
      Color(0xFF8A70C0),
      Color(0xFFA890D8),
      Color(0xFFC4B0EC),
    ],
    futureHairlineLight: Color(0xFFD4D0E0),
    futureHairlineDark: Color(0xFF3E3850),
  );

  static const goldenHour = ConsistencyPaletteRamp(
    zeroLight: Color(0xFFF4F0E8),
    zeroDark: Color(0xFF2E2A20),
    lightStops: [
      Color(0xFFE8D4A0),
      Color(0xFFC8A840),
      Color(0xFF8A7020),
      Color(0xFF6E5818),
      Color(0xFF524214),
    ],
    darkStops: [
      Color(0xFF6A5C38),
      Color(0xFFA08840),
      Color(0xFFC8A840),
      Color(0xFFE0C068),
      Color(0xFFF0D890),
    ],
    futureHairlineLight: Color(0xFFD8D2C4),
    futureHairlineDark: Color(0xFF484438),
  );

  static const forestGreens = ConsistencyPaletteRamp(
    zeroLight: Color(0xFFE8F4E8),
    zeroDark: Color(0xFF1E2A1E),
    lightStops: [
      Color(0xFFA8D4A0),
      Color(0xFF5AA870),
      Color(0xFF2A7030),
      Color(0xFF1F5424),
      Color(0xFF16401C),
    ],
    darkStops: [
      Color(0xFF3A6840),
      Color(0xFF4E9060),
      Color(0xFF6AB078),
      Color(0xFF8AC898),
      Color(0xFFA8D8B0),
    ],
    futureHairlineLight: Color(0xFFC8D8C8),
    futureHairlineDark: Color(0xFF384838),
  );

  static const oceanBlues = ConsistencyPaletteRamp(
    zeroLight: Color(0xFFE8F0F8),
    zeroDark: Color(0xFF1A2430),
    lightStops: [
      Color(0xFFA0C8E8),
      Color(0xFF5088C0),
      Color(0xFF204A8A),
      Color(0xFF183A6E),
      Color(0xFF102C54),
    ],
    darkStops: [
      Color(0xFF3A5C80),
      Color(0xFF5088C0),
      Color(0xFF70A0D0),
      Color(0xFF90B8E0),
      Color(0xFFB0D0F0),
    ],
    futureHairlineLight: Color(0xFFC8D4E0),
    futureHairlineDark: Color(0xFF384858),
  );

  static const monochromeGreyscale = ConsistencyPaletteRamp(
    zeroLight: Color(0xFFF4F4F4),
    zeroDark: Color(0xFF222222),
    lightStops: [
      Color(0xFFC8C8C8),
      Color(0xFF888888),
      Color(0xFF303030),
      Color(0xFF242424),
      Color(0xFF181818),
    ],
    darkStops: [
      Color(0xFF5A5A5A),
      Color(0xFF888888),
      Color(0xFFB0B0B0),
      Color(0xFFD0D0D0),
      Color(0xFFE8E8E8),
    ],
    futureHairlineLight: Color(0xFFD0D0D0),
    futureHairlineDark: Color(0xFF404040),
  );

  static ConsistencyPaletteRamp rampFor(ConsistencyPaletteId id) {
    return switch (id) {
      ConsistencyPaletteId.coolTealDepth => coolTeal,
      ConsistencyPaletteId.softPurple => softPurple,
      ConsistencyPaletteId.goldenHour => goldenHour,
      ConsistencyPaletteId.forestGreens => forestGreens,
      ConsistencyPaletteId.oceanBlues => oceanBlues,
      ConsistencyPaletteId.monochromeGreyscale => monochromeGreyscale,
    };
  }

  /// Normalized progress along the ramp in \[0, 1\], using [intensityCap].
  static double rampT(int count) {
    final c = count < 1 ? 1 : (count > intensityCap ? intensityCap : count);
    if (c <= stops.first) return 0;
    if (c >= stops.last) return 1;
    for (var i = 0; i < stops.length - 1; i++) {
      final a = stops[i];
      final b = stops[i + 1];
      if (c <= b) {
        final local = (c - a) / (b - a);
        return (i + local) / (stops.length - 1);
      }
    }
    return 1;
  }

  /// Continuous fill for days with at least one completion.
  static Color rampColor({
    required int count,
    required bool isDark,
    ConsistencyPaletteId palette = ConsistencyPaletteId.coolTealDepth,
  }) {
    final c = count < 1 ? 1 : (count > intensityCap ? intensityCap : count);
    final ramp = rampFor(palette);
    final colors = isDark ? ramp.darkStops : ramp.lightStops;
    if (c <= stops.first) return colors.first;
    if (c >= stops.last) return colors.last;
    for (var i = 0; i < stops.length - 1; i++) {
      final a = stops[i];
      final b = stops[i + 1];
      if (c <= b) {
        final t = (c - a) / (b - a);
        return Color.lerp(colors[i], colors[i + 1], t)!;
      }
    }
    return colors.last;
  }

  static Color zeroColor({
    required bool isDark,
    ConsistencyPaletteId palette = ConsistencyPaletteId.coolTealDepth,
  }) =>
      rampFor(palette).zero(isDark: isDark);

  static Color futureHairline({
    required bool isDark,
    ConsistencyPaletteId palette = ConsistencyPaletteId.coolTealDepth,
  }) =>
      rampFor(palette).futureHairline(isDark: isDark);

  /// Readable day-number colour on a filled cell.
  static Color dayNumberColor(Color fill) {
    return fill.computeLuminance() > 0.42
        ? const Color(0xFF1D2730)
        : const Color(0xFFF5F7F6);
  }
}

/// How a calendar cell should be painted.
enum ConsistencyCellKind {
  /// Day after today, or today with zero completions.
  futureEmpty,

  /// Past day with zero completions (calm near-white, not punitive).
  missed,

  /// At least one completion; use continuous ramp.
  active,
}

/// Dashboard vs explorer sizing.
enum ConsistencyCalendarDensity {
  /// ~25% viewport target on Dashboard.
  compact,

  /// Comfortable explorer / detail size.
  comfortable,
}

abstract final class ConsistencyCellSemantics {
  ConsistencyCellSemantics._();

  static ConsistencyCellKind kindFor({
    required DateTime day,
    required DateTime today,
    required int count,
  }) {
    final d = DateTime(day.year, day.month, day.day);
    final t = DateTime(today.year, today.month, today.day);
    // Future days stay empty (not a "0 goals" day yet).
    if (d.isAfter(t)) return ConsistencyCellKind.futureEmpty;
    // Any calendar day that has arrived with 0 completions uses palette zero.
    if (count <= 0) return ConsistencyCellKind.missed;
    return ConsistencyCellKind.active;
  }

  static Color fillFor({
    required ConsistencyCellKind kind,
    required int count,
    required bool isDark,
    ConsistencyPaletteId palette = ConsistencyPaletteId.coolTealDepth,
  }) {
    return switch (kind) {
      ConsistencyCellKind.futureEmpty => Colors.transparent,
      ConsistencyCellKind.missed =>
        // Palette zero only (never theme secondary / text colours).
        ConsistencyHeatmapColors.zeroColor(isDark: isDark, palette: palette),
      ConsistencyCellKind.active => ConsistencyHeatmapColors.rampColor(
          count: count,
          isDark: isDark,
          palette: palette,
        ),
    };
  }

  static Color borderFor({
    required ConsistencyCellKind kind,
    required bool isDark,
    ConsistencyPaletteId palette = ConsistencyPaletteId.coolTealDepth,
  }) {
    return switch (kind) {
      ConsistencyCellKind.futureEmpty => ConsistencyHeatmapColors.futureHairline(
          isDark: isDark,
          palette: palette,
        ),
      ConsistencyCellKind.missed => ConsistencyHeatmapColors.zeroColor(
          isDark: isDark,
          palette: palette,
        ),
      ConsistencyCellKind.active => Colors.transparent,
    };
  }
}
