import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/motivators/adhd_motivator_pack.dart';

void main() {
  test('pack has curated offline lines', () {
    expect(AdhdMotivatorPack.lines.length, greaterThanOrEqualTo(20));
    expect(AdhdMotivatorPack.lines.length, lessThanOrEqualTo(40));
  });

  test('lineAt wraps and forDate is stable per calendar day', () {
    final a = AdhdMotivatorPack.forDate(DateTime(2026, 7, 19, 8));
    final b = AdhdMotivatorPack.forDate(DateTime(2026, 7, 19, 23));
    expect(a, b);
    expect(
      AdhdMotivatorPack.lineAt(AdhdMotivatorPack.lines.length),
      AdhdMotivatorPack.lines.first,
    );
  });
}
