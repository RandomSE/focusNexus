import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/goal_deadline_label.dart';
import 'package:focusNexus/goals/goals_use_case.dart';

void main() {
  test('goalDeadlineLabel uses no-deadline label when empty', () {
    expect(goalDeadlineLabel(''), GoalsUseCase.noDeadlineLabel);
    expect(goalDeadlineLabel('   '), GoalsUseCase.noDeadlineLabel);
  });

  test('goalDeadlineLabel preserves formatted deadline', () {
    const formatted = '03 June 2026 14:30';
    expect(goalDeadlineLabel(formatted), formatted);
    expect(goalDeadlineLabel('  $formatted  '), formatted);
  });

  test('goalCompletedLabel uses unknown label when empty', () {
    expect(goalCompletedLabel(''), 'completion date unknown');
    expect(goalCompletedLabel('   '), 'completion date unknown');
  });

  test('goalCompletedLabel preserves formatted completion time', () {
    const formatted = '07 June 2026 09:15';
    expect(goalCompletedLabel(formatted), formatted);
  });
}
