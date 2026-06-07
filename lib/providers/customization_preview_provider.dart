import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'customization_preview_provider.g.dart';

class CustomizationPreviewState {
  const CustomizationPreviewState({
    required this.previewPrimary,
    required this.previewSecondary,
    this.hasUnsavedChanges = false,
  });

  final Color previewPrimary;
  final Color previewSecondary;
  final bool hasUnsavedChanges;

  CustomizationPreviewState copyWith({
    Color? previewPrimary,
    Color? previewSecondary,
    bool? hasUnsavedChanges,
  }) {
    return CustomizationPreviewState(
      previewPrimary: previewPrimary ?? this.previewPrimary,
      previewSecondary: previewSecondary ?? this.previewSecondary,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

@riverpod
class CustomizationPreview extends _$CustomizationPreview {
  @override
  CustomizationPreviewState build() {
    return const CustomizationPreviewState(
      previewPrimary: Colors.black87,
      previewSecondary: Color(0xFFF2EFE6),
    );
  }

  void initFromBundle(Color primary, Color secondary) {
    state = CustomizationPreviewState(
      previewPrimary: primary,
      previewSecondary: secondary,
    );
  }

  void selectColor({
    required Color color,
    required bool isPrimary,
    required Color savedPrimary,
    required Color savedSecondary,
  }) {
    var primary = state.previewPrimary;
    var secondary = state.previewSecondary;
    if (!state.hasUnsavedChanges) {
      primary = savedPrimary;
      secondary = savedSecondary;
    }
    if (isPrimary) {
      if (color.toARGB32() == secondary.toARGB32()) return;
      primary = color;
    } else {
      if (color.toARGB32() == primary.toARGB32()) return;
      secondary = color;
    }
    state = CustomizationPreviewState(
      previewPrimary: primary,
      previewSecondary: secondary,
      hasUnsavedChanges:
          primary != savedPrimary || secondary != savedSecondary,
    );
  }

  void revertToSaved() {
    state = state.copyWith(hasUnsavedChanges: false);
  }

  void revertToDefaults(Color primary, Color secondary) {
    state = CustomizationPreviewState(
      previewPrimary: primary,
      previewSecondary: secondary,
      hasUnsavedChanges: true,
    );
  }

  void markSaved() {
    state = state.copyWith(hasUnsavedChanges: false);
  }
}
