# Play Console operator forms

Play Console questionnaires block production even when the AAB is valid.
Fill these **before** or **with** the first upload. This file is operator
copy grounded in the current app and legal docs. It is not legal advice.

Related:

- Exact-alarm declaration: [`docs/PLAY_EXACT_ALARM.md`](PLAY_EXACT_ALARM.md)
- Privacy Policy URL: [`PRIVACY_POLICY_HOSTING.md`](PRIVACY_POLICY_HOSTING.md)
- Canonical policy: [`legal/PRIVACY_POLICY.md`](../legal/PRIVACY_POLICY.md)
- Store listing disclaimers: [`STORE_LISTING_DISCLAIMERS.md`](STORE_LISTING_DISCLAIMERS.md)

## Privacy policy (required)

Paste this public HTTPS URL into Play Console (App content / Privacy policy).
In-app policy text does **not** fill that field.

https://sparkling-gumdrop-1d2c86.netlify.app

Do not use the Discord invite as the Privacy Policy URL.

## Data safety

Answer from current product behaviour (local-first; no Owner servers for
goals, settings, or progress; no ads SDK; no remote push). The app
does not collect or share listed user data types off the device.

| Console question (typical) | Operator answer |
|----------------------------|-----------------|
| Does the app collect or share any of the listed user data types? | **No.** Data stays on the device. FocusNexus does not upload goals, settings, or progress to Owner servers. |
| Encryption in transit | N/A if you declared no collection. |
| Users can request deletion | In-app Settings wipe ("Clear preferences and delete account") removes local FocusNexus data on that device. There is no cloud account to delete. |
| Account required | **No** Google / email / social account. Local setup only. |
| Data sold | **No.** |
| Data used for advertising | **No.** |
| Independent security review | **No** (unless you later obtain one). |

If Console still asks for data types after "No collection", do **not** invent
categories. Re-check that you selected no collection / no sharing. The app
does not collect location, contacts, photos, health records, financial
accounts, or device IDs for analytics.

Permissions in the main manifest are for **on-device** features only:

- `POST_NOTIFICATIONS` - local reminders
- `SCHEDULE_EXACT_ALARM` - optional exact local alarms (see exact-alarm section)
- `RECEIVE_BOOT_COMPLETED` - reschedule local notifications after reboot
- `VIBRATE` - notification haptic

There is no main `INTERNET` permission. Opening Discord or the public privacy
page uses the system browser (`https` query only).

## Ads

**No ads.** The app does not show ads and does not include an ads SDK.

## In-app purchases / monetisation

**No in-app purchases.** Points, mini-games, and garden progress are local
rewards, not paid products.

## Content rating (IARC questionnaire)

Use these answers unless the live UI changes. Target audience is **13+**
(registration / EULA age checkbox).

| Topic | Operator answer |
|-------|-----------------|
| Violence | None |
| Sexual content / nudity | None |
| Language | None (no profanity as a feature) |
| Controlled substances | None |
| Gambling / simulated gambling | None |
| User-generated public content | None. Goals and packs stay on the device; there is no public feed. |
| Location sharing | No |
| Digital purchases | No |
| Age | **13 and older** (not directed at children under 13) |
| Medical / clinical | Not a medical app. Productivity and accessibility aid only. Use the store disclaimer in [`STORE_LISTING_DISCLAIMERS.md`](STORE_LISTING_DISCLAIMERS.md). |

Submit the questionnaire and apply the resulting rating to the store listing.

## App category and news

- Category: **Productivity** (or closest Console equivalent).
- Not a news app.
- Not a government app.
- Not a COVID / public-health official app.

## Target audience and children

- Target age: **13+**.
- The app is not directed at children under 13.
- Do not enrol in Designed for Families / Kids unless you later change the
  age gate and policy.

## Exact alarm declaration

When Console asks why the app uses `SCHEDULE_EXACT_ALARM`, follow
[`PLAY_EXACT_ALARM.md`](PLAY_EXACT_ALARM.md):

- Local goal reminders, affirmations, and streak nudges at times the user chose.
- Exact alarms improve reminder precision for ADHD-friendly planning.
- If the user denies exact-alarm access, the app falls back to inexact
  scheduling and still delivers reminders at approximate times.
- Not used for ads, location tracking, or unrelated background work.

Keep `SCHEDULE_EXACT_ALARM` in the main manifest. Do not switch to
`USE_EXACT_ALARM` unless Play policy or OEM evidence requires it.

## Government / export / other App content cards

Complete any remaining App content cards (government apps, COVID, financial
features, health claims) as **No** unless you later add those features.
FocusNexus is a local productivity aid, not a clinical or financial product.

## Operator checklist (production block)

1. Privacy policy URL saved and opens in a private browser window.
2. Data safety: no collection / no sharing, consistent with
   `legal/PRIVACY_POLICY.md`.
3. Content rating questionnaire submitted; rating applied.
4. Exact-alarm declaration filled from `docs/PLAY_EXACT_ALARM.md`.
5. Ads = no; IAP = no; target audience 13+.
6. Store listing disclaimer pasted from `STORE_LISTING_DISCLAIMERS.md`.
7. Then upload the signed AAB (signing: `android/SIGNING.md`).
