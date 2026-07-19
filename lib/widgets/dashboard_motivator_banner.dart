import 'package:flutter/material.dart';
import 'package:focusNexus/motivators/adhd_motivator_pack.dart';

/// Non-blocking dashboard motivator: tap to swap, dismiss for session.
///
/// Never modal-blocks navigation; does not steal focus from primary CTAs.
class DashboardMotivatorBanner extends StatelessWidget {
  const DashboardMotivatorBanner({
    super.key,
    required this.text,
    required this.textStyle,
    required this.onSwap,
    required this.onDismiss,
    this.accentColor,
  });

  final String text;
  final TextStyle textStyle;
  final VoidCallback onSwap;
  final VoidCallback onDismiss;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final border = accentColor ?? textStyle.color?.withValues(alpha: 0.35);

    return Semantics(
      container: true,
      label: 'Motivator: $text. Double tap to show another. Dismiss available.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSwap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border ?? Colors.grey),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(text, style: textStyle),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Dismiss motivator for this session',
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: textStyle.color,
                    ),
                    onPressed: onDismiss,
                    tooltip: 'Dismiss',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Convenience factory selecting copy from [AdhdMotivatorPack].
  static String textFor({required int index}) => AdhdMotivatorPack.lineAt(index);
}
