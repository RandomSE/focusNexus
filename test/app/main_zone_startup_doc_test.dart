import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression lock for Flutter BindingBase "Zone mismatch" at runApp.
void main() {
  test('main.dart initializes bindings inside runZonedGuarded', () {
    final source = File('lib/main.dart').readAsStringSync();
    final zoneIdx = source.indexOf('runZonedGuarded(');
    final initIdx = source.indexOf('WidgetsFlutterBinding.ensureInitialized()');
    final runAppIdx = source.indexOf('runApp(');
    expect(zoneIdx, greaterThanOrEqualTo(0));
    expect(initIdx, greaterThan(zoneIdx));
    expect(runAppIdx, greaterThan(initIdx));
  });
}
