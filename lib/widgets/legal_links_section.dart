import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusNexus/app/app_navigation.dart';
import 'package:focusNexus/app/app_route.dart';
import 'package:focusNexus/legal/legal_documents.dart';
import 'package:focusNexus/utils/common_utils.dart';

/// Shared navigation affordances for in-app legal documents.
class LegalLinksSection extends ConsumerWidget {
  const LegalLinksSection.buttons({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
    this.includeEula = true,
    this.eulaButtonLabel = 'End User License Agreement',
    this.spacing = 8,
  }) : variant = LegalLinksVariant.buttons,
       linkStyle = null,
       separator = null;

  const LegalLinksSection.textLinks({
    super.key,
    required this.linkStyle,
    this.includeEula = true,
    this.separator = '·',
    this.spacing = 8,
  })  : variant = LegalLinksVariant.textLinks,
        primaryColor = null,
        secondaryColor = null,
        textStyle = null,
        eulaButtonLabel = null;

  final LegalLinksVariant variant;
  final Color? primaryColor;
  final Color? secondaryColor;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final bool includeEula;
  final String? eulaButtonLabel;
  final String? separator;
  final double spacing;

  List<LegalDocumentId> get _ids => [
        if (includeEula) LegalDocumentId.eula,
        LegalDocumentId.privacyPolicy,
        LegalDocumentId.intellectualProperty,
      ];

  void _open(WidgetRef ref, BuildContext context, LegalDocumentId id) {
    ref.pushRoute(context, LegalDocumentRoute(id));
  }

  String _labelFor(LegalDocumentId id) {
    if (id == LegalDocumentId.eula && eulaButtonLabel != null) {
      return eulaButtonLabel!;
    }
    return id.title;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (variant) {
      LegalLinksVariant.buttons => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _ids.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              CommonUtils.buildElevatedButton(
                _labelFor(_ids[i]),
                primaryColor!,
                secondaryColor!,
                textStyle!,
                0,
                0,
                () => _open(ref, context, _ids[i]),
              ),
            ],
          ],
        ),
      LegalLinksVariant.textLinks => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: spacing,
          children: [
            for (var i = 0; i < _ids.length; i++) ...[
              if (i > 0 && separator != null)
                Text(
                  separator!,
                  style: linkStyle!.copyWith(
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none,
                  ),
                ),
              TextButton(
                onPressed: () => _open(ref, context, _ids[i]),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_labelFor(_ids[i]), style: linkStyle),
              ),
            ],
          ],
        ),
    };
  }
}

enum LegalLinksVariant { buttons, textLinks }

/// Inline text-button link to a single legal document (e.g. EULA in a checkbox).
class LegalDocumentTextLink extends ConsumerWidget {
  const LegalDocumentTextLink({
    super.key,
    required this.documentId,
    required this.label,
    required this.linkStyle,
  });

  final LegalDocumentId documentId;
  final String label;
  final TextStyle linkStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () =>
          ref.pushRoute(context, LegalDocumentRoute(documentId)),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: linkStyle),
    );
  }
}
