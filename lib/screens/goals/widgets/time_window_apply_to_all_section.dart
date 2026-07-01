import 'package:flutter/material.dart';
import 'package:focusNexus/models/classes/theme_bundle.dart';

/// Bordered group for shared “apply to all” controls in the bulk wizard.
class TimeWindowApplyToAllSection extends StatelessWidget {
  const TimeWindowApplyToAllSection({
    super.key,
    required this.bundle,
    required this.title,
    required this.child,
  });

  final ThemeBundle bundle;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bundle.primaryColor.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: bundle.accentColor.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: bundle.textStyle.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
