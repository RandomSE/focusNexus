import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Play Console app id is com.randomse.focusnexus. The AAB applicationId
/// must match exactly (lowercase).
const String kPlayApplicationId = 'com.randomse.focusnexus';

void main() {
  test('Android applicationId and namespace match Play Console', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "$kPlayApplicationId"'));
    expect(gradle, contains('namespace = "$kPlayApplicationId"'));
  });

  test('MainActivity uses the Play applicationId package', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      contains('android:name="$kPlayApplicationId.MainActivity"'),
    );

    final activities = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.uri.pathSegments.last == 'MainActivity.kt')
        .toList();
    expect(activities, hasLength(1));
    expect(
      activities.single.readAsStringSync(),
      contains('package $kPlayApplicationId'),
    );
  });
}
