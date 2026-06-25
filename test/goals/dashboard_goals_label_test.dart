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
