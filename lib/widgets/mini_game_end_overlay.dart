import 'package:flutter/material.dart';

/// Full-screen end-of-round veil: tap anywhere (or Done) to dismiss.
class MiniGameEndOverlay extends StatelessWidget {
  const MiniGameEndOverlay({
    super.key,
    required this.backgroundColor,
    required this.child,
    required this.onDismiss,
  });

  final Color backgroundColor;
  final Widget child;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: ColoredBox(
          color: backgroundColor,
          child: Center(child: child),
        ),
      ),
    );
  }
}
