import 'package:flutter/material.dart';

import 'package:focusNexus/models/classes/theme_bundle.dart';

/// Visual break between major Assistant areas (FAQ vs conversation).
class AssistantSectionHeader extends StatelessWidget {
  const AssistantSectionHeader({
    super.key,
    required this.bundle,
    required this.title,
  });

  final ThemeBundle bundle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 2,
          thickness: 2,
          color: bundle.primaryColor.withValues(alpha: 0.35),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: bundle.textStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: bundle.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
