import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_scroll_zone.dart';

void main() {
  test('assistantNavZoneFor returns none without layout rects', () {
    expect(
      assistantNavZoneFor(
        viewportTop: 0,
        viewportBottom: 400,
        faqContentRect: null,
        askContentRect: const Rect.fromLTWH(0, 500, 100, 200),
      ),
      AssistantNavZone.none,
    );
  });

  test('assistantNavZoneFor prefers ask when ask content fills viewport', () {
    expect(
      assistantNavZoneFor(
        viewportTop: 100,
        viewportBottom: 500,
        faqContentRect: const Rect.fromLTWH(0, 0, 100, 80),
        askContentRect: const Rect.fromLTWH(0, 120, 100, 600),
      ),
      AssistantNavZone.ask,
    );
  });

  test('assistantNavZoneFor prefers faq when faq content fills viewport', () {
    expect(
      assistantNavZoneFor(
        viewportTop: 50,
        viewportBottom: 450,
        faqContentRect: const Rect.fromLTWH(0, 40, 100, 500),
        askContentRect: const Rect.fromLTWH(0, 560, 100, 400),
      ),
      AssistantNavZone.faq,
    );
  });

  test('assistantNavZoneFor returns none when only headers peek in', () {
    expect(
      assistantNavZoneFor(
        viewportTop: 0,
        viewportBottom: 400,
        faqContentRect: const Rect.fromLTWH(0, 380, 100, 500),
        askContentRect: const Rect.fromLTWH(0, 900, 100, 400),
      ),
      AssistantNavZone.none,
    );
  });
}
