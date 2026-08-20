import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PLAY_CONSOLE_OPERATOR_FORMS.md covers required Console questionnaires', () {
    final doc = File('docs/PLAY_CONSOLE_OPERATOR_FORMS.md').readAsStringSync();
    expect(doc, contains('Data safety'));
    expect(doc, contains('Content rating'));
    expect(doc, contains('SCHEDULE_EXACT_ALARM'));
    expect(doc, contains('docs/PLAY_EXACT_ALARM.md'));
    expect(doc, contains('https://sparkling-gumdrop-1d2c86.netlify.app'));
    expect(doc, contains('does not collect or share'));
    expect(doc, contains('13'));
    expect(doc, contains('No ads'));
    expect(doc, contains('No in-app purchases'));
  });
}
