import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('master push builds an AAB and emails it after the quality gate', () {
    final yaml = File('.github/workflows/ci.yml').readAsStringSync();

    expect(yaml, contains('release-aab:'));
    expect(yaml, contains('needs: [test-merge-gate]'));
    expect(yaml, contains("github.ref == 'refs/heads/master'"));
    expect(yaml, contains('flutter build appbundle --release'));
    expect(yaml, contains('actions/upload-artifact@v4'));
    expect(yaml, contains('app-release-aab'));
    expect(yaml, contains('dawidd6/action-send-mail@v3'));
    expect(yaml, contains('secrets.RELEASE_EMAIL_TO'));
    expect(yaml, contains('secrets.SMTP_SERVER'));
    expect(yaml, contains('secrets.SMTP_USERNAME'));
    expect(yaml, contains('secrets.SMTP_PASSWORD'));
    expect(yaml, contains('secrets.SMTP_PORT'));
    expect(yaml, contains('secrets.SMTP_FROM'));
    expect(yaml, contains('secrets.ANDROID_KEYSTORE_BASE64'));
    expect(yaml, contains('secrets.ANDROID_STORE_PASSWORD'));
    expect(yaml, contains('secrets.ANDROID_KEY_PASSWORD'));
    expect(yaml, contains('secrets.ANDROID_KEY_ALIAS'));
    expect(
      yaml,
      contains('KEYSTORE_B64: \${{ secrets.ANDROID_KEYSTORE_BASE64 }}'),
    );
    expect(yaml, contains("printf 'storePassword=%s\\n"));
    expect(yaml, contains("tr -d '[:space:]'"));
    expect(
      yaml.contains('<<EOF'),
      isFalse,
      reason: 'unquoted heredocs re-expand dollar signs inside secret values',
    );
    expect(
      yaml.contains('20000000'),
      isTrue,
      reason: 'bundles above 20 MB are linked, not attached',
    );
  });
}
