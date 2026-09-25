# App Store preparation

| Item | Value |
|---|---|
| Bundle ID | `app.baton.familyCare` (register in Apple Developer portal) |
| Name / subtitle | See `release/STORE_LISTING.md` |
| Primary category | **Productivity**; secondary: Lifestyle |
| Age rating | 4+ (no objectionable content) |
| Privacy nutrition label | **Data Not Collected** |
| Privacy policy URL | Required — host reviewed `legal/PRIVACY_POLICY.md` |
| Export compliance | Uses only OS-provided encryption → exempt (`ITSAppUsesNonExemptEncryption = NO` can be added to Info.plist) |
| Sign in with Apple | Not needed (no accounts) |
| HealthKit | Not used |
| Notifications | Local only; permission requested in context (after first task assigned to me). No push entitlement needed. |
| Review notes | "Baton is a family coordination to-do app. No login. All data is stored on device. It does not provide medical advice. To test: complete onboarding with any names, add a task, assign it, tap Share update." |

## Guideline risks
- 4.2 Minimum functionality: mitigated — full task/handoff/timeline app.
- 5.1.1 Data collection: none.
- 1.4.1 / 5.1.3 Health: no health data features; boundary statement in onboarding and settings.

## Build & signing (human action)
CI runs `flutter build ios --release --no-codesign` on macOS. To ship:
1. Apple Developer Program membership ($99/yr) under the publishing legal entity.
2. Create App ID + App Store Connect record.
3. In Xcode (`app/ios/Runner.xcworkspace`) set Team; automatic signing; `flutter build ipa`.
4. Upload via Xcode Organizer or Transporter; TestFlight internal testing first.
Optional CI: fastlane match + App Store Connect API key as secrets.
