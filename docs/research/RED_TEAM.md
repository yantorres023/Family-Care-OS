# Red Team — assume the idea is bad

_Premise tested: "Family Care OS — keep your family coordinated around the people you care for." Each attack is scored on how much public evidence supports it (1 weak – 5 strong) and whether it is fatal to the broad idea, and to the narrowed wedge._

| # | Attack | Evidence strength | Fatal to broad "Family Care OS"? | Fatal to narrowed wedge? | Response |
|---|---|---|---|---|---|
| 1 | **WhatsApp is good enough.** | 4 — everyone has it; families already divide tasks there. | Largely yes: a second messaging surface loses. | No, if we don't compete on messaging. | No chat in MVP. Structured ownership/status + handoff, with **share-to-chat** export. |
| 2 | **Family members won't install another app.** | 4 — 70%/100-day abandonment; InfoSAGE uptake. | Yes — broad OS needs everyone. | No — coordinator gets value solo; helpers can stay in chat. | Single-player value first. Collaboration optional. |
| 3 | **Older adults won't use it.** | 2 — they're not the target user. | Partial. | No. | Cared-for person is a *profile*, not a user. Large-text friendly UI. |
| 4 | **People won't pay.** | 4 — category is mostly free; complaints about $15/mo. | Threatens consumer business. | Threatens business, not validation. | Launch free; test WTP by fake door; B2B2C track. See MONETIZATION.md. |
| 5 | **Coordination is too irregular; the app gets forgotten.** | 3 — crisis-driven bursts. | Yes for heavy OS. | Partial. | Recurring tasks (bills, weekly groceries) create a steady cadence; low-effort re-entry via Today. |
| 6 | **Notifications become noise.** | 3 | Partial. | Partial. | Coordinator-only local reminders, per-type toggles, quiet by default, no content on lock screen by default. |
| 7 | **Health/privacy concerns too high.** | 3 | Yes if meds/records. | Low risk. | No medical fields; local-only storage; no account; no analytics SDK. |
| 8 | **Inviting family creates friction.** | 4 | Yes. | Avoided in MVP (no invites needed). | "Helpers" are names the coordinator adds; invites deferred to cloud phase. |
| 9 | **Products already solve this.** | 4 — Caring Village, CircleCare, Jointly, Lotsa, ianacare. | Yes — undifferentiated. | Partial. | Differentiate on: non-medical, reliable, local-first, works-with-group-chat, handoff. Still a real risk. |
| 10 | **Users actually need medical systems (portals, med management).** | 2–3 | n/a | No — we explicitly refer out. | Boundary statement in app; no clinical features. |

## Additional attacks

- **"Single-device MVP doesn't prove collaboration."** True. It proves *the coordinator will maintain a structured list and share it*. That is a necessary precondition for collaboration; if coordinators won't maintain it alone, sync won't save it. Documented as a compromise, not a claim.
- **"Share-to-chat is just a to-do app with a share button."** Partially true. The defensible parts are the care-specific model (owner per item, recurrence of care chores, handoff note, activity log, helper roster) and the formatting of the summary. Differentiation is thin; this is a validation vehicle, not a moat.
- **"Local-only means data loss if phone is lost."** True. Mitigation: plain-text/JSON export; cloud backup deferred. Documented risk.

## Verdict on the original broad thesis

The broad "Family Care OS" (tasks + calendar + meds + documents + expenses + chat for the whole family) **fails** attacks 1, 2, 8 and 9: it competes head-on with free incumbents and requires every family member to adopt it.

A narrower wedge survives: **the primary coordinator's "who's doing what" list + handoff log, non-medical, that feeds the existing family group chat.** It survives 1, 2, 3, 7, 8, 10; partially survives 5, 6, 9; and remains exposed on 4 (monetization) — acceptable for an MVP whose purpose is validation.

Pivot wedges tested (policy allows ≤2):
1. **Coordinator-first task + handoff (chosen).**
2. Shared expense ledger for siblings — strong conflict evidence but requires multi-party participation to have any value (fails attack 2 harder). Deferred to post-collaboration.

## DECISION

**PIVOT**
