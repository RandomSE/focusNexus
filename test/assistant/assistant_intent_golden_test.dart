import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_faq.dart';
import 'package:focusNexus/assistant/assistant_resolution.dart';
import 'package:focusNexus/assistant/resolve_assistant_response.dart';

/// Normalized user phrasing → expected FAQ [AssistantFaqEntry.id].
///
/// [expectedId] may be `fallback` or `professional` for non-FAQ outcomes.
const _goldenCases = <({String query, String expectedId})>[
  (query: 'What is FocusNexus?', expectedId: 'general.about'),
  (query: 'Tell me about this app', expectedId: 'general.about'),
  (query: 'What is your data policy?', expectedId: 'general.data_policy'),
  (query: 'Data privacy policy', expectedId: 'general.data_policy'),
  (query: 'Do you sell my data?', expectedId: 'general.data_policy'),
  (query: 'How do I open settings?', expectedId: 'general.open_settings'),
  (query: 'Where is settings?', expectedId: 'general.open_settings'),
  (query: 'How do I get to goals?', expectedId: 'general.open_goals'),
  (query: 'Open achievements', expectedId: 'general.open_achievements'),
  (query: 'Where is the reward screen?', expectedId: 'general.open_reward'),
  (query: 'How do I navigate the app?', expectedId: 'general.navigation'),
  (query: 'How many points do I have?', expectedId: 'general.points_balance'),
  (query: 'What is my point balance?', expectedId: 'general.points_balance'),
  (query: 'What does in slot now mean?', expectedId: 'general.in_slot_now'),
  (query: 'What is a goal?', expectedId: 'goals.what_is_goal'),
  (query: 'What is a deadline goal?', expectedId: 'goals.deadline'),
  (query: 'What is a time slot goal?', expectedId: 'goals.time_slot'),
  (query: 'What is a time-slot goal?', expectedId: 'goals.time_slot'),
  (query: 'Explain time windows for goals', expectedId: 'goals.time_slot'),
  (query: 'How do I add a goal?', expectedId: 'goals.add_complete'),
  (query: 'How do I complete a goal?', expectedId: 'goals.add_complete'),
  (query: 'What are templates?', expectedId: 'goals.templates'),
  (query: 'Template manager vs multi template', expectedId: 'goals.template_manager'),
  (query: 'How do repeats work?', expectedId: 'goals.repeats'),
  (query: 'How do I earn points?', expectedId: 'goals.earn_points'),
  (query: 'How do I earn points from goals?', expectedId: 'goals.earn_points'),
  (query: 'Calendar goals coming soon?', expectedId: 'goals.calendar'),
  (query: 'Active vs completed goals filter', expectedId: 'goals.status_filters'),
  (query: 'How do I clear active goals?', expectedId: 'goals.clear_active'),
  (query: 'What does high contrast mode do?', expectedId: 'settings.high_contrast'),
  (query: 'What does high contrast do?', expectedId: 'settings.high_contrast'),
  (query: 'Dyslexia font setting', expectedId: 'settings.dyslexia_font'),
  (query: 'What are reward types?', expectedId: 'settings.reward_types'),
  (query: 'What do the reward types do?', expectedId: 'settings.reward_types'),
  (query: 'Notification frequency', expectedId: 'settings.notification_frequency'),
  (query: 'Daily affirmations', expectedId: 'settings.daily_affirmations'),
  (query: 'What is AI Encouragement?', expectedId: 'settings.ai_encouragement'),
  (query: 'What is AI encouragement?', expectedId: 'settings.ai_encouragement'),
  (
    query: 'Difference between assistant and AI encouragement',
    expectedId: 'general.assistant_vs_encouragement',
  ),
  (query: 'Pause goals notifications', expectedId: 'settings.pause_goals'),
  (query: 'Sound volume settings', expectedId: 'settings.sound'),
  (query: 'Delete my account', expectedId: 'settings.delete_account'),
  (query: 'How does the Zen garden work?', expectedId: 'rewards.zen_garden'),
  (query: 'Zen garden restart growth mutation', expectedId: 'rewards.zen_rebirth'),
  (query: 'What are achievements?', expectedId: 'rewards.achievements'),
  (query: 'How do I claim achievements?', expectedId: 'rewards.claim_achievements'),
  (query: 'How do mini-games work?', expectedId: 'rewards.mini_games'),
  (query: 'How many points do I start with?', expectedId: 'rewards.starting_points'),
  (query: 'Customization reward colors', expectedId: 'rewards.customization'),
  (query: 'What happens during onboarding?', expectedId: 'general.onboarding'),
  (query: 'Who won the world cup in 1998?', expectedId: 'fallback'),
  (query: 'Do I have ADHD?', expectedId: 'professional'),
];

void main() {
  group('assistant intent golden suite', () {
    test('resolves curated phrasings to expected entry ids', () {
      var matched = 0;
      final failures = <String>[];

      for (final testCase in _goldenCases) {
        final resolution = resolveAssistantQuery(testCase.query);
        final actualId = switch (resolution.kind) {
          AssistantResolutionKind.fallback => 'fallback',
          AssistantResolutionKind.professionalAdvice => 'professional',
          AssistantResolutionKind.disambiguation => 'disambiguation:${resolution.disambiguationEntryIds.join(',')}',
          _ => resolution.entryId ?? 'missing-id',
        };

        if (testCase.expectedId == 'fallback' ||
            testCase.expectedId == 'professional') {
          if (actualId == testCase.expectedId) {
            matched++;
          } else {
            failures.add(
              '"${testCase.query}" → expected ${testCase.expectedId}, got $actualId',
            );
          }
          continue;
        }

        if (actualId == testCase.expectedId) {
          matched++;
        } else {
          failures.add(
            '"${testCase.query}" → expected ${testCase.expectedId}, got $actualId',
          );
        }
      }

      final rate = matched / _goldenCases.length;
      expect(
        failures,
        isEmpty,
        reason: 'Golden intent failures (${(rate * 100).toStringAsFixed(1)}%):\n'
            '${failures.join('\n')}',
      );
      expect(rate, greaterThanOrEqualTo(0.9));
    });
  });

  group('exact-match fast paths', () {
    test('every FAQ question resolves to its own id', () {
      for (final entry in allAssistantFaqEntries) {
        final resolution = resolveAssistantQuery(entry.question);
        expect(
          resolution.entryId,
          entry.id,
          reason: 'FAQ question "${entry.question}"',
        );
        expect(resolution.kind, AssistantResolutionKind.exact);
      }
    });

    test('every quick reply resolves confidently', () {
      for (final label in assistantQuickReplies) {
        final resolution = resolveAssistantQuery(label);
        expect(
          resolution.entryId,
          isNotNull,
          reason: 'Quick reply "$label"',
        );
        expect(
          resolution.kind,
          anyOf(
            AssistantResolutionKind.exact,
            AssistantResolutionKind.keyword,
          ),
          reason: 'Quick reply "$label"',
        );
      }
    });
  });

  group('matcher edge cases', () {
    test('AI encouragement is not confused with assistant contrast entry', () {
      final resolution = resolveAssistantQuery('What is AI Encouragement?');
      expect(resolution.entryId, 'settings.ai_encouragement');
      expect(resolution.text.toLowerCase(), contains('notification'));
      expect(resolution.text.toLowerCase(), isNot(contains('chatgpt')));
    });

    test('live balance deflects without inventing a number', () {
      final resolution = resolveAssistantQuery('How many points do I have?');
      expect(resolution.entryId, 'general.points_balance');
      expect(resolution.text.toLowerCase(), contains('dashboard'));
      expect(resolution.text, isNot(contains(RegExp(r'\b\d{3,}\b'))));
    });

    test('mini-games caveat stays honest', () {
      final resolution = resolveAssistantQuery('How do mini-games work?');
      expect(resolution.entryId, 'rewards.mini_games');
      expect(resolution.text.toLowerCase(), contains('placeholder'));
    });

    test('confident matches expose related question chips', () {
      final resolution = resolveAssistantQuery('What is FocusNexus?');
      expect(resolution.relatedQuestions, isNotEmpty);
      expect(resolution.text, isNot(contains('You might also ask:')));
    });

    test('create goal phrase falls back without create command', () {
      final resolution = resolveAssistantQuery('create goal Read');
      expect(
        resolution.kind,
        anyOf(
          AssistantResolutionKind.fallback,
          AssistantResolutionKind.keyword,
        ),
      );
    });

    test('how do i add a goal stays FAQ', () {
      final resolution = resolveAssistantQuery('How do I add a goal?');
      expect(resolution.entryId, 'goals.add_complete');
      expect(resolution.kind, AssistantResolutionKind.exact);
    });
  });
}
