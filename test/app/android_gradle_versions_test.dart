import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Flutter 3.50 dependency validation (DependencyVersionChecker) fails the
/// release bundle when Gradle is below 9.3.1, AGP is below 9.1.1, or Kotlin
/// is below 2.4.10. These pins sit at Flutter's warn floors so the check
/// neither throws nor logs a soon-dropped warning.
void main() {
  test('Gradle wrapper is Flutter 3.50 warn floor 9.5.0', () {
    final wrapper = File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync();
    expect(wrapper, contains('gradle-9.5.0-all.zip'));
  });

  test('AGP and Kotlin are Flutter 3.50 warn floors', () {
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    expect(
      settings,
      contains('id("com.android.application") version "9.3.1"'),
    );
    expect(
      settings,
      contains('id("org.jetbrains.kotlin.android") version "2.4.20"'),
    );
  });

  test('App Gradle uses built-in Kotlin compilerOptions', () {
    final app = File('android/app/build.gradle.kts').readAsStringSync();
    final properties = File('android/gradle.properties').readAsStringSync();
    expect(app, contains('jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17'));
    expect(app, isNot(contains('id("kotlin-android")')));
    expect(app, isNot(contains('kotlinOptions')));
    // Flutter 3.50 rewrites these opt-outs on every build. Keep them.
    expect(properties, contains('android.builtInKotlin=false'));
    expect(properties, contains('android.newDsl=false'));
  });
}
