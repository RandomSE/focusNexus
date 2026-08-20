import 'package:flutter/material.dart';
import 'package:focusNexus/legal/legal_documents.dart';
import 'package:focusNexus/utils/theme_styles.dart';
import 'package:focusNexus/widgets/settings_themed_builder.dart';

/// Scrollable viewer for bundled legal documents.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.documentId,
    this.primaryColor,
    this.secondaryColor,
    this.textStyle,
  });

  final LegalDocumentId documentId;
  final Color? primaryColor;
  final Color? secondaryColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SettingsThemedBuilder(
      builder: (context, bundle) {
        final bg = secondaryColor ?? bundle.secondaryColor;
        final fg = primaryColor ?? bundle.primaryColor;
        final style = textStyle ??
            ThemeStyles.buildTextStyle(
              fontSize: bundle.textStyle.fontSize ?? 14,
              primaryColor: fg,
              useDyslexiaFont: bundle.textStyle.fontFamily == 'OpenDyslexic',
            );

        return Theme(
          data: bundle.themeData,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              title: Text(documentId.title, style: style),
              backgroundColor: bg,
              iconTheme: ThemeStyles.iconThemeFor(fg),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                documentId.body,
                style: style.copyWith(
                  fontWeight: FontWeight.normal,
                  height: 1.35,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
