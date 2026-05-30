import 'sandbox_entity.dart';

/// How bulk selection adds items in multi-select mode.
enum BulkSelectStyle {
  /// Tap individual items to toggle them in the selection set.
  tap,

  /// Drag a rectangle to select every item whose bounds overlap it.
  area,
}

/// Focus + bulk selection for progressive visual sandboxes.
class SandboxSelectionState {
  String? focusPrimaryId;
  String? focusDecorId;
  bool multiMode = false;
  BulkSelectStyle bulkSelectStyle = BulkSelectStyle.tap;
  final Set<String> bulkPrimary = {};
  final Set<String> bulkDecor = {};

  bool get hasFocus => focusPrimaryId != null || focusDecorId != null;

  int get bulkCount => bulkPrimary.length + bulkDecor.length;

  void setMultiMode(bool value) {
    multiMode = value;
    if (value) {
      clearFocus();
    } else {
      bulkPrimary.clear();
      bulkDecor.clear();
      bulkSelectStyle = BulkSelectStyle.tap;
    }
  }

  void setBulkSelectStyle(BulkSelectStyle style) {
    bulkSelectStyle = style;
  }

  /// Replaces bulk selection with every id in [primaryIds] and [decorIds].
  void replaceBulkSelection({
    required Set<String> primaryIds,
    required Set<String> decorIds,
  }) {
    bulkPrimary
      ..clear()
      ..addAll(primaryIds);
    bulkDecor
      ..clear()
      ..addAll(decorIds);
  }

  void clearFocus() {
    focusPrimaryId = null;
    focusDecorId = null;
  }

  void clearAll() {
    clearFocus();
    bulkPrimary.clear();
    bulkDecor.clear();
  }

  /// Clears selection when the user taps empty sand.
  void deselectOnEmptyTap() {
    if (multiMode) {
      bulkPrimary.clear();
      bulkDecor.clear();
      return;
    }
    clearFocus();
  }

  void applyPick(SandboxEntityRef pick) {
    if (pick.isPrimary) {
      focusPrimaryId = pick.id;
      focusDecorId = null;
    } else {
      focusDecorId = pick.id;
      focusPrimaryId = null;
    }
  }

  void toggleBulk(SandboxEntityRef pick) {
    if (pick.isPrimary) {
      if (bulkPrimary.contains(pick.id)) {
        bulkPrimary.remove(pick.id);
      } else {
        bulkPrimary.add(pick.id);
      }
    } else {
      if (bulkDecor.contains(pick.id)) {
        bulkDecor.remove(pick.id);
      } else {
        bulkDecor.add(pick.id);
      }
    }
  }

  bool isSelected(SandboxEntityRef ref) {
    if (multiMode) {
      return ref.isPrimary
          ? bulkPrimary.contains(ref.id)
          : bulkDecor.contains(ref.id);
    }
    return ref.isPrimary
        ? focusPrimaryId == ref.id
        : focusDecorId == ref.id;
  }

  bool isPrimarySelected(String id) {
    if (multiMode) return bulkPrimary.contains(id);
    return focusPrimaryId == id;
  }

  bool isDecorSelected(String id) {
    if (multiMode) return bulkDecor.contains(id);
    return focusDecorId == id;
  }
}
