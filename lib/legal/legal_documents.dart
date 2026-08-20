/// In-app legal document catalog for FocusNexus.
///
/// Bodies mirror `legal/*.md` at the repository root.
library;

/// Shared version for in-app EULA and Privacy Policy bodies (and acceptance gate).
const String kLegalDocsVersion = '1.0.0';

/// Alias kept for call-site clarity; prefer [kLegalDocsVersion].
const String kEulaVersion = kLegalDocsVersion;

const String kLegalOwnerName = 'Joshua Grace';

const String kAppTrademark = 'FocusNexus';

/// Canonical FocusNexus Discord invite for legal / privacy contact.
const String kLegalContactDiscordUrl = 'https://discord.gg/aHUgcbdvr';

/// Public HTTPS Privacy Policy page for Play Console / store listing.
/// Discord is contact only; this URL is the store-listing Privacy Policy field.
const String kPrivacyPolicyPublicUrl =
    'https://sparkling-gumdrop-1d2c86.netlify.app';

/// Discord brand blurple for secondary Join Discord controls.
const int kDiscordBrandBlueValue = 0xFF5865F2;

/// In-app catalog (EULA, Privacy, IP). Trademark notice remains docs-only
/// under `legal/TRADEMARK.md` and is not presented as a viewer screen.
enum LegalDocumentId {
  eula,
  privacyPolicy,
  intellectualProperty,
}

extension LegalDocumentIdX on LegalDocumentId {
  String get storageValue => name;

  String get title => switch (this) {
        LegalDocumentId.eula => 'End User License Agreement',
        LegalDocumentId.privacyPolicy => 'Privacy Policy',
        LegalDocumentId.intellectualProperty =>
          'Intellectual Property',
      };

  String get body => switch (this) {
        LegalDocumentId.eula => LegalDocumentBodies.eula,
        LegalDocumentId.privacyPolicy => LegalDocumentBodies.privacyPolicy,
        LegalDocumentId.intellectualProperty =>
          LegalDocumentBodies.intellectualProperty,
      };

  static LegalDocumentId? tryParse(Object? raw) {
    if (raw is LegalDocumentId) return raw;
    if (raw is String) {
      for (final id in LegalDocumentId.values) {
        if (id.name == raw || id.storageValue == raw) return id;
      }
    }
    return null;
  }
}

/// Canonical in-app text (ASCII punctuation only).
abstract final class LegalDocumentBodies {
  LegalDocumentBodies._();

  static const String eula = '''
FocusNexus End User License Agreement (EULA)
Version $kLegalDocsVersion
(c) 2025-2026 $kLegalOwnerName

IMPORTANT: Please read this End User License Agreement carefully before creating an account or using FocusNexus. By checking "I agree" and continuing, you acknowledge that you have read, understood, and agree to be bound by this EULA.

1. Parties and ownership
FocusNexus (the "App") is owned exclusively by $kLegalOwnerName ("Owner"). All rights, title, and interest in and to the App, including source code, binaries, assets, branding, documentation, and related materials, belong solely to the Owner and are protected under applicable intellectual property laws.

2. Limited license grant
Subject to your acceptance of this EULA and continued compliance, Owner grants you a personal, limited, non-exclusive, non-transferable, non-sublicensable, revocable license to install and use the App on devices you own or control, solely for your personal, non-commercial use.

3. Restrictions
Except with Owner's prior explicit written permission, you may not:
(a) copy, reproduce, redistribute, publish, or publicly display the App or any substantial portion of it;
(b) modify, adapt, translate, or create derivative works;
(c) sell, rent, lease, sublicense, or commercially exploit the App;
(d) reverse engineer, decompile, or disassemble the App except to the limited extent that applicable law expressly prohibits such restriction;
(e) remove or obscure proprietary notices, trademarks (including FocusNexus), or copyright notices;
(f) use the App to build a competing product using Owner's confidential or proprietary materials.

4. Account and acceptance
Creating an account (device registration / setup) requires acceptance of this EULA. Owner may update this EULA from time to time. Continued use after a version change may require re-acceptance of the then-current version. If you do not agree, you must stop using the App and delete your account/data via the in-app controls.

5. Local data
The App is designed to store your goals, settings, and progress on your device. See the Privacy Policy for details. You are responsible for device security and backups you choose to make outside the App.

6. Disclaimer of warranties
THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. The App is a productivity aid and is not medical, legal, or financial advice.

7. Limitation of liability
TO THE MAXIMUM EXTENT PERMITTED BY LAW, OWNER SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF DATA, PROFITS, OR BUSINESS, ARISING FROM YOUR USE OF THE APP. OWNER'S TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM (OR ZERO IF THE APP WAS PROVIDED FREE OF CHARGE). NOTHING IN THIS EULA EXCLUDES OR LIMITS LIABILITY THAT CANNOT LAWFULLY BE EXCLUDED OR LIMITED UNDER THE CONSUMER PROTECTION ACT 68 OF 2008 OR OTHER APPLICABLE SOUTH AFRICAN LAW.

8. Termination
This license terminates automatically if you breach this EULA. Upon termination you must cease all use and delete the App and copies. Sections that by their nature should survive (ownership, restrictions, disclaimers, liability limits) will survive.

9. Governing law
This EULA is governed by the laws of the Republic of South Africa, without regard to conflict-of-law rules. The courts of South Africa have exclusive jurisdiction over any dispute arising from this EULA, subject to any mandatory consumer protections that apply in your place of residence.

10. Contact
For permission requests or legal notices, contact the Owner via the FocusNexus Discord: $kLegalContactDiscordUrl

By accepting, you confirm you are legally capable of entering this agreement and that you agree to the Privacy Policy and any Intellectual Property notice presented with this EULA.
''';

  static const String privacyPolicy = '''
FocusNexus Privacy Policy
Version $kLegalDocsVersion
(c) 2025-2026 $kLegalOwnerName

1. Summary
FocusNexus is designed as a local-first app. Your goals, settings, progress, and related content stay on your device. FocusNexus does not upload your goals, settings, or progress to Owner servers for advertising or sale.

2. Data we store on your device
Depending on features you enable, the App may store locally:
- registration and onboarding preferences;
- goals, templates, and completion history;
- appearance, accessibility, and customization settings;
- reward progress (points, garden, mini-games, achievements);
- notification preferences and schedule-related markers;
- EULA acceptance status and version;
- optional custom affirmation or motivator packs you create.

3. Notifications
If you enable notifications, the App schedules local notifications on your device (for example goal reminders, affirmations, or streak nudges). This requires system notification permission. The App does not use remote push / APNs / FCM for these local reminders.

4. No sale of personal data
Owner does not sell your personal data and does not use your in-app content for third-party advertising.

5. Sharing
Nothing you enter leaves the App unless you share it yourself outside the App (for example screenshots or OS-level sharing).

6. Local storage and device backups
Preferences and progress are stored on your device using platform secure storage. Where configured, Android cloud backup of FocusNexus app data is disabled. Uninstalling the App, clearing app data, or some device restores after a wipe can permanently remove your local FocusNexus data. The App does not provide import or export of your data in this build.

7. Account deletion
Using "Clear preferences and delete account" (or equivalent) in Settings wipes local app data stored by FocusNexus on that device and returns you to setup.

8. Children
The App is not directed at children under 13 (or the minimum age required in your jurisdiction). Do not use the App if you are below that age.

9. Not medical advice
FocusNexus is a productivity and accessibility aid. It is not medical advice, diagnosis, therapy, or a treatment for ADHD or any other condition.

10. Changes
We may update this Privacy Policy. Material changes may be presented in-app. The version shown in the App is the version that applies.

11. Governing law
This Privacy Policy is governed by the laws of the Republic of South Africa, without regard to conflict-of-law rules.

12. Contact
For privacy questions, contact the Owner via the FocusNexus Discord: $kLegalContactDiscordUrl
A public HTTPS copy of this Privacy Policy is published at: $kPrivacyPolicyPublicUrl
''';

  static const String intellectualProperty = '''
FocusNexus Intellectual Property Notice
(c) 2025-2026 $kLegalOwnerName. All rights reserved.

1. Ownership
FocusNexus, including all source code, object code, designs, graphics, audio, text, trademarks, trade dress, and documentation, is the exclusive property of $kLegalOwnerName. All rights reserved.

2. Trademarks
FocusNexus and associated logos are used as trademarks / proprietary designations of $kLegalOwnerName. No license to use these marks is granted except as expressly stated in writing by Owner. Unauthorized use of the FocusNexus name, logos, or confusingly similar branding is prohibited.

3. Portfolio viewing
Third parties who have visibility of the repository or materials may view them for portfolio evaluation or hiring assessment only. Viewing does not grant any right to copy, fork for use, reproduce, modify, redistribute, sell, or create derivative works.

4. Required notice format
Where attribution is authorized in writing, use:
`(c) 2025-2026 $kLegalOwnerName. All rights reserved.`

5. Enforcement
Any unauthorized replication, reproduction, sale, alteration, reverse engineering, or commercial use is a violation of Owner's rights and the project LICENSE. Permission must be obtained in explicit written form from $kLegalOwnerName. This notice is governed by the laws of the Republic of South Africa.

6. Related documents
See the repository LICENSE, legal/TRADEMARK.md, and the End User License Agreement presented in the App.
''';
}