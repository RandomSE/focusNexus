import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_form_feedback.dart';

void main() {
  group('GoalFormFeedback.formatMissingFieldsMessage', () {
    test('empty list yields empty string', () {
      expect(GoalFormFeedback.formatMissingFieldsMessage(const []), '');
    });

    test('single field', () {
      expect(
        GoalFormFeedback.formatMissingFieldsMessage(const ['Goal Title']),
        'Please fill or fix: Goal Title.',
      );
    });

    test('two fields use and', () {
      expect(
        GoalFormFeedback.formatMissingFieldsMessage(const [
          'Goal Title',
          'Time Required in minutes',
        ]),
        'Please fill or fix: Goal Title and Time Required in minutes.',
      );
    });

    test('three or more use commas and and', () {
      expect(
        GoalFormFeedback.formatMissingFieldsMessage(const [
          'Template Name',
          'Time (minutes)',
          'Steps',
        ]),
        'Please fill or fix: Template Name, Time (minutes), and Steps.',
      );
    });
  });

  group('GoalFormFeedback.collectNormalGoalFieldIssues', () {
    test('reports empty title and invalid time', () {
      expect(
        GoalFormFeedback.collectNormalGoalFieldIssues(
          title: '',
          time: '',
          steps: '1',
          deadlineHours: '',
        ),
        ['Goal Title', 'Time Required in minutes'],
      );
    });

    test('reports deadline shorter than time required', () {
      expect(
        GoalFormFeedback.collectNormalGoalFieldIssues(
          title: 'Walk',
          time: '90',
          steps: '1',
          deadlineHours: '1',
        ),
        ['Hours to complete'],
      );
    });

    test('valid form yields no issues', () {
      expect(
        GoalFormFeedback.collectNormalGoalFieldIssues(
          title: 'Walk',
          time: '30',
          steps: '2',
          deadlineHours: '2',
        ),
        isEmpty,
      );
    });
  });

  group('GoalFormFeedback.collectTimeSlotGoalFieldIssues', () {
    test('reports empty title', () {
      expect(
        GoalFormFeedback.collectTimeSlotGoalFieldIssues(
          title: '  ',
          time: '10',
          steps: '1',
        ),
        ['Goal Title'],
      );
    });
  });

  group('GoalFormFeedback.collectTemplateFieldIssues', () {
    test('reports empty name and invalid time', () {
      expect(
        GoalFormFeedback.collectTemplateFieldIssues(
          name: '',
          time: '0',
          steps: '1',
          deadlineHours: '',
        ),
        ['Template Name', 'Time (minutes)'],
      );
    });
  });
}
