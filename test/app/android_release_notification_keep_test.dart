import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/utils/goal_notification_android.dart';

void main() {
  late String keepXml;
  late String proguard;
  late String gradle;

  setUpAll(() {
    keepXml = File('android/app/src/main/res/raw/keep.xml').readAsStringSync();
    proguard = File('android/app/proguard-rules.pro').readAsStringSync();
    gradle = File('android/app/build.gradle.kts').readAsStringSync();
  });

  test('release shrinks resources so Dart-string icons need keep.xml', () {
    expect(gradle, contains('isMinifyEnabled = true'));
    expect(gradle, contains('isShrinkResources = true'));
    expect(gradle, contains('proguard-rules.pro'));
  });

  test('keep.xml retains the status-bar drawable named in Dart', () {
    expect(keepXml, contains('tools:keep'));
    expect(
      keepXml,
      contains('@drawable/${GoalNotificationAndroid.androidStatusBarIcon}'),
    );
    expect(
      File(
        'android/app/src/main/res/drawable-mdpi/'
        '${GoalNotificationAndroid.androidStatusBarIcon}.png',
      ).existsSync(),
      isTrue,
    );
  });

  test('proguard-rules.pro includes flutter_local_notifications Gson keeps', () {
    expect(proguard, contains('-keepattributes Signature'));
    expect(proguard, contains('-keepattributes *Annotation*'));
    expect(proguard, contains('com.google.gson.TypeAdapter'));
    expect(proguard, contains('com.google.gson.TypeAdapterFactory'));
    expect(proguard, contains('com.google.gson.JsonSerializer'));
    expect(proguard, contains('com.google.gson.JsonDeserializer'));
    expect(proguard, contains('com.google.gson.annotations.SerializedName'));
    expect(proguard, contains('com.google.gson.reflect.TypeToken'));
    expect(proguard, contains('-keep class com.dexterous.** { *; }'));
  });
}
