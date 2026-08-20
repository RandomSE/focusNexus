import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/debug_log.dart';

void main() {
  test('emitDebugLog remains gated when disabled (profile/release posture)', () {
    final captured = <String?>[];
    emitDebugLog('should stay silent', enabled: false, write: captured.add);
    expect(captured, isEmpty);
  });

  test('emitDebugLog writes when enabled (debug posture)', () {
    final captured = <String?>[];
    emitDebugLog('heard', enabled: true, write: captured.add);
    expect(captured, ['heard']);
  });
}
