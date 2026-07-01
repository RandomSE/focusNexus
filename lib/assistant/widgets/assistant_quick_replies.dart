import 'package:flutter/material.dart';

import 'package:focusNexus/assistant/assistant_faq.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

/// Tappable suggested questions above the Assistant input field.
class AssistantQuickReplies extends StatelessWidget {
  const AssistantQuickReplies({
    super.key,
    required this.bundle,
    required this.onSelected,
  });

  final ThemeBundle bundle;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxChipWidth = constraints.maxWidth * 0.85;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Suggested questions',
                    style: bundle.textStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: bundle.primaryColor,
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                children: [
                  for (final label in assistantQuickReplies)
                    _AssistantQuickReplyChip(
                      bundle: bundle,
                      label: label,
                      maxWidth: maxChipWidth,
                      onPressed: () => onSelected(label),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AssistantQuickReplyChip extends StatelessWidget {
  const _AssistantQuickReplyChip({
    required this.bundle,
    required this.label,
    required this.maxWidth,
    required this.onPressed,
  });

  final ThemeBundle bundle;
  final String label;
  final double maxWidth;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dyslexia = usesOpenDyslexic(bundle.textStyle);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: bundle.primaryColor.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: bundle.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: dyslexia ? 10 : 8,
            ),
            child: Text(
              label,
              style: bundle.textStyle,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
