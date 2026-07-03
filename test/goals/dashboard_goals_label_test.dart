import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/goals/dashboard_goals_label.dart';

void main() {
  group('dashboardGoalsButtonLabel', () {
    test('omits count when no active goals', () {
      expect(dashboardGoalsButtonLabel(0), 'Goals');
    });

    test('includes active count', () {
      expect(dashboardGoalsButtonLabel(3), 'Goals (3)');
    });

    test('appends in-slot summary on the button', () {
      expect(
        dashboardGoalsButtonLabel(3, goalsInSlotNow: 2),
        'Goals (3) · 2 in slot now',
      );
      expect(
        dashboardGoalsButtonLabel(1, goalsInSlotNow: 1),
        'Goals (1) · 1 in slot now',
      );
    });
  });

  group('dashboardInSlotLine', () {
    test('returns null when none in slot', () {
      expect(dashboardInSlotLine(0), isNull);
    });

    test('singular and plural in-slot lines', () {
      expect(dashboardInSlotLine(1), '1 in slot now');
      expect(dashboardInSlotLine(2), '2 in slot now');
    });
  });
}
