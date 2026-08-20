# Android release signing

FocusNexus release builds must use a local upload keystore. They never fall
back to the debug keystore.

## One-time setup

1. Create a keystore (run from `android/app/` or adjust `storeFile` path):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Copy the example properties file:

```bash
cp android/key.properties.example android/key.properties
```

3. Edit `android/key.properties` with real values. `storeFile` is resolved
relative to `android/app/` (for example `upload-keystore.jks` if the file
lives next to `build.gradle.kts`, or an absolute path).

## Rules

- Do **not** commit `android/key.properties`, `*.jks`, or `*.keystore`.
- If `key.properties` is missing, `assembleRelease` / `bundleRelease` will not
  use debug signing; the release build stays unsigned until you add local
  credentials.
- Keep passwords and the keystore only on the machine (or secure CI secrets)
  that produces Play Store uploads.

For release AAB builds with optional Dart obfuscation (`--obfuscate`,
`--split-debug-info`), see
[`docs/ANDROID_RELEASE_BUILD.md`](../docs/ANDROID_RELEASE_BUILD.md).
