import 'package:flutter/material.dart';

import 'color_math.dart';
import 'mutation_kind.dart';

int _colorToArgb32(Color c) =>
    (c.alpha << 24) | (c.red << 16) | (c.green << 8) | c.blue;

/// Flutter-facing helpers; keep domain logic free of this file for fast tests.
Color applyMutationTint({
  required Color base,
  required MutationKind? mutation,
}) {
  if (mutation == null) {
    return base;
  }
  switch (mutation) {
    case MutationKind.invertedColors:
      return Color(invertArgb32(_colorToArgb32(base)));
  }
}
