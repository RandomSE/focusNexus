import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

/// Tappable follow-up question chips under an Assistant reply.
class AssistantRelatedQuestions extends StatelessWidget {
  const AssistantRelatedQuestions({
    super.key,
    required this.bundle,
    required this.title,
    required this.questions,
    required this.onQuestionSelected,
  });

  final ThemeBundle bundle;
  final String title;
  final List<String> questions;
  final ValueChanged<String> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();

    final dyslexia = usesOpenDyslexic(bundle.textStyle);
    final baseSize = bundle.textStyle.fontSize ?? 14;
    final titleStyle = bundle.textStyle.copyWith(
      fontSize: baseSize * 0.88,
      fontWeight: FontWeight.w600,
      color: bundle.primaryColor.withValues(alpha: 0.85),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: titleStyle),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final question in questions)
                _RelatedQuestionChip(
                  bundle: bundle,
                  label: question,
                  dyslexia: dyslexia,
                  onTap: () => onQuestionSelected(question),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelatedQuestionChip extends StatelessWidget {
  const _RelatedQuestionChip({
    required this.bundle,
    required this.label,
    required this.dyslexia,
    required this.onTap,
  });

  final ThemeBundle bundle;
  final String label;
  final bool dyslexia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.85;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bundle.primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: bundle.primaryColor.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: dyslexia ? 10 : 8,
              ),
              child: Text(
                label,
                style: bundle.textStyle.copyWith(height: 1.35),
                softWrap: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
