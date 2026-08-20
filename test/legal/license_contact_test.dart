import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/legal/legal_documents.dart';

void main() {
  test('LICENSE Contact points to canonical Discord invite', () {
    final license = File('LICENSE').readAsStringSync();
    expect(license, contains('## 10. Contact'));
    expect(license, contains(kLegalContactDiscordUrl));
    expect(
      license,
      contains('FocusNexus Discord: $kLegalContactDiscordUrl'),
    );
    expect(license, isNot(contains('channels published')));
  });
}
