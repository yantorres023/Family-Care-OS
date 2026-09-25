# Google Play preparation

| Item | Value |
|---|---|
| Package | `app.baton.family_care` |
| Category | **Productivity** (alt: Lifestyle). _Not_ Medical / Health & Fitness — the app has no health features, and Play no longer allows Individual accounts to publish in health categories. |
| Content rating | Everyone (IARC questionnaire: no violence, no UGC sharing within app, no location) |
| Target audience | 18+ |
| Ads | No |
| In-app purchases | No (v0.1) |
| Health apps declaration | Complete it: **"My app does not have any health features"** (coordination/organisation only). Required for all apps. |
| Data safety | **No data collected. No data shared.** (No data transmitted off-device by the developer; user-initiated share sheet is not developer collection.) Declare: data deletion available in-app. |
| Permissions | `POST_NOTIFICATIONS` — "Reminders for tasks assigned to you." `RECEIVE_BOOT_COMPLETED` — "Restore scheduled reminders after the phone restarts." No exact-alarm, location, contacts, camera, storage permissions. |
| Min / target SDK | Flutter defaults (minSdk from `flutter.minSdkVersion`; targetSdk from Flutter 3.47.5 — verify it meets Play's current target API requirement at submission) |
| App signing | Play App Signing + upload key (**human action**; currently debug-signed) |
| Testing track | Internal testing → closed testing (≥12 testers for 14 days is required for new personal developer accounts) |

## Build
`cd app && flutter build appbundle --release` (CI produces an unsigned-for-store, debug-signed AAB as an artifact; replace signing before upload).

## Release signing (to do)
1. `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `app/android/key.properties` (never commit) with storePassword/keyPassword/keyAlias/storeFile.
3. Update `app/android/app/build.gradle.kts` `signingConfigs.release` to read key.properties; set `buildTypes.release.signingConfig` to it.
4. Store the keystore + passwords as GitHub Actions secrets if CI should sign.
