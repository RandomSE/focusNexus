import 'dart:io';

import 'package:focusNexus/legal/legal_documents.dart';

/// Helpers for keeping `legal/*.md` and [LegalDocumentBodies] aligned.
abstract final class LegalDocumentParity {
  LegalDocumentParity._();

  static const relativePaths = <LegalDocumentId, String>{
    LegalDocumentId.eula: 'legal/EULA.md',
    LegalDocumentId.privacyPolicy: 'legal/PRIVACY_POLICY.md',
    LegalDocumentId.intellectualProperty: 'legal/INTELLECTUAL_PROPERTY.md',
  };

  /// Strips markdown headings, normalizes dashes/whitespace for comparison.
  static String normalize(String raw) {
    var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    text = text.replaceAll('\u2013', '-').replaceAll('\u2014', '-');
    text = text.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  static String bodyFor(LegalDocumentId id) => switch (id) {
        LegalDocumentId.eula => LegalDocumentBodies.eula,
        LegalDocumentId.privacyPolicy => LegalDocumentBodies.privacyPolicy,
        LegalDocumentId.intellectualProperty =>
          LegalDocumentBodies.intellectualProperty,
      };

  static String readMarkdown(LegalDocumentId id, {Directory? projectRoot}) {
    final root = projectRoot ?? Directory.current;
    final relative = relativePaths[id]!;
    return File('${root.path}${Platform.pathSeparator}$relative')
        .readAsStringSync();
  }
}
