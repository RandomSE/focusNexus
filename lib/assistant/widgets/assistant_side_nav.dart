import 'package:flutter/material.dart';

import 'package:focusNexus/assistant/assistant_scroll_zone.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';
import 'package:focusNexus/utils/form_field_metrics.dart';

/// Widget-test anchor for the floating FAQ jump control.
const Key kAssistantSideNavFaqKey = Key('assistant-side-nav-faq');

/// Widget-test anchor for the floating ask jump control.
const Key kAssistantSideNavAskKey = Key('assistant-side-nav-ask');

/// Compact floating FAQ / Ask controls that overlay scroll content.
class AssistantSideNav extends StatelessWidget {
  const AssistantSideNav({
    super.key,
    required this.bundle,
    required this.zone,
    required this.onFaq,
    required this.onAsk,
  });

  final ThemeBundle bundle;
  final AssistantNavZone zone;
  final VoidCallback onFaq;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    if (zone == AssistantNavZone.none) {
      return const SizedBox.shrink();
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showFaq = zone == AssistantNavZone.ask;
    final showAsk = zone == AssistantNavZone.faq;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showFaq)
          Positioned(
            right: 10,
            top: 10,
            child: _FloatingNavButton(
              key: kAssistantSideNavFaqKey,
              bundle: bundle,
              label: 'FAQ',
              onPressed: onFaq,
            ),
          ),
        if (showAsk)
          Positioned(
            right: 10,
            bottom: bottomInset + 10,
            child: _FloatingNavButton(
              key: kAssistantSideNavAskKey,
              bundle: bundle,
              label: 'Ask question',
              onPressed: onAsk,
            ),
          ),
      ],
    );
  }
}

class _FloatingNavButton extends StatelessWidget {
  const _FloatingNavButton({
    super.key,
    required this.bundle,
    required this.label,
    required this.onPressed,
  });

  final ThemeBundle bundle;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dyslexia = usesOpenDyslexic(bundle.textStyle);
    final baseSize = bundle.textStyle.fontSize ?? 14;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        elevation: 3,
        color: bundle.secondaryColor.withValues(alpha: 0.94),
        shadowColor: bundle.primaryColor.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: bundle.primaryColor.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dyslexia ? 10 : 12,
              vertical: dyslexia ? 8 : 6,
            ),
            child: Text(
              label,
              style: bundle.textStyle.copyWith(
                fontSize: baseSize * 0.82,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }
}
