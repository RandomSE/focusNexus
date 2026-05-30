import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards against assembleDebug/kernel failures when [freezed_annotation] is missing
/// from [pubspec.yaml] dependencies or `flutter pub get` was not run after adding it.
void main() {
  test('freezed_annotation resolves (freezed sentinel and @Default)', () {
    expect(freezed, isA<Freezed>());
    expect(const Default(false), isA<Default>());
  });
}
