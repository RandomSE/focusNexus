import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/assistant/assistant_chat_reply.dart';
import 'package:focusNexus/assistant/assistant_faq.dart';
import 'package:focusNexus/assistant/local_assistant_service.dart';
import 'package:focusNexus/assistant/resolve_assistant_response.dart';

void main() {
  final service = LocalAssistantService();

  group('resolveAssistantResponse', () {
    test('navigation intent mentions dashboard destinations', () {
      final reply = resolveAssistantResponse('How do I open settings?');
      expect(reply.toLowerCase(), contains('settings'));
      expect(reply.toLowerCase(), contains('dashboard'));
    });

    test('time slot intent explains action window', () {
      final reply = resolveAssistantResponse('What is a time slot goal?');
      expect(reply.toLowerCase(), contains('slot'));
      expect(reply.toLowerCase(), contains('window'));
    });

    test('AI encouragement differs from assistant chat', () {
      final reply = resolveAssistantResponse('What is AI encouragement?');
      expect(reply.toLowerCase(), contains('notification'));
      expect(reply.toLowerCase(), isNot(contains('chatgpt')));
    });

    test('mini-games caveat is honest about placeholder', () {
      final reply = resolveAssistantResponse('How do mini-games work?');
      expect(reply.toLowerCase(), contains('placeholder'));
    });

    test('live points question deflects to dashboard', () {
      final reply = resolveAssistantResponse('How many points do I have?');
      expect(reply.toLowerCase(), contains('dashboard'));
      expect(reply, isNot(contains(RegExp(r'\b\d{3,}\b'))));
    });

    test('data privacy states local-only storage', () {
      final reply = resolveAssistantResponse('What is your data policy?');
      expect(reply.toLowerCase(), contains('device'));
      expect(reply.toLowerCase(), contains('does not sell'));
    });

    test('high contrast FAQ explains setting purpose', () {
      final reply = resolveAssistantResponse('What does high contrast mode do?');
      expect(reply.toLowerCase(), contains('contrast'));
    });

    test('fallback for unrelated questions', () {
      final reply = resolveAssistantResponse('Who won the world cup in 1998?');
      expect(reply.toLowerCase(), contains('not sure'));
    });

    test('professional advice is declined gently', () {
      final reply = resolveAssistantResponse('Do I have ADHD?');
      expect(reply.toLowerCase(), contains('professional'));
    });
  });

  group('LocalAssistantService', () {
    test('sendMessage delegates to resolver', () async {
      final reply = await service.sendMessage('What is FocusNexus?');
      expect(reply, isA<AssistantChatReply>());
      expect(reply.text.toLowerCase(), contains('focusnexus'));
    });
  });

  group('assistant FAQ catalog', () {
    test('has settings and goals sections', () {
      final titles = assistantFaqSections.map((s) => s.title).toList();
      expect(titles, contains('Settings'));
      expect(titles, contains('Goals'));
      expect(titles, contains('General'));
    });

    test('every entry has question, answer, and stable id', () {
      for (final section in assistantFaqSections) {
        for (final entry in section.entries) {
          expect(entry.id.trim(), isNotEmpty);
          expect(entry.question.trim(), isNotEmpty);
          expect(entry.answer.trim(), isNotEmpty);
        }
      }
    });

    test('quick replies are drawn from FAQ', () {
      expect(assistantQuickReplies.length, greaterThanOrEqualTo(6));
      expect(assistantQuickReplies.length, lessThanOrEqualTo(8));
    });
  });
}
