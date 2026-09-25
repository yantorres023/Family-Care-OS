# PROJECT STATE

_Last updated: 2026-09-25 — Phase 8 (release preparation complete; awaiting human actions)_

## CURRENT PHASE
Release-ready MVP for **closed beta**. Blocked on external/human actions only (signing, store accounts, legal entity, trademark, hosting).

## CURRENT PRODUCT THESIS
**Baton** (working name): the primary family coordinator's shared to-do and handoff list for a parent's care — every task has an owner or clearly "needs someone", with a note for the next person — that **works with the family group chat instead of replacing it**. Non-medical, local-first, no account.

Decision: **PIVOT** (from broad "Family Care OS"). See research/RED_TEAM.md.

## TARGET USER
Primary coordinator (often an adult daughter, 40–64, working) for an aging parent, with 1–4 irregular helpers, currently coordinating via WhatsApp/SMS. US, UK, Canada (English).

## SUPPORTED ASSUMPTIONS (public evidence only)
- Large and growing caregiver population (63M US, 5.8M UK, 13.4M Canada).
- One primary caregiver usually carries most of the load; unequal division is the main sibling conflict source.
- Families coordinate through group chats that bury logistics.
- High app abandonment; "easy to install/learn" dominates adoption.
- Category is crowded and mostly free; incumbents lean into medication tracking.
- Notification fatigue and privacy are real adoption barriers.

## REJECTED ASSUMPTIONS
- "Everyone in the family will install a new app" (contradicted by abandonment/adoption evidence) → share-to-chat instead.
- "The product needs medical features" → deliberately excluded.
- "A broad Family OS is the right wedge" → too undifferentiated.

## UNVALIDATED ASSUMPTIONS (UNVALIDATED_WITH_REAL_USERS)
- Coordinators will maintain the list weekly.
- Share-to-chat is an acceptable collaboration bridge.
- Handoff notes create disproportionate value.
- Anyone will pay (consumer or B2B2C).
- Sync is required for retention.

## COMPLETED WORK
- Research: MARKET_RESEARCH, COMPETITORS, EVIDENCE_LEDGER, RED_TEAM (PIVOT), FINAL_RED_TEAM, VALIDATION_DEBT (+ beta gates).
- Product: PRODUCT_STRATEGY, PRD, UX_SPEC, ANALYTICS, BRAND.
- Engineering: TECHNICAL_PLAN (incl. sync design), PRIVACY_MODEL.
- Business: MONETIZATION, DISTRIBUTION.
- App (`/app`, Flutter 3.47.5): onboarding, Today, Tasks, Timeline, Family, member management & roles, item editor/detail, recurrence, appointments, handoff notes with drafts, shared-device switcher, share-to-chat, local reminders, settings, export, delete-all, on-device analytics. ~6.2k LOC app, ~2.2k LOC tests.
- Quality: `dart format` clean, `flutter analyze --fatal-infos` clean, **120 tests passing** locally.
- CI: GitHub Actions — checks + Android APK/AAB + iOS no-codesign; **all green on run 1**, run 2 checks green (builds verified via GitHub API).
- Store prep: release/STORE_LISTING, android/PLAY_STORE, ios/APP_STORE, QA_CHECKLIST, screenshots.
- Legal drafts: legal/PRIVACY_POLICY, legal/TERMS (marked for legal review).
- Landing page: landing/index.html.
- RELEASE_REPORT.md.

## KNOWN RISKS
See docs/research/FINAL_RED_TEAM.md. Top: helpers never engage; no sync; undifferentiated; no revenue; Android reminder reliability.

## BLOCKERS (human)
Release signing keys; Apple Developer + Play Console accounts; legal entity & contact details for policies; trademark clearance for "Baton"; hosting privacy policy/landing; beta recruitment.

## NEXT TASK
Human actions in RELEASE_REPORT.md → closed beta (TestFlight + Play internal) → evaluate beta gates after 4 weeks.
