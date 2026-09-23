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

AOT may print `The generated ELF library contains unobfuscated DWARF debugging
information` and suggest `--strip`. That is **not** a `flutter build appbundle`
flag (the CLI errors with `Could not find an option named "--strip"`). It is
also **not** a Gradle/R8 failure.

After Gradle finishes, Flutter checks the AAB with Android `apkanalyzer`
(from **SDK Command-line Tools**) for `libflutter.so.sym` / `libapp.so.sym`
in `BUNDLE-METADATA`. If cmdline-tools are missing, `flutter doctor` shows
that X and Flutter prints `Release app bundle failed to strip debug symbols
from native libraries` even when the AAB is already at
`build/app/outputs/bundle/release/app-release.aab` and already contains those
`.sym` files. Install **Android SDK Command-line Tools (latest)** in Android
Studio (SDK Manager → SDK Tools), then re-run `flutter doctor` until the
cmdline-tools line is clean. Do not pass `--extra-gen-snapshot-options=--strip`.

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

Flutter's embedding also references Play Core split-install classes used only
for optional deferred components. This app does not use those. R8 minify then
fails with "Missing class com.google.android.play.core...". The ProGuard file
includes `-dontwarn` for those types so release minify can finish without
adding the Play Core library.

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

## CI on merge to master

After the Flutter quality gate passes, a push to `master` runs
the `release-aab` job in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

That job:

1. Builds `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`.
2. Uploads `app-release.aab` as Actions artifact `app-release-aab` (kept 14 days).
3. Emails `RELEASE_EMAIL_TO`. If the AAB is 20 MB or smaller, the file is attached. Larger bundles are not attached; the email links to the Actions run so you can download the artifact. A local release AAB can be about 200 MB, which SMTP will reject as an attachment.

Add these under GitHub **Settings, Secrets and variables, Actions, Repository secrets**. Environment secrets are not read, because `release-aab` does not set `environment:`.

| Secret | Purpose |
|--------|---------|
| `RELEASE_EMAIL_TO` | Mailbox that receives the AAB notice |
| `SMTP_SERVER` | SMTP host |
| `SMTP_USERNAME` | SMTP user. Used as From when `SMTP_FROM` is empty |
| `SMTP_PASSWORD` | SMTP password or app password |
| `SMTP_PORT` | Optional. Defaults to 587. Use 465 for implicit TLS |
| `SMTP_FROM` | Optional From address. Use this when the SMTP username is not the mailbox |
| `ANDROID_KEYSTORE_BASE64` | Optional. One-line base64 of `upload-keystore.jks`. If unset, the AAB is unsigned |
| `ANDROID_STORE_PASSWORD` | Required when the keystore secret is set. Single line |
| `ANDROID_KEY_PASSWORD` | Required when the keystore secret is set. Single line |
| `ANDROID_KEY_ALIAS` | Required when the keystore secret is set. Single line |

On Windows, create the keystore secret value with:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\upload-keystore.jks"))
```

Paste that single line. Line breaks in the base64 value are stripped before decode. Passwords are written with `printf` so `$` inside a secret is kept as-is.

Signing files are written only on the runner (`android/key.properties` and `android/app/upload-keystore.jks`, mode 600). They are not committed. Debug symbols under `build/debug-info` are not uploaded and are not emailed.

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
7. If Flutter exits 1 after Gradle with the strip-symbols message, run
   `flutter doctor`. Missing cmdline-tools is a false fail; the AAB may
   already exist. Install cmdline-tools, then rebuild to get a 0 exit code.

## iOS

IPA obfuscation and App Store release steps are out of scope for this document.
