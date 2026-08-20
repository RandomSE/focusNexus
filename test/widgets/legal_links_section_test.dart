import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/legal/legal_documents.dart';
import 'package:focusNexus/widgets/legal_links_section.dart';

void main() {
  testWidgets('buttons variant includes EULA, Privacy, and IP', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LegalLinksSection.buttons(
              primaryColor: Colors.black,
              secondaryColor: Colors.white,
              textStyle: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );

    expect(find.text(LegalDocumentId.eula.title), findsOneWidget);
    expect(find.text(LegalDocumentId.privacyPolicy.title), findsOneWidget);
    expect(
      find.text(LegalDocumentId.intellectualProperty.title),
      findsOneWidget,
    );
  });

  testWidgets('textLinks can omit EULA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LegalLinksSection.textLinks(
              linkStyle: const TextStyle(
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
              includeEula: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text(LegalDocumentId.eula.title), findsNothing);
    expect(find.text(LegalDocumentId.privacyPolicy.title), findsOneWidget);
    expect(
      find.text(LegalDocumentId.intellectualProperty.title),
      findsOneWidget,
    );
  });
}
