# RELEASE REPORT — Baton (Family Care OS) v0.1.0

_Date: 2026-09-25. Autonomous run; no human input, no interviews, no users._

## Executive summary
Public evidence supports a real, large, growing problem: one family member usually coordinates a parent's care, siblings argue about uneven load, and logistics get lost in group chats. It also shows that a broad "Family Care OS" would be a me-too in a crowded, mostly free category that assumes every relative will install a new app.

The run therefore **pivoted** to a narrow wedge and built it: **Baton**, a coordinator-first, non-medical, local-first Flutter app where every task has an owner or clearly "needs someone", handoff notes tell the next person what happened, and one tap sends a clean update to the family chat. It builds for Android (APK + AAB) and iOS (unsigned release) in CI, passes 120 automated tests, and has analyzer-clean code. It is ready for a **closed beta**, not a public launch, and it does **not** yet sync between phones.

## Decision: **PIVOT**
From "shared OS for the whole family" to "the coordinator's shared to-do + handoff list that works with the group chat". Rationale: research/RED_TEAM.md (broad idea fails on WhatsApp-good-enough, install friction, invite friction, and existing products).

## Final product thesis
> Know what needs doing for Mom today, who's on it, and what already happened — without chasing people in the group chat.

## ICP
Primary family coordinator (most often an adult daughter aged 40–64, working) for an aging parent, with 1–4 irregular helpers, some long-distance; practical/logistical care needs; English-speaking US/UK/Canada.

## Evidence strength
**Moderate for the problem, weak for the solution.** All secondary evidence, gathered by web search. Direct page fetches were blocked by the sandbox, so figures come from search extracts and must be re-verified.
- Strong: population size (AARP/NAC 2025: 63M US; Carers UK: 5.8M; StatCan: 13.4M); primary-caregiver pattern and sibling conflict (peer-reviewed); high app abandonment (JMIR scoping review, median 70% in 100 days).
- Moderate: group chats bury logistics (forums, qualitative); handoff logs are a real practice (paper log books and templates on sale).
- Weak/none: willingness to pay for coordination software; whether share-to-chat or handoff notes change behaviour.

## Counter-evidence
- Free incumbents already cover tasks and calendars (Lotsa, CaringBridge Planner, ianacare, Caring Village free tier); Jointly costs £2.99 one-off.
- Many families find WhatsApp "good enough".
- Caregivers rate "communicating with the health-care team" as a top technology use (60.5%), a medical-adjacent need Baton deliberately doesn't serve.
- InfoSAGE (an institution-backed family coordination platform) got little organic uptake.

## What was built (`/app`)
- **Onboarding** (4 steps, only two names required, medical-boundary notice).
- **Today:** latest handoff note (or a prompt to write one), "N things need someone" banner, then Overdue / Today / Coming up (7 days) / No date yet / Done today, plus "Send update to family chat".
- **Tasks and appointments:** owner, date, optional time, repeats (daily, weekly, every 2 weeks, monthly with month-end anchoring), place, notes, important flag, duplicate warning, complete with Undo, "I'll do it", "I can't do this", "Ask the family chat".
- **Timeline:** every change logged with who and when; "Notes only" filter.
- **Handoff notes:** "What should the next person know?", with a draft built from today's list.
- **Family:** helpers added by name, 4 roles (Owner, Coordinator, Helper, Viewer), rename, change role, transfer ownership, remove (open tasks become "needs someone", history kept), shared-device "Who's using Baton?" switcher.
- **Reminders:** on-device only, for items assigned to me, lead time configurable, lock-screen text private by default, optional morning summary, permission asked in context, app works if it's denied.
- **Settings and data rights:** export all data as JSON, delete all (type DELETE), on-device usage counts, about/boundary.
- **Screenshots:** `release/screenshots/` (fictional data).

## Collaboration architecture
**Implemented:** a single device, plus a shared-device mode, plus share-to-chat. **Not implemented:** multi-device sync, accounts, invites. The app does not claim collaboration it lacks; the UI says "does not sync between phones yet". The repository interface, ChangeSet writes, UUIDs, `updated_at` fields, tombstones and a shared contract test suite are in place for a sync backend. The full design (Supabase + RLS, hashed expiring invite codes, conflict rules, revocation, circle deletion) is in docs/engineering/TECHNICAL_PLAN.md §Sync.

## Privacy model
No account, no server, no telemetry, no ads or trackers. Data lives in on-device SQLite. The only outbound path is the user-initiated share sheet, and item notes are never included in shared text. No medical fields. Lock-screen text is private by default. Store labels: Apple "Data Not Collected"; Play "No data collected/shared". Details: docs/engineering/PRIVACY_MODEL.md.

## Medical boundary
No diagnosis, symptoms, medication or dosage, vitals, triage or health claims. A boundary statement appears in onboarding, settings, store copy, terms and the landing page. Notes fields warn against entering medical details. Store category: Productivity.

## Tests
- **120 automated tests, all passing**: domain (dates, DST, month-end, recurrence, permissions, Today, share text, reminders including New York/London DST, analytics sanitiser, handoff drafts), data (contract tests on in-memory and SQLite, every field round-trips, v1→v2 migration, refusal to downgrade, corrupt-data handling), state (ownership, member removal, helper/viewer enforcement, reminders, permission denied, export, delete-all, failed-write consistency), UI (onboarding end to end, completion + undo, editor, duplicate dialog, handoff, member removal, share, timeline, delete-all, **200% text scale**, **tap-target and labelled-target guidelines**).
- `dart format`: clean. `flutter analyze --fatal-infos`: no issues.
- Not automatable here (see release/QA_CHECKLIST.md): real notification delivery, share sheet, OS backup.

## Android
The container couldn't build Android: dl.google.com is blocked, so the Android SDK couldn't be installed. **CI builds it on GitHub Actions: `flutter build apk --release` and `flutter build appbundle --release` succeeded** on every pushed commit, most recently the final head `c6bdf79` (run [36148486735](https://github.com/yantorres023/Family-Care-OS/actions/runs/36148486735), artifacts uploaded). These builds are **debug-signed**; release signing is a human action. Only two permissions: `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`. There is no exact-alarm permission.

## iOS
The macOS CI job ran `flutter test` and **`flutter build ios --release --no-codesign`, and both succeeded** (final head: run [36148486735](https://github.com/yantorres023/Family-Care-OS/actions/runs/36148486735)). The unsigned Runner.app is uploaded as an artifact. Signing and provisioning need an Apple Developer account.

## Monetization
Free during validation. The next step is a fake-door price test ($19/$29/$39 per year, one payer per family) at the point where users ask for sync, alongside a B2B2C track (employers, UK carers' organisations and councils). Ads and data sale are rejected. Details: docs/business/MONETIZATION.md.

## Distribution
Templates-first content for the coordinator's search moments, and genuine participation in caregiver communities following their rules. Partnerships with carers' organisations and employers. The shared update carries an optional "Sent with Baton" footer that works as the referral surface. The docs include 10 content ideas and 10 SEO targets. **No outreach was performed.**

## Known bugs / limitations
- No sync between phones. Helpers can only participate via the family chat or a shared device.
- On a shared device, roles guard against mistakes, not against misuse: anyone holding the phone can switch to the owner.
- Export only. There is **no import**, so moving to a new phone relies on the OS backup.
- Reminders use inexact scheduling and may drift by several minutes. Aggressive OEM battery savers may delay them.
- English only.
- Share success on some Android share targets reports "unavailable" and is counted as success in analytics.
- Screenshot goldens render card shadows as outlines (a test-environment artifact, not an app bug).

## Technical debt
- Sync backend and invites (designed, not built).
- Data import/restore.
- Opt-in remote telemetry for beta metrics (currently on-device only).
- No integration tests on real devices.
- Localization (fr-CA, es-US).
- The `tool/screenshots_test.dart` font paths point at the local Flutter SDK cache.

## External blockers
Signing credentials, store accounts, legal identity, trademark clearance, hosting, beta testers. None of these can be done autonomously.

## HUMAN_ACTION_REQUIRED

| # | ACTION | WHY | EXACT STEPS |
|---|---|---|---|
| 1 | Clear the name "Baton" | Avoid a forced rename after launch | Search USPTO, UKIPO and CIPO in classes 9 and 42. Search App Store/Play for "Baton". Register a domain. If blocked, pick from docs/product/BRAND.md and update `android:label`, `CFBundleDisplayName`, store copy and the landing page. |
| 2 | Choose the legal entity and fill the policy placeholders | Stores require a privacy policy URL and support contact | Fill `[brackets]` in legal/PRIVACY_POLICY.md and legal/TERMS.md. Get legal review (UK GDPR/GDPR, CCPA, PIPEDA, consumer law). Host at a public URL. |
| 3 | Create the Android upload key and release signing | CI builds are debug-signed and Play rejects them | Follow release/android/PLAY_STORE.md §Release signing. Add the keystore and passwords as GitHub secrets if CI should sign. |
| 4 | Set up Google Play Console | Publishing | Create the developer account (an Organization account is recommended). Create the app with package `app.baton.family_care`. Complete Data safety ("no data collected"), the Health apps declaration ("no health features"), content rating and target audience 18+. Upload the AAB to Internal testing, then Closed testing. |
| 5 | Set up the Apple Developer Program and signing | Needed for an iOS build users can install | Enroll ($99/yr). Register bundle id `app.baton.familyCare`. Create the App Store Connect record. Open `app/ios/Runner.xcworkspace` in Xcode, set the Team and use automatic signing. Run `flutter build ipa`, upload, and start TestFlight. Privacy label: Data Not Collected. |
| 6 | Verify the Play target API level at submission | Play raises the minimum every year | Check `targetSdk` in the built AAB against current Play policy. Bump the Flutter version if needed. |
| 7 | On-device QA | Notifications, share and backup can't be tested in CI | Run release/QA_CHECKLIST.md on 2 Android and 2 iOS devices. |
| 8 | Recruit 30–50 beta coordinators | Validation is the purpose of v0.1 | Use the templates-first plan in docs/business/DISTRIBUTION.md. No fake users, no incentives that bias answers. |
| 9 | Decide on beta telemetry | Beta gates need aggregate metrics | Either collect data manually (weekly screenshots of Settings → Usage counts, plus surveys) or approve an opt-in telemetry design (PRIVACY_MODEL §Future) before building it. |
| 10 | Host the landing page | Waitlist and privacy URL | Serve `landing/` (for example GitHub Pages or Netlify). Replace `[WAITLIST_EMAIL]`. |

## Real-user validation debt
Everything about behaviour is unvalidated: activation, weekly reuse, whether helpers engage, share-to-chat, handoff value, notification annoyance, WhatsApp preference and willingness to pay. Full table (hypothesis, metric, pass, fail, cheapest test): docs/research/VALIDATION_DEBT.md.

## Beta metrics and kill/pivot thresholds (experimental)
| Metric | Continue | Kill/pivot |
|---|---|---|
| Activation (profile + ≥3 items + ≥1 helper + share/assign) | ≥40% | <20% |
| Week-2 retention | ≥35% | <15% |
| Weekly completed owned tasks per active circle | ≥5 | <2 |
| Multi-member signal (shared-device actors or weekly share) | ≥40% | <15% |
| Reminder disable rate by day 30 | ≤15% | ≥35% |
| "Very disappointed" (Sean Ellis) | ≥40% | <20% |
| Sync fake-door tap rate | ≥5% | <2% |

**Rules:** if activation is under 20% *and* retention under 15%, stop or go content-only. If the product retains users but the multi-member signal is under 15%, reposition it as a personal organiser or stop. If the multi-member signal is at least 40% and users ask for sync, build sync as the paid family plan.

## Next 3 experiments
1. **Template demand test** (1 week, no app): publish the "weekly family update" and "handoff note" templates and measure signups.
2. **Closed beta** (4 weeks, 30–50 coordinators via TestFlight and Play internal testing), evaluated against the gates above.
3. **Sync fake door with price cells**, built into the beta, to test collaboration demand and willingness to pay before building a backend.

## Files to review first
1. `docs/research/RED_TEAM.md`: why we pivoted.
2. `docs/research/EVIDENCE_LEDGER.md`: what's supported and what isn't.
3. `docs/product/PRODUCT_STRATEGY.md` and `docs/product/PRD.md`.
4. `app/lib/state/care_store.dart`: all user commands and rules.
5. `app/lib/domain/`: recurrence, permissions, share text, reminders.
6. `docs/engineering/PRIVACY_MODEL.md` and `legal/`.
7. `release/screenshots/`: what it looks like.
8. `docs/research/VALIDATION_DEBT.md`: what to learn next.

## Definition of done
- [x] research
- [x] evidence ledger
- [x] competitor analysis
- [x] GO/PIVOT/STOP → **PIVOT**
- [x] product strategy
- [x] PRD
- [x] UX spec
- [x] technical plan
- [x] working Flutter app
- [x] task workflow
- [x] Today
- [x] ownership
- [x] appointments/events
- [x] timeline
- [x] handoff
- [x] notifications (local)
- [x] collaboration: **explicitly documented limitation** (shared device + share-to-chat; sync designed, not built)
- [x] privacy review
- [x] tests (120)
- [x] analyzer clean
- [x] Android CI (APK + AAB built)
- [x] iOS CI (no-codesign build)
- [x] monetization
- [x] growth
- [x] store preparation
- [x] validation debt
- [x] RELEASE_REPORT.md
