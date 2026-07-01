import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_achievement_match.dart';
import 'package:focusNexus/assistant/assistant_live_context.dart';
import 'package:focusNexus/assistant/assistant_resolution.dart';
import 'package:focusNexus/assistant/local_assistant_service.dart';
import 'package:focusNexus/assistant/resolve_assistant_response.dart';

void main() {
  const hints = [
    AssistantAchievementHint(
      title: 'Goal Setter I',
      task: 'Create goals 10 times',
    ),
    AssistantAchievementHint(
      title: 'Completionist II',
      task: 'Complete goals 100 times',
    ),
  ];

  group('resolveAchievementGlossaryQuery', () {
    test('matches achievement title fragments', () {
      final resolution = resolveAchievementGlossaryQuery(
        'How do I get Goal Setter I?',
        liveContext: const AssistantLiveContext(achievements: hints),
      );
      expect(resolution?.kind, AssistantResolutionKind.achievement);
      expect(resolution?.text, contains('Goal Setter I'));
      expect(resolution?.text, contains('Create goals'));
    });

    test('ignores unrelated queries', () {
      final resolution = resolveAchievementGlossaryQuery(
        'What is a time-slot goal?',
        liveContext: const AssistantLiveContext(achievements: hints),
      );
      expect(resolution, isNull);
    });
  });

  group('live points context', () {
    test('injects balance when available', () {
      final resolution = resolveAssistantQuery(
        'How many points do I have?',
        liveContext: const AssistantLiveContext(pointsBalance: 125),
      );
      expect(resolution.entryId, 'general.points_balance');
      expect(resolution.text, contains('125'));
      expect(resolution.text, contains('currently have'));
    });

    test('LocalAssistantService reads injected context', () async {
      final service = LocalAssistantService(
        readLiveContext: () async => const AssistantLiveContext(pointsBalance: 42),
      );
      final reply = await service.sendMessage('How many points do I have?');
      expect(reply.text, contains('42'));
    });
  });

  group('resolver priority', () {
    test('alias match wins before achievement glossary', () {
      final resolution = resolveAssistantQuery(
        'How do I earn points?',
        liveContext: const AssistantLiveContext(
          achievements: hints,
        ),
      );
      expect(resolution.entryId, 'goals.earn_points');
      expect(resolution.kind, AssistantResolutionKind.exact);
    });

    test('achievement glossary resolves when no alias matches', () {
      final resolution = resolveAssistantQuery(
        'How do I get Goal Setter I?',
        liveContext: const AssistantLiveContext(achievements: hints),
      );
      expect(resolution.kind, AssistantResolutionKind.achievement);
      expect(resolution.text, contains('Goal Setter I'));
    });
  });

  group('structured related questions', () {
    test('confident FAQ matches expose chip labels separately from answer', () {
      final resolution = resolveAssistantQuery('What is FocusNexus?');
      expect(resolution.text, isNot(contains('You might also ask:')));
      expect(resolution.relatedQuestions, isNotEmpty);
    });
  });
}
