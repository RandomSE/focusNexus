import 'package:flutter/material.dart';

/// Runs an appearance-related settings write, closes open menus, and waits for
/// the next frame so controls rebuild once with the final theme.
Future<void> runAppearanceChange(
  State state,
  void Function(void Function()) setState,
  Future<void> Function() apply,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  setState(() {});
  await Future<void>.delayed(Duration.zero);
  await apply();
  await WidgetsBinding.instance.endOfFrame;
  if (!state.mounted) return;
}
