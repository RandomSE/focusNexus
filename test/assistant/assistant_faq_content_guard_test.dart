import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_faq_ui_references.dart';

void main() {
  test('FAQ-referenced UI labels still exist in lib/', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final libSources = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    final missing = <String>[];
    for (final label in assistantFaqRequiredUiStrings) {
      if (!libSources.contains(label)) {
        missing.add(label);
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'FAQ references UI labels missing from lib/: ${missing.join(', ')}',
    );
  });
}
