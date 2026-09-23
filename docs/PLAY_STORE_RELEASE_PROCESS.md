# FocusNexus: GitHub repository to a live Google Play listing

This is the operator playbook for taking the current FocusNexus GitHub
repository all the way to a public production listing on the Google Play
Store. It is written against this repo as it exists today. It is not legal
advice, and it is not a substitute for the live Play Console UI (Google
renames cards often).

Related repo docs (do not duplicate their copy here; follow them):

- Signing: [`android/SIGNING.md`](../android/SIGNING.md)
- Play AAB + Dart obfuscation: [`ANDROID_RELEASE_BUILD.md`](ANDROID_RELEASE_BUILD.md)
- Privacy Policy hosting: [`PRIVACY_POLICY_HOSTING.md`](PRIVACY_POLICY_HOSTING.md)
- Console questionnaires: [`PLAY_CONSOLE_OPERATOR_FORMS.md`](PLAY_CONSOLE_OPERATOR_FORMS.md)
- Exact-alarm declaration: [`PLAY_EXACT_ALARM.md`](PLAY_EXACT_ALARM.md)
- Store listing disclaimer paste: [`STORE_LISTING_DISCLAIMERS.md`](STORE_LISTING_DISCLAIMERS.md)
- Canonical policy: [`legal/PRIVACY_POLICY.md`](../legal/PRIVACY_POLICY.md)
- Store-video shot list (media is a separate workstream):
  [`.kodaelus/play-store-user-flows.md`](../.kodaelus/play-store-user-flows.md)

Store screenshots, feature graphic, and preview video are **required by
Play Console** before production. This playbook tells you **when** those
assets are needed and what slots exist. Creating the media itself is out
of scope here.

---

## 0. What "done" means

You are finished when all of the following are true:

1. A Google Play developer account exists, is paid, and identity
   verification is complete.
2. A Play Console app exists with application id
   `com.randomse.focusnexus`.
3. A **signed** Android App Bundle (AAB) built from this repo is uploaded.
4. Play App Signing is enrolled (Play holds the app-signing key; you keep
   the upload keystore).
5. App content / policy forms are saved (privacy URL, Data safety, ads,
   IAP, content rating, target audience, exact-alarm declaration).
6. Store listing text and (separately prepared) media are complete enough
   for the chosen track.
7. If this is a **personal** developer account created after 13 November
   2023: a closed test with at least **12 testers** opted in continuously
   for **14 days** is complete, and production access is approved.
8. Production (or the first public track you chose) is reviewed and
   published.
9. The live Play listing opens the hosted Privacy Policy over HTTPS, and
   a private/incognito check of
   https://sparkling-gumdrop-1d2c86.netlify.app still shows the full
   policy.

Until those gates pass, the GitHub repo is only source code. Play does
not pull from GitHub for you.

---

## 1. Current project facts (do not invent new ones)

Treat these as the source of truth unless you deliberately change the
code and then update this file.

| Item | Value in this repo |
|------|--------------------|
| Public app name | FocusNexus |
| Android `applicationId` / namespace | `com.randomse.focusnexus` |
| Dart package name | `focusNexus` |
| First store version | `1.0.0+1` (`versionName` 1.0.0, `versionCode` 1) |
| Flutter pin | `.flutter-version` = **3.35.7** (CI uses the same pin) |
| Target / compile SDK | `flutter.targetSdkVersion` / `flutter.compileSdkVersion` (Flutter 3.35+ defaults to API **36**) |
| Min SDK | `flutter.minSdkVersion` (Flutter 3.35+ default is API **24**) |
| Owner named in legal docs | Joshua Grace |
| Governing law | Republic of South Africa |
| Play Privacy Policy URL | https://sparkling-gumdrop-1d2c86.netlify.app |
| In-app constant | `kPrivacyPolicyPublicUrl` in `lib/legal/legal_documents.dart` |
| Contact | Discord only: `kLegalContactDiscordUrl` |
| Age gate | 13+ checkbox on registration and EULA re-accept |
| Ads | None (no ads SDK) |
| In-app purchases | None (points are local rewards) |
| Accounts | Local device setup only; no Google / email / social login |
| Remote push | None (local `flutter_local_notifications` only) |
| Main-manifest `INTERNET` | Not declared. Debug/profile manifests add it for hot reload only. |
| Main permissions | `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE` |
| Backup | `android:allowBackup="false"` plus exclude-all backup / data-extraction rules |
| Release signing | Local upload keystore via `android/key.properties`. **No debug-keystore fallback.** |
| Release minify | R8 `isMinifyEnabled = true`, `isShrinkResources = true` |
| Category (operator intent) | Productivity |
| Medical claim | Explicitly **not** a medical / ADHD treatment app |

**Do not change `applicationId` after the first successful upload.** Play
treats it as the app's identity forever. The Play Console app is
`com.randomse.focusnexus`. Changing it later creates a **new** app and
loses installs, ratings, and the listing.

**Do not use the Discord invite as the Privacy Policy URL.** Discord is
contact only. Play needs a normal public HTTPS page.

---

## 2. Realistic timeline (personal account, first app)

This is an operator calendar, not a coding estimate.

| Phase | Typical elapsed time | Can overlap? |
|-------|----------------------|--------------|
| Play developer account + payment + identity verification | 1 to 14 days (sometimes longer if ID is rejected) | Start this first |
| Local Flutter pin, signing keystore, first signed AAB | Half a day if the machine is already set up | Yes, while verification runs |
| Create the Console app, fill policy forms, upload AAB to internal/closed | Half a day to 2 days | Yes |
| Closed-test **review** of the first closed-track upload (new accounts) | Hours to about 7 days | Clock for 12/14 does **not** start until testers opt in |
| Recruit 12+ testers, keep them opted in 14 continuous days | 14 days plus recruiting slack (budget 3 weeks) | Listing text and media can continue |
| Apply for production access + Google review of that application | About 1 to 7+ days | No |
| Production review of the store listing + AAB | About 1 to 7+ days (can be longer) | No |

**Budget three to six weeks** from "I have a GitHub clone" to "the app
is searchable on Play" if this is a new personal developer account.
Organization accounts (D-U-N-S) skip the 12-tester / 14-day production
lock, but business verification takes its own time.

If you must be in production **before 31 August 2026**, start the
developer account and closed test immediately. From that date, **new
apps and updates must target API 36**. This repo already follows
`flutter.targetSdkVersion`; Flutter 3.35.0+ defaults that to 36. Still
confirm the uploaded AAB's target SDK on the Console App bundle
explorer after the first upload.

---

## 3. Phase A: Google accounts, money, and identity

Play is a Google product. The GitHub repository being private does not
matter. You publish binaries, not the repo.

### 3.1 Decide personal vs organization

- **Personal:** you as Joshua Grace / an individual. One-time Play
  registration fee (historically 25 USD). After 13 November 2023, new
  personal accounts must complete closed testing (section 11) before
  Production unlocks.
- **Organization:** a registered business with a D-U-N-S number. More
  paperwork. Usually **no** 12/14 closed-test lock. Use this only if
  you actually have a legal entity you want as the seller.

For a first FocusNexus listing, personal is the default path this
playbook assumes.

### 3.2 Create or pick the Google account

1. Use a Google account you will still own in five years. This account
   becomes the Play Console owner.
2. Turn on 2-Step Verification. Play will nag; recovery after a lost
   owner account is painful.
3. Add a recovery email and phone you control.

Do **not** use a throwaway school or shared login as the owner.

### 3.3 Register as a Play developer

1. Open [Google Play Console](https://play.google.com/console).
2. Accept the Developer Distribution Agreement.
3. Pay the one-time registration fee with a card that can take an
   international charge.
4. Complete the account details: developer name (this is the public
   "offered by" name; it can be FocusNexus or your personal name),
   email, address, phone.

The public developer name is not the Android `applicationId`. You can
show "FocusNexus" or "Joshua Grace" to users. Pick something you are
willing to keep.

### 3.4 Identity verification (blocks publishing)

Google requires government-id verification for Play developers. Typical
asks:

- Legal name matching the ID
- Government photo ID
- Sometimes a selfie / liveness check
- Phone verification
- Address

Start this **before** you obsess over the AAB. An unverified account
cannot ship to production. If the name on the ID does not match the
account profile, fix the profile first.

### 3.5 Payments profile (even for a free app)

FocusNexus has **no paid download and no IAP** in this build. You still
usually must create a payments profile so Play knows who the developer
is. You will not need a merchant account unless you later add prices.

### 3.6 What you do **not** need from GitHub

- You do **not** connect the private GitHub repo to Play.
- You do **not** need GitHub Actions to upload the first AAB (this
  repo's CI analyzes and tests; it does not produce a signed Play
  bundle).
- You do **not** make the repo public for Play review. Reviewers
  install the AAB, they do not clone your source.

Keep `android/key.properties`, `*.jks`, and `*.keystore` **out** of
git. They are already gitignored.

---

## 4. Phase B: Get a clean local checkout that can build Android

### 4.1 Clone

```bash
git clone <your-private-FocusNexus-url>
cd FocusNexus
```

Use the branch you intend to ship (usually `master` after your release
commit is merged). Do not ship a dirty tree that still has debug-only
experiments you did not mean to include. The dashboard debug points
panel is already wrapped in `kDebugMode` and is stripped from release.

### 4.2 Install the **pinned** Flutter, not "whatever is on PATH"

This repo pins Flutter **3.35.7** in [`.flutter-version`](../.flutter-version).
CI uses `subosito/flutter-action` with `flutter-version-file:
.flutter-version`.

Your machine may have a newer stable (for example 3.44.x). That can
build, but it is not what CI certified. For the first Play upload,
prefer the pin:

```bash
flutter --version
# If this is not 3.35.7, install/switch to 3.35.7 (FVM, or a second SDK).
flutter pub get
flutter analyze --fatal-infos
flutter test
```

Primary platforms in this repo are Android and iOS only. You need:

- Android Studio (or at least Android SDK + command-line tools)
- An Android SDK that can compile API 36
- NDK **28.2.13676358** (already set in
  `android/app/build.gradle.kts`)
- A JDK compatible with the project (the app module uses Java 17)
- Accept Android licenses: `flutter doctor --android-licenses`

Run `flutter doctor` and fix Android toolchain rows before you try a
release bundle.

### 4.3 Confirm you are not about to upload a debug artifact

Debug and profile manifests declare `INTERNET` for hot reload. The
**main** manifest does not. Only `--release` appbundles are acceptable
for Play production. Never upload an APK from `flutter run` or a
`debug` / `profile` build.

---

## 5. Phase C: Create the upload keystore (one time, forever)

Follow [`android/SIGNING.md`](../android/SIGNING.md). The short version:

### 5.1 Generate the upload key

From a directory you will remember (often `android/app/`):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Use a strong store password and key password. The distinguished-name
fields should be **your** legal identity (they are not shown on the
store listing, but they are inside the certificate).

Validity 10000 days is about 27 years. That is intentional. If this
keystore dies and you did not enroll Play App Signing, the app is
stuck forever.

### 5.2 Create `android/key.properties`

```bash
cp android/key.properties.example android/key.properties
```

Edit real values. `storeFile` is resolved **relative to `android/app/`**
(for example `upload-keystore.jks` if the jks sits next to
`build.gradle.kts`, or an absolute path).

Example shape (do not commit real passwords):

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

### 5.3 Backup the keystore like it is money

Make **at least two** offline backups (encrypted USB, password manager
attachment, or a vault). If you lose this file after Play App Signing
is on, you can request an upload-key reset from Play. If you lose it
**and** you somehow never enrolled Play App Signing, you cannot update
the app.

Never email the jks. Never commit it. Never put it in a public gist.

### 5.4 What the Gradle file does if you skip this

`android/app/build.gradle.kts` only attaches a release `signingConfig`
when `android/key.properties` exists. If the file is missing, release
stays **unsigned**. Play will reject an unsigned AAB. That is safer
than silently signing with the debug key.

---

## 6. Phase D: Build the Play Android App Bundle

### 6.1 Canonical command

From the repository root, after `flutter pub get` and with signing in
place:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

Expected output path:

```text
build/app/outputs/bundle/release/app-release.aab
```

Details and debug-info handling:
[`ANDROID_RELEASE_BUILD.md`](ANDROID_RELEASE_BUILD.md).

### 6.2 What you upload vs what you keep

| Artifact | Upload to Play? | Keep privately? |
|----------|-----------------|-----------------|
| `app-release.aab` | **Yes** (this is the store binary) | Yes, labelled with versionCode |
| `build/debug-info/` | **No** | **Yes**, one tree per versionCode |
| `upload-keystore.jks` / `key.properties` | **No** | **Yes** |
| APK from `flutter build apk` | No (Play wants AAB for new apps) | Optional, for sideload QA only |
| Debug / profile builds | No | No |

### 6.3 Versioning rules (will reject you if you get them wrong)

`pubspec.yaml` currently has `version: 1.0.0+1`.

- `1.0.0` is `versionName` (what users see).
- `1` is `versionCode` (what Play uses). It must **increase by at least
  1** on every upload to a track that already has a bundle, including
  a re-upload after a rejected review if you change the binary.

To bump without editing `pubspec.yaml` you can pass:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info --build-name=1.0.1 --build-number=2
```

Prefer editing `pubspec.yaml` so the repo and the store stay aligned.

You cannot reuse versionCode 1 after Play has accepted it on any track.

### 6.4 Pre-upload smoke on a real device

Before the first Console upload:

1. Install the release build on a physical phone
   (`flutter install --release` after a release apk, or use
   `bundletool` to generate APKs from the AAB).
2. Walk the first-run path: auth start -> registration (EULA + 13+
   checkboxes) -> onboarding -> dashboard.
3. Create a goal, complete it, open a mini-game (Firefly Jar is free
   to unlock).
4. Enable notifications in Settings and confirm a test reminder
   behavior you can actually wait for (or a short-frequency setting).
5. Open Settings -> legal links and confirm Privacy / EULA / IP open.
6. Confirm there is **no** "Debug points to credit" field (that UI is
   `kDebugMode` only).
7. Confirm the app name under the launcher icon is FocusNexus.

If release notifications never appear, see section 18. That is the one
High engineering risk found in the readiness audit.

### 6.5 16 KB page-size and API 36

Play requires 16 KB page-size compatible native code for Android 15+
targets. Flutter 3.35+ ships an engine that meets this when you use
the pin. You do not add a special flag. After upload, open the bundle
explorer and confirm there is no 16 KB warning.

Also confirm **target SDK 36** on the uploaded bundle if you will
submit on or after 31 August 2026.

---

## 7. Phase E: Create the app in Play Console

1. Play Console -> **All apps** -> **Create app**.
2. App name: **FocusNexus** (this is the listing title; you can refine
   later within Play's length limits).
3. Default language: pick the language of your listing (English is the
   natural default for this repo's UI).
4. App or game: **App**.
5. Free or paid: **Free**.
6. Declarations: accept the Developer Program Policies and US export
   laws / declarations as they apply to you. FocusNexus is a local
   productivity client, not encryption-as-a-product and not a
   government app. Still read the checkboxes; do not click blind.

After create, you get an app dashboard with a left nav. You will live
in these areas:

- **Test and release** (testing tracks, production, App integrity)
- **Grow** / **Store presence** (main store listing)
- **Policy** / **App content** (privacy, Data safety, ratings)
- **Monitor** (pre-launch report, crashes after you have users)

---

## 8. Phase F: Store listing (text now; media later)

Play will not let you send a production release without a complete
listing. You can draft text immediately. Screenshots, feature graphic,
and optional promo video are a **separate media workstream**.

### 8.1 Main store listing fields (text)

Prepare these in a notes file before you paste:

- **App name:** FocusNexus
- **Short description** (80 characters): local productivity / focus
  helper. Do not claim medical treatment.
- **Full description:** what the app does (goals, time slots, points,
  mini-games, zen garden, accessibility). Paste the medical disclaimer
  from [`STORE_LISTING_DISCLAIMERS.md`](STORE_LISTING_DISCLAIMERS.md).
- **App category:** Productivity (or the closest current Console
  equivalent).
- **Tags:** only if they are accurate (productivity, reminders,
  habits). Do not use medical tags.
- **Contact email:** a mailbox you read. This is **not** the Privacy
  Policy URL. Discord can stay as in-app contact; Play still wants an
  email on the listing.
- **Privacy Policy URL:**
  https://sparkling-gumdrop-1d2c86.netlify.app
- **Do not use the Discord invite** in the Privacy Policy field.

Open that URL in a private window before you save. If it 404s, Play
can reject or later remove the app. Hosting steps:
[`PRIVACY_POLICY_HOSTING.md`](PRIVACY_POLICY_HOSTING.md).

### 8.2 Graphic assets (required, prepared separately)

Console will show empty slots until you add:

- High-res icon (512 x 512 PNG). This repo already has
  `assets/icon/playstore_icon.png` as a starting master; confirm it
  meets the current Play spec before upload.
- Feature graphic (1024 x 500).
- Phone screenshots (and optionally 7-inch / 10-inch tablet if you
  claim tablet support).
- Optional promo video (YouTube). Shot priority lives in
  `.kodaelus/play-store-user-flows.md`.

Do not block engineering work on these, but do not schedule a
production send until they exist.

### 8.3 Store listing hygiene that causes policy mail

- Do **not** say FocusNexus diagnoses, treats, or cures ADHD.
- Do **not** show a different app in screenshots than the AAB.
- Do **not** promise iCloud / cloud sync (this build is local-only).
- Do **not** imply ads or IAP if you declared none.
- Do **not** use other companies' trademarks as if they endorse you
  (including using the Discord wordmark beyond a "Join Discord"
  contact line).

---

## 9. Phase G: App content and policy forms (production blockers)

Fill these **before or with** the first meaningful upload. Copy answers
from [`PLAY_CONSOLE_OPERATOR_FORMS.md`](PLAY_CONSOLE_OPERATOR_FORMS.md).
Summary only:

### 9.1 Privacy policy

Paste https://sparkling-gumdrop-1d2c86.netlify.app and save.

### 9.2 Data safety

This app is local-first. Operator answer: the app does **not** collect
or share the listed user data types off the device. No encryption-in-
transit row if you declared no collection. No data sold. No ads use.
No independent security review unless you later obtain one.

In-app wipe ("Clear preferences and delete account") deletes **local**
data on that device. There is no cloud account.

If Console still asks for data-type checkboxes after "No collection",
do not invent categories. Re-read the question. Opening Discord or the
privacy page uses the system browser (`https` query only) and is not
Owner-server collection.

### 9.3 Ads

No ads. No ads SDK.

### 9.4 In-app purchases / monetization

No IAP. Points, garden, and mini-games are local rewards.

### 9.5 Content rating (IARC)

Complete the questionnaire. Operator answers in the forms doc: no
violence, no sexual content, no profanity-as-a-feature, no substances,
no gambling, no public UGC, no location sharing, no digital purchases,
target **13 and older**, not a medical app.

Submit and **apply** the resulting rating to the listing. Unrated apps
are not allowed.

### 9.6 Target audience and children

Target age **13+**. Not directed at children under 13. Do **not**
enrol in Designed for Families / Kids unless you later change the age
gate and the legal docs.

The in-app gate is a checkbox ("I confirm I am 13 or older") on
registration and on EULA re-accept. `AppRouteGuard` blocks the main
app until registration, current EULA, and onboarding are done.

### 9.7 Exact alarm declaration

When Console asks why the app uses `SCHEDULE_EXACT_ALARM`, use
[`PLAY_EXACT_ALARM.md`](PLAY_EXACT_ALARM.md):

- Local goal reminders, affirmations, and streak nudges at times the
  user chose.
- Exact alarms improve reminder precision for ADHD-friendly planning.
- If the user denies exact-alarm access, the app falls back to inexact
  scheduling.
- Not used for ads, location, or unrelated background work.

Keep `SCHEDULE_EXACT_ALARM` in the main manifest. Do not switch to
`USE_EXACT_ALARM` unless Play policy or OEM evidence requires it.

### 9.8 Other App content cards

Government apps, COVID / public-health official apps, news, financial
features, health claims: **No**, unless you later add those products.
FocusNexus is a productivity and accessibility aid.

Photo and video permissions: this app does not declare camera or
media-read permissions. Answer accordingly. Do not claim photo access
you do not have.

### 9.9 Advertising ID

No ads SDK. You should not need the advertising-id declaration as a
collector. If Console asks whether the app uses the advertising ID,
answer from the merged manifest of the **uploaded AAB**, not from
memory. The main manifest does not declare `AD_ID`.

---

## 10. Phase H: First upload and testing tracks

Play is a pipeline of tracks. You almost never throw the first AAB
straight at Production on a new personal account (Production is often
locked anyway).

### 10.1 App signing by Google Play (mandatory for new apps)

On first AAB upload, Console walks you through **Play App Signing**:

1. You upload an AAB signed with your **upload** key (the jks from
   section 5).
2. Play generates (or you export/import) the **app-signing** key that
   actually signs what users install.
3. You never need to put the app-signing key on your laptop if you let
   Play generate it. That is the recommended path for a first app.

Let Play generate the app-signing key unless you already have a reason
to bring your own. After enrollment, every future AAB must be signed
with the **same upload key**.

### 10.2 Internal testing (you and a few devices)

1. **Test and release** -> **Internal testing**.
2. Create a release, upload `app-release.aab`, name it
   `1.0.0 (1)` or similar.
3. Add testers by email (Google accounts).
4. Copy the internal opt-in link. Each tester must open that link
   **on the device**, accept, then install from Play (not a sideload).
5. Use this track to find crash-on-launch and signing mistakes fast.
   Internal testing does **not** satisfy the 12/14 production rule.

Release notes can be short: "First internal FocusNexus build."

### 10.3 Closed testing (the production key for new personal accounts)

1. **Test and release** -> **Closed testing** (often "Closed testing -
   Closed testing" or a named closed track).
2. Create a release with the **same** (or a newer) signed AAB.
3. Country availability: start with the countries you can support. For
   a first listing, "all countries" is fine for a free local app, or
   restrict to South Africa plus countries you can answer support mail
   from.
4. Add testers: email list and/or a Google Group.
5. Save and send the closed release for review if Console asks. New
   accounts often get a **review of the closed-test release itself**
   before testers can install.

Testers must:

1. Open the **official Play opt-in URL** (not an APK you emailed).
2. Become a tester.
3. Install FocusNexus from the Play Store listing that appears.
4. Keep it installed and actually open it over the next 14 days.

Sideloaded APKs do not count. Emulators usually do not count as
serious engagement.

### 10.4 Open testing (optional)

Open testing puts a Play listing in front of anyone with the link (and
sometimes search). Useful later. Not required to unlock production.
Do not start open testing until you are willing for strangers to see
the listing.

---

## 11. Phase I: The 12 testers / 14 days rule (personal accounts)

Official policy (personal accounts created after 13 November 2023):
you must run a closed test with at least **12 testers** who have been
opted in **continuously for the preceding 14 days** before you can
apply for production access.
Source: [Play Console Help: App testing requirements for new personal
developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465).

Practical rules that catch people:

- 12 **opted-in Play testers**, not 12 emails you invited.
- The 14 days must be **unbroken**. If you drop to 11, the clock
  effectively resets.
- A tester who opts out and back in restarts **their** 14 days.
- Recruit **15 to 20** people so one dropout does not kill the window.
- Ask them to open the app a few times (create a goal, complete one,
  tap a mini-game). Google has rejected "opted in but never launched"
  farms.
- You (the developer) can be one tester if you opt in with a Google
  account on a real device, but do not try to be all 12.

While the 14 days run:

- Do not yank the closed release.
- You **may** upload a newer AAB to the same closed track (bump
  `versionCode`). Testers get an update. That does not reset the
  14-day opted-in clock by itself, but a broken update that makes
  everyone uninstall **will**.
- Finish store listing text, media (separate workstream), and any
  remaining App content cards.

When Console shows that you meet the criteria, use **Apply for
production access** on the dashboard. You will answer questions about
what you tested and why the app is ready. Be specific: "12 testers
installed from the closed track, completed registration, created
goals, and used reminders on real devices."

Wait for that application to be approved. Until then, Production stays
off.

Organization / D-U-N-S accounts: confirm in **your** Console. If
Production is already available, you can skip this section.

---

## 12. Phase J: Pre-launch report, device catalog, and policy review

After a closed or internal upload, Play's pre-launch report crawls the
AAB on a farm of devices.

What to do with it:

1. Open **Monitor** / **Pre-launch report** (name varies).
2. Fix **crashes** that reproduce on API 24+ phones. A crawler that
   cannot get past your EULA checkbox is normal; a crash on launch is
   not.
3. Accessibility and screenshot warnings are usually non-blocking.
4. If the crawler flags a permission you did not expect, download the
   merged manifest from the bundle explorer and compare to
   `android/app/src/main/AndroidManifest.xml`. Plugin merge can add
   permissions. This repo's main plugins
   (`flutter_local_notifications`, `url_launcher`, `audioplayers`,
   `permission_handler`, `flutter_secure_storage`) do **not** add
   `INTERNET` or `AD_ID` in their library manifests.

Also complete:

- **App category** and store settings
- **News app** = no
- **COVID** official app = no
- **Government** app = no
- **Financial features** = no
- **Health** = not a clinical app; you already disclaim this

If review asks for a login: there is no cloud login. Reply that the
app uses on-device setup only, and give them the first-run steps
(accept EULA, confirm 13+, pick notification frequency and at least
one reward type).

---

## 13. Phase K: Production release

When production access is on:

1. **Test and release** -> **Production**.
2. Create a release.
3. Upload the AAB you want the public to have (must be a
   `versionCode` greater than or equal to what closed testing used;
   if closed already used `1`, production needs `2` **or** you
   promote the existing closed release if Console offers promote).
4. Release name: `1.0.0` is fine.
5. Release notes (user-visible "What's new"): first launch can say
   you are introducing FocusNexus as a local productivity aid. Include
   the short medical disclaimer if you have room, or keep it in the
   full description.
6. Countries: same as closed, or expand.
7. Rollout: first app can be **100%**. A staged rollout (10% / 50% /
   100%) is optional and more useful after you have crash-free days.
8. Review the **Send for review** checklist. Missing privacy URL,
   missing screenshots, missing rating, or an unanswered Data safety
   form will block send.
9. Send for review.

Review outcomes:

- **Approved:** the listing becomes public (or you can choose manual
  publish if you set that). Search and direct-link installs start.
- **Rejected:** read the email and the Policy status page. Typical
  first-app causes: privacy URL down, Data safety mismatch, medical
  claims, incomplete rating, exact-alarm justification missing,
  screenshots that do not match, or "not enough testing evidence" on
  the production-access application. Fix the stated item. Bump
  `versionCode` if you change the binary. Resubmit. Do not argue
  about a dead privacy URL; republish the Netlify page first.

---

## 14. Phase L: Day-one operator jobs after it is live

1. Install from the **public** Play link on a device that was not a
   tester (or clear the tester opt-in) and walk first run again.
2. Confirm the live Privacy Policy URL still loads.
3. Watch **Android vitals** / crashes for 48 hours.
4. Keep the `build/debug-info` tree for `versionCode` 1 somewhere
   durable so a later crash can be symbolicated.
5. Do not delete the upload keystore.
6. If you change `legal/PRIVACY_POLICY.md`, update
   `docs/privacy/index.html`, redeploy Netlify Drop, and confirm the
   **same hostname** still works. If Drop gives you a new hostname,
   you must update `kPrivacyPolicyPublicUrl`, the legal markdown, the
   HTML mirror, `STORE_LISTING_DISCLAIMERS.md`, this file, and the
   Play Console field.

---

## 15. Phase M: Every later update (the loop)

1. Change code on a branch. Keep CI green
   (`flutter analyze --fatal-infos` + sharded `flutter test` in
   `.github/workflows/ci.yml`).
2. Bump `version:` in `pubspec.yaml` (name and/or number).
   **versionCode must rise.**
3. Rebuild the signed obfuscated AAB (section 6). Archive new
   debug-info.
4. Upload to internal or closed first if the change is risky
   (notifications, signing, permissions, legal).
5. If you added a permission, a data type, ads, IAP, or a medical
   claim, **revisit App content forms before production**.
6. Production release notes: user-facing, not git-log dumps.
7. After 31 August 2026, every update must remain on target API 36+.

You still do **not** need to publish the GitHub repo.

---

## 16. Master operator checklist (print this)

### Accounts

- [ ] Google account with 2FA, recovery email, recovery phone
- [ ] Play developer registration paid
- [ ] Identity verification approved
- [ ] Payments profile created
- [ ] Developer display name chosen

### Machine and binary

- [ ] Flutter **3.35.7** (or a newer SDK you have consciously accepted)
- [ ] `flutter pub get`, analyze, and test green
- [ ] `android/key.properties` + `upload-keystore.jks` exist locally
- [ ] Keystore backed up in two places
- [ ] `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`
- [ ] `build/app/outputs/bundle/release/app-release.aab` exists
- [ ] `build/debug-info` archived as `1.0.0+1` (or current version)
- [ ] Real-device release smoke (first run, goal, notification, no debug credit UI)

### Console app

- [ ] App created: name FocusNexus, type App, free
- [ ] Play App Signing enrolled on first upload
- [ ] application id on the bundle is `com.randomse.focusnexus`
- [ ] Target SDK 36 confirmed on the bundle explorer
- [ ] No unexpected permissions on the merged manifest

### Policy

- [ ] Privacy Policy URL saved and loads in a private window
- [ ] Data safety: no collection / no sharing
- [ ] Ads = no
- [ ] IAP = no
- [ ] Content rating submitted and applied (13+)
- [ ] Target audience 13+; not Designed for Families
- [ ] Exact-alarm declaration filled from `PLAY_EXACT_ALARM.md`
- [ ] Remaining App content cards answered No where they do not apply
- [ ] Store disclaimer pasted from `STORE_LISTING_DISCLAIMERS.md`

### Listing

- [ ] Short and full description (no medical claims)
- [ ] Category Productivity
- [ ] Contact email
- [ ] High-res icon, feature graphic, phone screenshots (media workstream)
- [ ] Optional promo video (media workstream)

### Testing and production

- [ ] Internal test install works from the opt-in link
- [ ] Closed test published; testers used the Play opt-in link
- [ ] 12 testers opted in continuously for 14 days (personal accounts)
- [ ] Production access application approved (if required)
- [ ] Production release sent and approved
- [ ] Public install verified

---

## 17. Copy-paste first-run script for testers

Send this to closed testers (plain text):

1. Open the Play opt-in link I sent. Accept becoming a tester.
2. Install FocusNexus from the Play Store button that appears. Do not
   install an APK I emailed.
3. Open the app. On setup, choose a notification frequency, choose at
   least one reward type (Mini-games is fine), tick that you agree to
   the EULA / Privacy Policy / IP notice, and tick that you are 13 or
   older.
4. Finish onboarding.
5. Create one easy goal and mark it complete.
6. Open Mini-games and play one Firefly Jar round if that reward is
   enabled.
7. Leave the app installed for two weeks. Open it again on a few
   different days.
8. If Play asks for notification permission and you are willing, allow
   it. If a reminder feels too exact-alarm-heavy, you can deny exact
   alarms; reminders should still arrive, just less precisely.

---

## 18. Known High engineering risk (fix before you trust reminders in production)

Release builds enable R8 minify **and** resource shrinking
(`android/app/build.gradle.kts`). Local notifications use:

- a Dart string icon name `ic_notification`
  (`lib/utils/goal_notification_android.dart`)
- `flutter_local_notifications`, which persists schedules with Gson

The plugin README requires Gson keep rules and a resource `keep.xml`
so R8 does not discard notification drawables that Java/XML never
reference. This repo's `android/app/proguard-rules.pro` currently
keeps Flutter embedding classes only. There is no
`android/app/src/main/res/raw/keep.xml`.

That combination can make **release** reminders silently fail while
debug builds look fine. Play review may not catch it. Closed testers
will.

Before you treat the closed test as evidence that reminders work,
install the **release** AAB (not `flutter run`) and confirm a
notification actually appears. If it does not, add the plugin's Gson
rules and a `tools:keep` entry for `@drawable/ic_notification` (and
re-test). That fix is intentionally not part of this documentation
file.

---

## 19. What this playbook will not do for you

- It will not create screenshots, the feature graphic, or the trailer.
- It will not pay the Play fee or pass identity verification.
- It will not recruit your 12 testers.
- It will not give legal advice about South African consumer law, COPPA,
  or GDPR. The shipped EULA and Privacy Policy are Owner documents;
  counsel review is your choice.
- It will not publish iOS. IPA / App Store is out of scope.
- It will not upload from CI. Signing stays on the operator machine
  unless you later add your own secret store.

When the Console UI does not match a heading in this file, trust the
Console and the linked official Help articles, then update this file.
