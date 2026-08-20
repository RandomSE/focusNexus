import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/legal/legal_document_parity.dart';
import 'package:focusNexus/legal/legal_documents.dart';

void main() {
  test('in-app legal bodies match normalized legal/*.md sources', () {
    final root = _projectRoot();
    for (final id in LegalDocumentId.values) {
      final md = LegalDocumentParity.readMarkdown(id, projectRoot: root);
      final dartBody = LegalDocumentParity.bodyFor(id);
      expect(
        LegalDocumentParity.normalize(dartBody),
        LegalDocumentParity.normalize(md),
        reason: '${LegalDocumentParity.relativePaths[id]} drifted from '
            'LegalDocumentBodies for $id',
      );
    }
  });
}

Directory _projectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final marker = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    if (marker.existsSync()) return dir;
    dir = dir.parent;
  }
  fail('Could not locate project root (pubspec.yaml) from ${Directory.current.path}');
}
