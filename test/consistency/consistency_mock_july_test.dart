import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/consistency/consistency_aggregator.dart';
import 'package:focusNexus/consistency/consistency_mock_july.dart';

void main() {
  test('July mock has mixed tiers and at least two zero days', () {
    final goals = ConsistencyMockJuly.buildCompletedGoals();
    final counts = ConsistencyAggregator.countsForMonth(
      goals,
      ConsistencyMockJuly.defaultYear,
      7,
    );
    final daysInJuly = DateTime(ConsistencyMockJuly.defaultYear, 8, 0).day;
    final zeroDays = <int>[];
    for (var d = 1; d <= daysInJuly; d++) {
      final day = DateTime(ConsistencyMockJuly.defaultYear, 7, d);
      final c = counts[day] ?? 0;
      if (c == 0) zeroDays.add(d);
    }
    expect(zeroDays.length, greaterThanOrEqualTo(2));
    expect(counts.values.any((c) => c >= 1 && c <= 4), isTrue);
    expect(goals, isNotEmpty);
    expect(
      ConsistencyAggregator.goalsOnDay(
        goals,
        counts.keys.first,
      ),
      isNotEmpty,
    );
  });

  test('July mock is deterministic for the default seed', () {
    final a = ConsistencyMockJuly.buildCompletedGoals();
    final b = ConsistencyMockJuly.buildCompletedGoals();
    expect(a.length, b.length);
    expect(a.first.title, b.first.title);
    expect(a.first.completedAt, b.first.completedAt);
  });
}
