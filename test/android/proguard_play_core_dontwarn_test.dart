import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R8 fails minify when Flutter embedding references Play Core split-install
/// types that this app does not ship (no deferred components).
void main() {
  late String proguard;
  late String releaseDoc;

  setUpAll(() {
    proguard = File('android/app/proguard-rules.pro').readAsStringSync();
    releaseDoc = File('docs/ANDROID_RELEASE_BUILD.md').readAsStringSync();
  });

  test('proguard dontwarns unused Play Core split-install classes', () {
    const required = <String>[
      '-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication',
      '-dontwarn com.google.android.play.core.splitinstall.SplitInstallException',
      '-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager',
      '-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory',
      '-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest\$Builder',
      '-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest',
      '-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState',
      '-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener',
      '-dontwarn com.google.android.play.core.tasks.OnFailureListener',
      '-dontwarn com.google.android.play.core.tasks.OnSuccessListener',
      '-dontwarn com.google.android.play.core.tasks.Task',
    ];
    for (final rule in required) {
      expect(proguard, contains(rule), reason: 'missing R8 rule: $rule');
    }
  });

  test('release recipe does not pass invalid flutter --strip', () {
    expect(
      releaseDoc,
      contains('Could not find an option named "--strip"'),
      reason: 'DWARF --strip is gen_snapshot, not flutter CLI',
    );
    final command = RegExp(r'```bash\s*([\s\S]*?)```').firstMatch(releaseDoc);
    expect(command, isNotNull);
    expect(
      command!.group(1),
      isNot(contains('--strip')),
      reason: 'canonical flutter command must not use --strip',
    );
  });
}
