import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/decor_catalog.dart';
import 'package:focusNexus/progressive_visuals/visual_theme_id.dart';

void main() {
  test('decorCatalogFor returns zen entries only for zenGarden', () {
    expect(decorCatalogFor(VisualThemeId.zenGarden), isNotEmpty);
  });

  test('decorEntryByKind finds catalog entry', () {
    final entry = decorEntryByKind('zen.moss_rock');
    expect(entry, isNotNull);
    expect(entry!.pointCost, 50);
    expect(entry.themeId, VisualThemeId.zenGarden);
  });

  test('decorPrice returns null for unknown kind', () {
    expect(decorPrice('missing.kind'), isNull);
    expect(decorPrice('zen.koi_pond'), 140);
  });
}
