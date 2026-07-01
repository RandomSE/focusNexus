import 'dart:ui';

/// Which floating nav control should appear for the current viewport.
enum AssistantNavZone {
  /// No overlay — viewport is outside FAQ / ask content.
  none,

  /// Viewport is over FAQ answers — show jump to ask.
  faq,

  /// Viewport is over ask / chat — show jump to FAQ.
  ask,
}

/// Minimum visible overlap (0–1) before showing a zone-specific control.
const double kAssistantNavZoneOverlapThreshold = 0.12;

/// Picks [AssistantNavZone.faq] or [AssistantNavZone.ask] from viewport overlap.
AssistantNavZone assistantNavZoneFor({
  required double viewportTop,
  required double viewportBottom,
  required Rect? faqContentRect,
  required Rect? askContentRect,
}) {
  if (faqContentRect == null || askContentRect == null) {
    return AssistantNavZone.none;
  }

  final faqOverlap = _verticalOverlapRatio(
    viewportTop,
    viewportBottom,
    faqContentRect.top,
    faqContentRect.bottom,
  );
  final askOverlap = _verticalOverlapRatio(
    viewportTop,
    viewportBottom,
    askContentRect.top,
    askContentRect.bottom,
  );

  if (askOverlap >= kAssistantNavZoneOverlapThreshold &&
      askOverlap >= faqOverlap) {
    return AssistantNavZone.ask;
  }
  if (faqOverlap >= kAssistantNavZoneOverlapThreshold) {
    return AssistantNavZone.faq;
  }
  return AssistantNavZone.none;
}

double _verticalOverlapRatio(
  double viewTop,
  double viewBottom,
  double contentTop,
  double contentBottom,
) {
  final overlapTop = viewTop > contentTop ? viewTop : contentTop;
  final overlapBottom = viewBottom < contentBottom ? viewBottom : contentBottom;
  final overlap = overlapBottom - overlapTop;
  if (overlap <= 0) return 0;
  final viewHeight = viewBottom - viewTop;
  if (viewHeight <= 0) return 0;
  return overlap / viewHeight;
}
