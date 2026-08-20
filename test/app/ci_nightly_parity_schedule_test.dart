import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ci.yml enables nightly-parity via schedule cron', () {
    final yaml = File('.github/workflows/ci.yml').readAsStringSync();
    expect(yaml, contains('nightly-parity:'));
    expect(yaml, contains("github.event_name == 'schedule'"));
    expect(
      yaml.contains(RegExp(r'schedule:\s*\n\s*-\s*cron:')),
      isTrue,
      reason: 'workflow on: must include schedule cron so nightly-parity runs',
    );
  });
}
