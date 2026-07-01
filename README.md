# focusNexus


A cross-platform productivity app built with **Flutter/Dart** that helps users stay motivated through **achievement tracking, goal management, and instant feedback**. Designed with accessibility and inclusivity in mind, the app provides clear progress communication and supportive feedback tailored for neurodivergent users.

##  Features
-  Achievement tracking with streaks, rewards, and secure persistence
-  Goal management system with progress indicators
-  Instant feedback via SnackBars and automatic UI refresh
-  Accessible UI themes with customizable styling
-  Secure storage for saving achievements and points

## Development

This project targets **Flutter 3.35** (pinned in [`.flutter-version`](.flutter-version) as `3.35.7` for CI and local tooling).

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
```

Use the same Flutter version locally as CI — e.g. `flutter upgrade` to match `.flutter-version`, or [FVM](https://fvm.app/) with `fvm install` / `fvm use`.
