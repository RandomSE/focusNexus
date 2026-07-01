import 'package:flutter/material.dart';

import 'package:focusNexus/assistant/assistant_faq.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

/// Expandable FAQ sections for the Assistant screen.
class AssistantFaqPanel extends StatelessWidget {
  const AssistantFaqPanel({
    super.key,
    required this.bundle,
    required this.onQuestionSelected,
  });

  final ThemeBundle bundle;
  final ValueChanged<String> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in assistantFaqSections)
          _FaqSectionTile(
            bundle: bundle,
            section: section,
            onQuestionSelected: onQuestionSelected,
          ),
      ],
    );
  }
}

class _FaqSectionTile extends StatelessWidget {
  const _FaqSectionTile({
    required this.bundle,
    required this.section,
    required this.onQuestionSelected,
  });

  final ThemeBundle bundle;
  final AssistantFaqSection section;
  final ValueChanged<String> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bundle.secondaryColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            section.title,
            style: bundle.textStyle.copyWith(fontWeight: FontWeight.w600),
            softWrap: true,
          ),
          children: [
            for (var i = 0; i < section.entries.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: bundle.primaryColor.withValues(alpha: 0.15),
                ),
              _FaqEntryCard(
                bundle: bundle,
                entry: section.entries[i],
                onQuestionSelected: onQuestionSelected,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqEntryCard extends StatelessWidget {
  const _FaqEntryCard({
    required this.bundle,
    required this.entry,
    required this.onQuestionSelected,
  });

  final ThemeBundle bundle;
  final AssistantFaqEntry entry;
  final ValueChanged<String> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    final dyslexia = usesOpenDyslexic(bundle.textStyle);
    final baseSize = bundle.textStyle.fontSize ?? 14;
    final questionStyle = bundle.textStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: bundle.primaryColor,
      height: 1.35,
    );
    final answerStyle = bundle.textStyle.copyWith(
      fontSize: baseSize * 0.94,
      fontWeight: FontWeight.w400,
      color: bundle.primaryColor.withValues(alpha: 0.82),
      height: 1.4,
    );
    final labelStyle = bundle.textStyle.copyWith(
      fontSize: baseSize * 0.78,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: bundle.accentColor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: bundle.primaryColor.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: bundle.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onQuestionSelected(entry.question),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, 10, 12, dyslexia ? 10 : 8),
                color: bundle.primaryColor.withValues(alpha: 0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('QUESTION', style: labelStyle),
                    const SizedBox(height: 4),
                    Text(
                      entry.question,
                      style: questionStyle,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, dyslexia ? 12 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('ANSWER', style: labelStyle),
                    const SizedBox(height: 4),
                    Text(
                      entry.answer,
                      style: answerStyle,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
