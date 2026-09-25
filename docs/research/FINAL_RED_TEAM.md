# Final Red Team — "If this launches tomorrow, why does it fail?"

| # | Reason | Class | Likelihood | Action taken / status |
|---|---|---|---|---|
| 1 | Siblings never touch it; it becomes the coordinator's private to-do list and adds work instead of sharing it. | ADOPTION | High | Mitigated, not solved: share-to-chat update, "Ask the family chat" per task, shared-device switcher. Real fix = sync (not built). Measured by V6/V9. |
| 2 | Coordinator expects siblings to tick things off from their own phones; discovers there's no sync and churns. | PRODUCT / TECHNICAL | High | **Disclosed** in onboarding ("Everything stays on this phone"), Family tab ("does not sync between phones yet"), store copy. Sync designed (TECHNICAL_PLAN §Sync); gated on beta evidence + credentials. |
| 3 | Store shoppers can't tell it apart from Caring Village / CircleCare / Jointly. | MARKET | High | Positioning: "works with your group chat", "no account", "not medical". Screenshots lead with owners + share. Still a real risk. |
| 4 | First run feels empty; aha moment never happens. | UX | Medium | **Fixed:** onboarding starter tasks now appear on Today under "No date yet" (previously Today was empty after setup). Handoff prompt card appears immediately. |
| 5 | Nobody pays. | MONETIZATION | High | Free during validation; fake-door price test planned; B2B2C track. No revenue claims. |
| 6 | Reminders arrive late or not at all on some Android devices (battery optimisation, inexact alarms). | TECHNICAL | Medium | Chose inexact scheduling to avoid Play exact-alarm policy; Terms state reminders may be delayed and must not be relied on for time-critical needs; QA checklist covers reboot/DST. |
| 7 | Users type medical details into notes; a lost unlocked phone or an over-shared update leaks them. | PRIVACY | Medium | Notes never included in shared updates; "avoid medical details" helper text; private lock-screen default; no transmission; export/delete. |
| 8 | Rejected or restricted by stores as a health app, or flagged for medical claims. | MEDICAL/LEGAL | Low–Medium | Category Productivity; health declaration "no health features"; boundary copy in onboarding/settings/listing; no medication or symptom features. |
| 9 | Phone replaced/lost → family history gone. | TECHNICAL | Medium | OS backup left enabled (D-012); JSON export. **No import yet** — tracked as technical debt. |
| 10 | No distribution channel; caregiver communities ban self-promotion. | DISTRIBUTION | High | Templates-first content plan; partnerships with carers' orgs; no paid acquisition before retention gate. |

Additional risks noted:
- **Shared-device roles are not security** (anyone can switch to the owner). Documented in PRIVACY_MODEL; acceptable for a family device, must be server-enforced with sync.
- **English-only**; Canada (French) and Europe need localisation.
- **Name "Baton" not cleared.**

## Verdict after final red team
Ship to a **closed beta**, not a public launch. The build is sound enough to test the behavioural hypotheses (activation, weekly reuse, share-to-chat, handoff), which is its purpose. Public launch should wait for the beta gates in VALIDATION_DEBT.md and, most likely, for sync (risk #1/#2).
