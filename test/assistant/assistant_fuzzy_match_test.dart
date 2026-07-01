import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_fuzzy_match.dart';
import 'package:focusNexus/assistant/resolve_assistant_response.dart';

void main() {
  group('assistantLevenshteinDistance', () {
    test('identical strings are zero apart', () {
      expect(assistantLevenshteinDistance('settings', 'settings'), 0);
    });

    test('single typo is distance 1', () {
      expect(assistantLevenshteinDistance('settings', 'setings'), 1);
    });
  });

  group('fuzzy FAQ matching', () {
    test('misspelled encouragement still resolves', () {
      final resolution = resolveAssistantQuery('What is AI encoragement?');
      expect(resolution.entryId, 'settings.ai_encouragement');
    });

    test('misspelled settings still resolves navigation entry', () {
      final resolution = resolveAssistantQuery('Where is setings?');
      expect(resolution.entryId, 'general.open_settings');
    });
  });
}
