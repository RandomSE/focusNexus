import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/legal/legal_documents.dart';

void main() {
  late Directory root;

  setUpAll(() {
    root = _projectRoot();
  });

  String readRelative(String relative) {
    return File('${root.path}${Platform.pathSeparator}$relative')
        .readAsStringSync();
  }

  test('in-app Privacy Policy cites the hosted HTTPS copy', () {
    expect(
      LegalDocumentBodies.privacyPolicy,
      contains(
        'A public HTTPS copy of this Privacy Policy is published at: '
        '$kPrivacyPolicyPublicUrl',
      ),
    );
    expect(
      LegalDocumentBodies.privacyPolicy,
      contains('FocusNexus Discord: $kLegalContactDiscordUrl'),
    );
  });

  test('canonical markdown cites the hosted HTTPS copy', () {
    final md = readRelative('legal/PRIVACY_POLICY.md');
    expect(md, contains(kPrivacyPolicyPublicUrl));
    expect(
      md,
      contains(
        'A public HTTPS copy of this Privacy Policy is published at: '
        '$kPrivacyPolicyPublicUrl',
      ),
    );
    expect(md, contains(kLegalContactDiscordUrl));
  });

  test('HTML mirror links the hosted HTTPS copy', () {
    final html = readRelative('docs/privacy/index.html');
    expect(html, contains('href="$kPrivacyPolicyPublicUrl"'));
    expect(html, contains(kPrivacyPolicyPublicUrl));
    expect(html, contains('href="$kLegalContactDiscordUrl"'));
  });

  test('hosting guide names the Play Console paste URL', () {
    final hosting = readRelative('docs/PRIVACY_POLICY_HOSTING.md');
    expect(hosting, contains(kPrivacyPolicyPublicUrl));
    expect(hosting, isNot(contains('Paste the Discord')));
    expect(
      hosting,
      contains('Do **not** use the Discord invite link as the Play Console'),
    );
  });

  test('store listing docs include the Play Console Privacy Policy URL', () {
    final listing = readRelative('docs/STORE_LISTING_DISCLAIMERS.md');
    expect(listing, contains(kPrivacyPolicyPublicUrl));
    expect(listing, contains('Privacy Policy URL'));
    expect(listing, contains('Do not use the Discord invite'));
  });
}

Directory _projectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final marker = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    if (marker.existsSync()) return dir;
    dir = dir.parent;
  }
  fail(
    'Could not locate project root (pubspec.yaml) from ${Directory.current.path}',
  );
}
