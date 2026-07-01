import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

void main() {
  test('decorCatalogFor returns zen entries for zenGarden', () {
    final entries = decorCatalogFor(VisualThemeId.zenGarden);
    expect(entries, isNotEmpty);
    expect(entries.every((e) => e.themeId == VisualThemeId.zenGarden), isTrue);
  });

  test('decorEntryByKind resolves known decor id', () {
    final entry = decorEntryByKind('zen.koi_pond');
    expect(entry, isNotNull);
    expect(entry!.pointCost, 140);
    expect(decorPrice('zen.koi_pond'), 140);
  });

  test('decorEntryByKind returns null for unknown kind', () {
    expect(decorEntryByKind('unknown.decor'), isNull);
    expect(decorPrice('unknown.decor'), isNull);
  });
}
