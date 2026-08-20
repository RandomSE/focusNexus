import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/legal/legal_documents.dart';

void main() {
  test('legal docs version is pinned', () {
    expect(kLegalDocsVersion, '1.0.0');
    expect(kEulaVersion, kLegalDocsVersion);
  });

  test('each document has title and non-empty body', () {
    for (final id in LegalDocumentId.values) {
      expect(id.title, isNotEmpty);
      expect(id.body.trim(), isNotEmpty);
      expect(id.body, contains('Joshua Grace'));
      expect(id.body.toUpperCase(), isNot(contains('IRONCLAD')));
    }
  });

  test('IP notice covers FocusNexus ownership without IRONCLAD', () {
    final body = LegalDocumentId.intellectualProperty.body;
    expect(body, contains('FocusNexus'));
    expect(body, contains('Joshua Grace'));
    expect(body.toUpperCase(), isNot(contains('IRONCLAD')));
    expect(LegalDocumentId.intellectualProperty.title, 'Intellectual Property');
  });

  test('tryParse accepts enum name strings', () {
    expect(
      LegalDocumentIdX.tryParse('privacyPolicy'),
      LegalDocumentId.privacyPolicy,
    );
    expect(LegalDocumentIdX.tryParse('unknown'), isNull);
  });

  test('Discord contact URL constant is canonical invite', () {
    expect(kLegalContactDiscordUrl, 'https://discord.gg/aHUgcbdvr');
  });

  test('hosted Privacy Policy URL is public HTTPS and not Discord', () {
    expect(
      kPrivacyPolicyPublicUrl,
      'https://sparkling-gumdrop-1d2c86.netlify.app',
    );
    final uri = Uri.parse(kPrivacyPolicyPublicUrl);
    expect(uri.scheme, 'https');
    expect(uri.host, isNot(contains('discord')));
    expect(kPrivacyPolicyPublicUrl, isNot(contains('discord.gg')));
  });

  test('EULA and Privacy Contact sections point to Discord invite', () {
    expect(
      LegalDocumentBodies.eula,
      contains('FocusNexus Discord: $kLegalContactDiscordUrl'),
    );
    expect(
      LegalDocumentBodies.privacyPolicy,
      contains('FocusNexus Discord: $kLegalContactDiscordUrl'),
    );
    expect(LegalDocumentBodies.eula, isNot(contains('channels published')));
    expect(
      LegalDocumentBodies.privacyPolicy,
      isNot(contains('channels published')),
    );
  });

  test('Privacy Sharing clause does not imply in-app export', () {
    expect(
      LegalDocumentBodies.privacyPolicy,
      isNot(contains('exports you initiate')),
    );
    expect(LegalDocumentBodies.privacyPolicy, contains('screenshots'));
    expect(LegalDocumentBodies.privacyPolicy, contains('OS-level sharing'));
  });

  test('Privacy documents backup limits and non-medical disclaimer', () {
    expect(
      LegalDocumentBodies.privacyPolicy,
      contains('Local storage and device backups'),
    );
    expect(
      LegalDocumentBodies.privacyPolicy,
      contains('not medical advice'),
    );
    expect(
      LegalDocumentBodies.privacyPolicy,
      contains('does not provide import or export'),
    );
  });
}
