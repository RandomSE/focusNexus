import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/builtin_goal_templates.dart';
import 'package:focusNexus/goals/template_group_cleanup.dart';

void main() {
  group('cleanupTemplateGroups', () {
    test('keeps built-in templates when user template is deleted', () {
      const deleted = 'My custom template';
      final valid = {
        ...builtinGoalTemplates.keys,
        'Other custom',
      };

      final result = cleanupTemplateGroups(
        groups: {
          'Morning': [
            'Clean your room',
            deleted,
            '5-minute walk',
          ],
        },
        validTemplateNames: valid,
      );

      expect(result.updatedGroups['Morning'], [
        'Clean your room',
        '5-minute walk',
      ]);
      expect(result.rebuiltGroups['Morning'], [deleted]);
      expect(result.removedGroupNames, isEmpty);
    });

    test('removes group when every template was deleted', () {
      final result = cleanupTemplateGroups(
        groups: {
          'Stale': ['gone-a', 'gone-b'],
        },
        validTemplateNames: builtinGoalTemplates.keys.toSet(),
      );

      expect(result.updatedGroups, isEmpty);
      expect(result.removedGroupNames, ['Stale']);
    });

    test('aggregates multiple affected groups for one message', () {
      final result = cleanupTemplateGroups(
        groups: {
          'A': ['gone', 'Clean your room'],
          'B': ['gone'],
        },
        validTemplateNames: builtinGoalTemplates.keys.toSet(),
      );

      expect(result.hasChanges, isTrue);
      expect(result.removedGroupNames, ['B']);
      expect(result.rebuiltGroups['A'], ['gone']);
      expect(
        templateGroupCleanupMessage(result),
        contains('Group "A" updated'),
      );
      expect(
        templateGroupCleanupMessage(result),
        contains('Removed group "B"'),
      );
    });
  });
}
