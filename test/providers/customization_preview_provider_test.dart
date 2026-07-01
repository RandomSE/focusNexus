import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/customization_preview_provider.dart';

void main() {
  test('selectColor rejects matching primary and secondary', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(customizationPreviewProvider.notifier);

    notifier.initFromBundle(Colors.black87, const Color(0xFFF2EFE6));
    notifier.selectColor(
      color: const Color(0xFFF2EFE6),
      isPrimary: true,
      savedPrimary: Colors.black87,
      savedSecondary: const Color(0xFFF2EFE6),
    );

    expect(
      container.read(customizationPreviewProvider).previewPrimary,
      Colors.black87,
    );

    notifier.selectColor(
      color: Colors.black87,
      isPrimary: false,
      savedPrimary: Colors.black87,
      savedSecondary: const Color(0xFFF2EFE6),
    );

    expect(
      container.read(customizationPreviewProvider).previewSecondary,
      const Color(0xFFF2EFE6),
    );
  });
}
