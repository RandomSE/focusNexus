import 'package:flutter/material.dart';
import 'package:focusNexus/widgets/mini_game_themed_hud.dart';

/// Shared top-bar / score / timer / end chrome using [MiniGameThemedHud.compact].
abstract final class MiniGameHudChrome {
  static const Color defaultNumberGlow = Color.fromRGBO(255, 183, 197, 0.25);

  /// Back (left) | [center] true-screen-center | timer (+ End) flush right.
  static Widget topBar({
    required MiniGameThemedHud hud,
    required VoidCallback onBack,
    required Widget center,
    required String timerLabel,
    VoidCallback? onEnd,
    String endLabel = 'End',
  }) {
    return Positioned(
      top: 8,
      left: 4,
      right: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: hud.foreground),
                tooltip: 'Back',
              ),
              const Spacer(),
              timerPill(hud: hud, label: timerLabel),
              if (onEnd != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onEnd,
                  child: Text(
                    endLabel,
                    style: hud.compact(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          IgnorePointer(child: center),
        ],
      ),
    );
  }

  static Widget timerPill({
    required MiniGameThemedHud hud,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hud.foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hud.foreground.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: hud.compact(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Label + optional glow value + optional streak block.
  static Widget scoreColumn({
    required MiniGameThemedHud hud,
    required String label,
    required String value,
    String? streakLabel,
    String? streakValue,
    Color? streakColor,
    Widget? belowValue,
    Color numberGlow = defaultNumberGlow,
    double valueFontSize = 26,
    double valueScale = 1,
  }) {
    Widget valueStack = Stack(
      alignment: Alignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            inherit: false,
            fontSize: valueFontSize,
            fontWeight: FontWeight.w600,
            fontFamily: hud.body.fontFamily,
            height: 1.1,
            foreground: Paint()
              ..color = numberGlow
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          ),
        ),
        Text(
          value,
          style: hud.compact(
            fontSize: valueFontSize,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
    if (valueScale != 1) {
      valueStack = Transform.scale(scale: valueScale, child: valueStack);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: hud.compact(fontSize: 12)),
          const SizedBox(height: 2),
          valueStack,
          if (belowValue != null) belowValue,
          if (streakLabel != null && streakValue != null) ...[
            const SizedBox(height: 6),
            Text(streakLabel, style: hud.compact(fontSize: 11)),
            Text(
              streakValue,
              style: hud.compact(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: streakColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// End-of-round centered score block (label, big value, optional secondary, Done).
  static Widget endScoreBody({
    required MiniGameThemedHud hud,
    required String title,
    required String value,
    required VoidCallback onDone,
    String? secondaryLabel,
    String? secondaryValue,
    Color? secondaryColor,
    Color numberGlow = defaultNumberGlow,
    String doneLabel = 'Done',
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: hud.compact(fontSize: 16)),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                inherit: false,
                fontSize: 52,
                fontWeight: FontWeight.w600,
                fontFamily: hud.body.fontFamily,
                height: 1.0,
                foreground: Paint()
                  ..color = numberGlow
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
              ),
            ),
            Text(
              value,
              style: hud.compact(
                fontSize: 52,
                fontWeight: FontWeight.w300,
                height: 1.0,
              ),
            ),
          ],
        ),
        if (secondaryLabel != null && secondaryValue != null) ...[
          const SizedBox(height: 16),
          Text(secondaryLabel, style: hud.compact(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            secondaryValue,
            style: hud.compact(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextButton(
          onPressed: onDone,
          child: Text(
            doneLabel,
            style: hud.compact(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
