import 'package:flutter/material.dart';

/// Section title that never shares a [Row] with growing action controls.
///
/// Large user fonts make sibling [TextButton] / [FilterChip] / price labels
/// steal width from an [Expanded] title, which then wraps one character per
/// line. Put the title on its own row; actions go in a [Wrap] below.
class SectionTitleActions extends StatelessWidget {
  const SectionTitleActions({
    super.key,
    required this.title,
    required this.titleStyle,
    this.actions = const <Widget>[],
    this.titleSpacing = 4,
    this.actionSpacing = 8,
    this.actionRunSpacing = 4,
  });

  final String title;
  final TextStyle titleStyle;
  final List<Widget> actions;
  final double titleSpacing;
  final double actionSpacing;
  final double actionRunSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: titleStyle,
          softWrap: true,
        ),
        if (actions.isNotEmpty) ...[
          SizedBox(height: titleSpacing),
          Wrap(
            spacing: actionSpacing,
            runSpacing: actionRunSpacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
      ],
    );
  }
}
