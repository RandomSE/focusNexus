# Android release build (Play AAB + Dart obfuscation)

This is an **operator recipe** for building a Google Play Android App Bundle
(AAB) with optional Dart obfuscation. Play Console does **not** require
obfuscation; it is proprietary hardening on top of the release pipeline.

Release **signing** is documented separately in
[`android/SIGNING.md`](../android/SIGNING.md). This file covers the Flutter
build flags and debug-info handling only.

## Prerequisites

- Flutter version matching [`.flutter-version`](../.flutter-version) (CI uses
  the same pin).
- Dependencies resolved: `flutter pub get`.
- For a **Play-uploadable** AAB: local signing per
  [`android/SIGNING.md`](../android/SIGNING.md) (`android/key.properties` and
  upload keystore). Without those files, `bundleRelease` stays **unsigned**;
  that is expected and is not a blocker for reading this doc.

## Canonical Play AAB command

From the repository root:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

Flutter prints the output path when the build finishes. Typical location:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload **only** that `.aab` to Play Console. Do not upload the debug-info
directory.

## What the flags do

| Flag | Effect |
|------|--------|
| `--release` | Release mode (AOT, no debug asserts). Required for store builds. |
| `--obfuscate` | Renames Dart identifiers in the compiled app to shorten names and make reverse engineering harder. |
| `--split-debug-info=build/debug-info` | Writes symbol / debug-info files under that directory so crash stacks from the obfuscated build can be de-obfuscated later. |

Dart obfuscation is **in addition to** Android R8 minify/shrink, which is already
enabled for release in [`android/app/build.gradle.kts`](../android/app/build.gradle.kts)
(`isMinifyEnabled = true`, `isShrinkResources = true`, ProGuard rules). R8
shrinks Java/Kotlin bytecode; `--obfuscate` targets Dart. Neither replaces the
other. Play policy does not require Dart obfuscation.

## Local notifications (R8 keep rules)

Release minify and resource shrinking can drop reminder UI that debug
`flutter run` still shows.

- Status-bar icon is a Dart string (`ic_notification` in
  `lib/utils/goal_notification_android.dart`). The shrinker cannot see that
  name. [`android/app/src/main/res/raw/keep.xml`](../android/app/src/main/res/raw/keep.xml)
  keeps `@drawable/ic_notification`.
- `flutter_local_notifications` 17.x persists schedules with Gson. The plugin
  README "Release build configuration" requires Gson keep rules in
  [`android/app/proguard-rules.pro`](../android/app/proguard-rules.pro).

Do not turn off `isMinifyEnabled` / `isShrinkResources` to "fix" missing
reminders. Keep the icon and Gson rules instead.

## Debug-info directory (keep private)

The `--split-debug-info=build/debug-info` output is **required later** to
symbolicate crash reports from obfuscated builds. Treat it like signing secrets:

- **Do not** commit it (covered by `/build/` in [`.gitignore`](../.gitignore);
  Flutter may also emit `app.*.symbols` and `app.*.map.json`, which are
  gitignored separately).
- **Do not** upload it to Play Console or ship it inside the AAB.
- **Do** keep one debug-info tree (or archive) per uploaded `versionCode` so a
  crash from `1.0.0+1` can still be matched to the symbols from that build.
- Store it on a secure operator machine or internal backup, not in public issue
  trackers.

If you lose debug-info for a given version, obfuscated stack traces for that
release cannot be fully restored.

## Operator checklist

1. Confirm Flutter matches `.flutter-version`.
2. Confirm signing setup per `android/SIGNING.md` when you need a Play-ready
   AAB.
3. Run the canonical command above.
4. Upload `app-release.aab` to Play Console.
5. Archive `build/debug-info` (or copy it elsewhere) labelled with the same
   `versionCode` / version name as the upload.
6. Do not enable `--obfuscate` on debug or profile builds unless you have a
   specific local need; this recipe is for release / Play only.

## iOS

IPA obfuscation and App Store release steps are out of scope for this document.
