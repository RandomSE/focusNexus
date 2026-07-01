import 'package:flutter/material.dart';

/// Shared semantics helpers for primary app screens.
class ScreenSemantics {
  ScreenSemantics._();

  /// Status line announced as a single label (avoids fragmented character reads).
  static Widget statusText(
    String label,
    TextStyle style, {
    TextAlign? textAlign,
    FontWeight? fontWeight,
  }) {
    final resolvedStyle =
        fontWeight == null ? style : style.copyWith(fontWeight: fontWeight);
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Text(
          label,
          style: resolvedStyle,
          textAlign: textAlign,
        ),
      ),
    );
  }

  /// Section heading for screen-reader navigation landmarks.
  static Widget sectionHeader(String title, TextStyle style) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: style.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
