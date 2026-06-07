import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs an appearance-related settings write, closes open menus, and waits for
/// the next frame so controls rebuild once with the final theme.
Future<void> runAppearanceChange(
  WidgetRef ref,
  Future<void> Function() apply,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
  await apply();
  await WidgetsBinding.instance.endOfFrame;
}
