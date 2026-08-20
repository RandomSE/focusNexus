import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/legal/legal_documents.dart';

void main() {
  late String doc;

  setUpAll(() {
    doc = File('docs/PLAY_STORE_RELEASE_PROCESS.md').readAsStringSync();
  });

  test('PLAY_STORE_RELEASE_PROCESS.md locks Play identity and AAB recipe', () {
    expect(doc, contains('com.randomSE.FocusNexus.FocusNexus'));
    expect(doc, contains('1.0.0+1'));
    expect(doc, contains(kPrivacyPolicyPublicUrl));
    expect(
      doc,
      contains(
        'flutter build appbundle --release --obfuscate '
        '--split-debug-info=build/debug-info',
      ),
    );
    expect(doc, contains('android/SIGNING.md'));
    expect(doc, contains('app-release.aab'));
  });

  test('PLAY_STORE_RELEASE_PROCESS.md covers Console gates and closed testing',
      () {
    expect(doc, contains('PLAY_CONSOLE_OPERATOR_FORMS.md'));
    expect(doc, contains('12 testers'));
    expect(doc, contains('14'));
    expect(doc, contains('Play App Signing'));
    expect(doc, contains('Do not use the Discord invite'));
    expect(doc, contains('SCHEDULE_EXACT_ALARM'));
  });
}
