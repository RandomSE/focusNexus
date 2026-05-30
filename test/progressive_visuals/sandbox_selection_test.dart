import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/sandbox_entity.dart';
import 'package:focusNexus/progressive_visuals/sandbox_selection.dart';

void main() {
  group('SandboxSelectionState', () {
    test('applyPick focuses one entity kind at a time', () {
      final s = SandboxSelectionState();
      s.applyPick(const SandboxEntityRef(id: 'p1', kind: SandboxEntityKind.primary));
      expect(s.focusPrimaryId, 'p1');
      expect(s.focusDecorId, isNull);

      s.applyPick(const SandboxEntityRef(id: 'd1', kind: SandboxEntityKind.decoration));
      expect(s.focusDecorId, 'd1');
      expect(s.focusPrimaryId, isNull);
    });

    test('deselectOnEmptyTap clears focus in single mode', () {
      final s = SandboxSelectionState()
        ..focusPrimaryId = 'p1';
      s.deselectOnEmptyTap();
      expect(s.hasFocus, isFalse);
    });

    test('deselectOnEmptyTap clears bulk sets in multi mode', () {
      final s = SandboxSelectionState()
        ..multiMode = true
        ..bulkPrimary.add('p1')
        ..bulkDecor.add('d1');
      s.deselectOnEmptyTap();
      expect(s.bulkCount, 0);
    });

    test('setMultiMode clears opposing selection mode', () {
      final s = SandboxSelectionState()
        ..focusPrimaryId = 'p1';
      s.setMultiMode(true);
      expect(s.multiMode, isTrue);
      expect(s.hasFocus, isFalse);

      s.bulkPrimary.add('p2');
      s.setMultiMode(false);
      expect(s.multiMode, isFalse);
      expect(s.bulkCount, 0);
    });

    test('toggleBulk adds and removes ids', () {
      final s = SandboxSelectionState()..multiMode = true;
      const pick = SandboxEntityRef(id: 'p1', kind: SandboxEntityKind.primary);
      s.toggleBulk(pick);
      expect(s.isSelected(pick), isTrue);
      s.toggleBulk(pick);
      expect(s.isSelected(pick), isFalse);
    });

    test('replaceBulkSelection replaces prior bulk ids', () {
      final s = SandboxSelectionState()
        ..multiMode = true
        ..bulkPrimary.add('old');
      s.replaceBulkSelection(primaryIds: {'a', 'b'}, decorIds: {'d1'});
      expect(s.bulkPrimary, {'a', 'b'});
      expect(s.bulkDecor, {'d1'});
    });

    test('setMultiMode resets bulk select style to tap', () {
      final s = SandboxSelectionState()
        ..multiMode = true
        ..bulkSelectStyle = BulkSelectStyle.area;
      s.setMultiMode(false);
      expect(s.bulkSelectStyle, BulkSelectStyle.tap);
    });
  });
}
