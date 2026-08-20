import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/debug_log.dart';

void main() {
  group('emitDebugLog', () {
    test('writes when enabled', () {
      final captured = <String?>[];
      emitDebugLog('hello', enabled: true, write: captured.add);
      expect(captured, ['hello']);
    });

    test('is no-op when disabled (simulates profile/release)', () {
      final captured = <String?>[];
      emitDebugLog('silent', enabled: false, write: captured.add);
      expect(captured, isEmpty);
    });

    test('forwards null message when enabled', () {
      final captured = <String?>[];
      emitDebugLog(null, enabled: true, write: captured.add);
      expect(captured, [null]);
    });

    // flutter test always has kDebugMode == true, so release silence cannot be
    // proven by calling debugLog() alone. Prove the gate via
    // emitDebugLog(enabled: false) in the tests above.
    test('documents that flutter test always has kDebugMode true', () {
      expect(kDebugMode, isTrue);
    });
  });
}
