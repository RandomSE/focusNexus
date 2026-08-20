# focusNexus

A Flutter/Dart productivity app for ADHD-friendly focus: goal management,
achievement tracking, zen garden rewards, mini-games, and accessibility-minded
UI (themes, OpenDyslexic, clear feedback). Package name: `focusNexus`.

FocusNexus is a productivity and accessibility aid. It is not medical advice,
diagnosis, therapy, or a treatment for ADHD or any other condition. Store
listing paste lines live in
[`docs/STORE_LISTING_DISCLAIMERS.md`](docs/STORE_LISTING_DISCLAIMERS.md).

## Features

- Achievement tracking with streaks, rewards, and secure persistence
- Goal management with progress indicators and reminders
- Zen garden / progressive visuals and reward loops
- Mini-games as optional focus breaks
- Instant feedback via SnackBars and automatic UI refresh
- Accessible themes and customizable styling
- Secure storage for preferences, achievements, and points

## License and legal

Source and distribution are governed by [LICENSE](LICENSE). Additional legal
documents live under [`legal/`](legal/):

- [EULA](legal/EULA.md)
- [Privacy Policy](legal/PRIVACY_POLICY.md)
- [Privacy Policy hosting (Play Console URL)](docs/PRIVACY_POLICY_HOSTING.md)
- [Play Console operator forms](docs/PLAY_CONSOLE_OPERATOR_FORMS.md)
- [Intellectual Property](legal/INTELLECTUAL_PROPERTY.md)
- [Trademark](legal/TRADEMARK.md)

Do not rewrite those documents from this README; treat them as the source of
truth.

## Android release signing

Release builds use a local upload keystore described in
[`android/SIGNING.md`](android/SIGNING.md). Never commit `key.properties` or
keystore files. Without local signing credentials, release stays unsigned
rather than falling back to debug signing.

For an optional Play AAB with Dart obfuscation and split debug info, see
[`docs/ANDROID_RELEASE_BUILD.md`](docs/ANDROID_RELEASE_BUILD.md).

Play Console **Policy / App content** forms (Data safety, content rating, privacy
URL, and related gates): [`docs/PLAY_CONSOLE_OPERATOR_FORMS.md`](docs/PLAY_CONSOLE_OPERATOR_FORMS.md).

## Prerequisites

- Flutter **3.35.7** (pinned in [`.flutter-version`](.flutter-version); used by CI)
- Dart SDK **^3.8.0** (from [`pubspec.yaml`](pubspec.yaml) `environment.sdk`)

Primary platforms: **Android** and **iOS** (`android/` and `ios/` only).

## Setup

```bash
flutter pub get
```

Match the pinned Flutter version locally (upgrade to `.flutter-version`, or use
[FVM](https://fvm.app/) with `fvm install` / `fvm use`).

Common quality checks:

```bash
flutter analyze --fatal-infos
flutter test
```

## Code generation

This project uses `riverpod_generator` (`@Riverpod` + `.g.dart`), `freezed`, and
`json_serializable`. After changing annotated models/providers (or when `.g.dart`
/ `.freezed.dart` files are missing or conflict), run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture map

Top-level under `lib/`:

`achievements`, `ai`, `app`, `assistant`, `bootstrap`, `consistency`, `goals`,
`legal`, `mini_games`, `models`, `motivators`, `progressive_visuals`,
`providers`, `repositories`, `rewards`, `screens`, `services`, `settings`,
`utils`, `views`, `widgets` (plus `main.dart`).

- **Navigation:** typed [`AppRoute`](lib/app/app_route.dart) with
  `ref.pushRoute` / related helpers in
  [`app_navigation.dart`](lib/app/app_navigation.dart).
  [`AppRouteGuard`](lib/app/app_route.dart) enforces EULA / onboarding gating.
- **Bootstrap:** [`ensureAppReady`](lib/bootstrap/app_bootstrap.dart) and related
  startup in `lib/bootstrap/` (settings, points, achievements, deferred work).

## Persistence

- Canonical keys: [`StorageKeys`](lib/services/storage/storage_keys.dart)
- Preferences: [`UserPrefsRepository`](lib/repositories/user_prefs_repository.dart)
- Secure backing store: [`FlutterSecureKeyValueStorage`](lib/services/storage/flutter_secure_key_value_storage.dart) wrapping `flutter_secure_storage`

Prefer `StorageKeys` over string literals for production and tests.

## Testing and CI

Local:

```bash
flutter test
# or a lane-sized path, e.g.
flutter test test/utils
```

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs `analyze` plus
change-detected test lanes:

| Lane | Typical paths |
|------|----------------|
| **core-heavy** | `test/goals`, `test/screens`, `test/widget`, `test/widgets`, `test/services`, `test/economy` |
| **ui-smoke** | `test/assistant`, `test/smoke`, `test/progressive_visuals`, `test/views`, `test/settings`, `test/motivators`, `test/rewards`, `test/mini_games`, `test/consistency` |
| **data-and-infra** | `test/providers`, `test/utils`, `test/models`, `test/repositories`, `test/app`, `test/bootstrap`, `test/deps`, `test/helpers`, `test/legal`, `test/widget_test.dart` |

A merge "Flutter quality gate" job requires analyze plus the lanes marked needed
for the change set.

## Debug logging

Use [`debugLog`](lib/utils/debug_log.dart) for console diagnostics. It is gated
on `kDebugMode` and is a no-op in profile/release. Do not call `print` /
`debugPrint` directly in app code (`avoid_print: true` in
`analysis_options.yaml`).

`kDebugMode` UI affordances (extra debug-only controls on screens) are fine;
console logging should still go through `debugLog`.

Note: `flutter test` always runs with `kDebugMode == true`. Release silence is
covered by the testable `emitDebugLog(enabled: false, ...)` gate in
`test/utils/debug_log_test.dart`.

## Copy style

Prefer **UK spelling** in user-facing copy where the app already does (for
example "colours").
