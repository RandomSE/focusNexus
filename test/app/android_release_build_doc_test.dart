import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ANDROID_RELEASE_BUILD.md documents obfuscated Play AAB recipe', () {
    final doc = File('docs/ANDROID_RELEASE_BUILD.md').readAsStringSync();
    expect(
      doc,
      contains(
        'flutter build appbundle --release --obfuscate '
        '--split-debug-info=build/debug-info',
      ),
    );
    expect(doc, contains('--obfuscate'));
    expect(doc, contains('--split-debug-info=build/debug-info'));
    expect(doc, contains('isMinifyEnabled'));
    expect(doc, contains('android/SIGNING.md'));
    expect(doc, contains('build/debug-info'));
    expect(doc, contains('app-release.aab'));
    expect(doc, contains('keep.xml'));
    expect(doc, contains('ic_notification'));
    expect(doc, contains('Gson'));
  });
}
