# PRD — Baton MVP (v0.1)

_Status: built (single-device). All success metrics are hypotheses. See PRODUCT_STRATEGY.md for why this scope._

## 1. Problem
The primary family coordinator for an aging parent holds the plan in their head and in a noisy group chat. Nobody can see at a glance **what needs to happen, who is doing it, and what already happened**, which causes dropped tasks and resentment over unequal load.

## 2. Goal of this release
Prove (or disprove) that a coordinator will **maintain a structured, owned task list and share it with the family** at least weekly — the precondition for any collaborative product.

Non-goals: multi-device sync, accounts, invites, chat, medical tracking, expenses, documents, AI.

## 3. Users
- **Coordinator** (device owner, role Owner).
- **Helpers** — named people in the circle. They receive shared text updates, or use a shared family device via the "Who's using Baton?" switcher.
- **Cared-for person** — a name/nickname only.

## 4. User stories & acceptance criteria

### Setup
**US-1** As a coordinator I can set up care for my parent in under 2 minutes.
- AC: 4-step onboarding (welcome → names → helpers → starter tasks). Only the two names are required.
- AC: Welcome screen shows the medical-boundary statement.
- AC: Duplicate/blank helper names and starter tasks are ignored.
- AC: On finish I land on Today.

### Today
**US-2** As any member I open the app and immediately see what needs to happen today.
- AC: Today shows, in order: latest handoff note (or prompt to write one), "N things need someone" banner, Overdue, Today, Coming up (7 days), Done today.
- AC: Timed items sort before all-day items; important items sort first within a slot.
- AC: Each row shows owner avatar or "Needs someone" (icon + text); overdue shows icon + "Overdue" text.
- AC: Empty state invites adding the first item.

### Tasks & appointments
**US-3** I can add a task or appointment with optional date, time, repeat, owner, place (appointments), notes and "important".
- AC: Title required, ≤120 chars; notes ≤4000; place ≤200; names ≤60.
- AC: Repeating requires a date. Options: daily, weekly, every 2 weeks, monthly.
- AC: Saving an item with the same title (case/space-insensitive) and date as an open item asks "Already on the list?".
- AC: Notes field warns against medical details.

**US-4** I can mark an item done from the list, with Undo.
- AC: Completing a repeating item creates the next occurrence (same owner); if overdue, the next date rolls forward to today or later (no pile-up).
- AC: Monthly items keep their day (31st → Feb 28 → Mar 31).
- AC: Undo/reopen removes the untouched next occurrence it created.

**US-5** I can see who is doing each item and change it.
- AC: "I'll do it" claims; "I can't do this" releases; coordinators can assign anyone.
- AC: Unassigned items offer "Ask the family chat", which shares a help request.

**US-6** I can edit and delete items; deletion is confirmed and logged.

### Handoff
**US-7** After a visit or call I can leave a note for the next person.
- AC: ≤2000 chars; "Start from today's list" drafts "Done today / Still to do / Coming up" from real data; user edits before saving.
- AC: Latest note appears on Today and in the shared update if <48h old.

### Timeline
**US-8** I can see what changed, newest first, grouped by day, filterable to notes only.
- AC: Every create/complete/reopen/assign/unassign/delete/note/member change is logged with who and when.
- AC: Entries keep readable text after items are edited or deleted.

### Family & roles
**US-9** I can add helpers by name, rename them, change their role, remove them, and transfer ownership.
- AC: Removing someone marks their open items "Needs someone" (dialog states how many) and keeps their history.
- AC: The owner cannot be removed; ownership must be transferred first.
- AC: Roles: Owner / Coordinator / Helper / Viewer, enforced as in PRIVACY_MODEL.md §Roles.

**US-10** On a shared family device, each person can pick who they are so actions are attributed correctly.

### Sharing
**US-11** I can send a clean plain-text update to my family chat through the system share sheet.
- AC: Includes overdue, today, coming up, done today, latest note (<48h), count needing someone. Never includes item notes. Optional "Sent with Baton" footer.

### Reminders
**US-12** I get reminders only for things assigned to me, at a time I choose.
- AC: Default: 1 hour before timed items; 9:00 on the day for all-day items. Options: at time, 15m, 1h, 2h, day before.
- AC: Lock-screen text hides titles and names by default.
- AC: Optional morning summary, only on days with items.
- AC: Permission is requested in context (first time something is assigned to me), never at launch; the app works fully if denied, and Settings explains how to re-enable.

### Data rights
**US-13** I can export all data as JSON and delete everything (type DELETE to confirm).

## 5. Permissions matrix
| Action | Owner | Coordinator | Helper | Viewer |
|---|---|---|---|---|
| View everything | ✓ | ✓ | ✓ | ✓ |
| Create item | ✓ | ✓ | ✓ (self or unassigned) | – |
| Edit/delete item | ✓ | ✓ | own-created or held | – |
| Complete item | ✓ | ✓ | own or unassigned | – |
| Assign | anyone | anyone | claim / release own | – |
| Handoff note | ✓ | ✓ | ✓ | – |
| Add/remove people | ✓ | ✓ (not owner/other coordinators) | – | – |
| Change roles, transfer ownership | ✓ | – | – | – |
| Settings, delete all data | ✓ | – | – | – |
| Export | ✓ | ✓ | – | – |

## 6. States & errors
- Loading → spinner; storage failure → "couldn't open its data" + Try again.
- Every write is atomic; on failure the UI shows "Something went wrong. Nothing was changed." and state is unchanged.
- Permission-denied actions are hidden/disabled; if reached, a plain message explains.
- Opening a deleted item (e.g., from a reminder) shows "This task was removed".

## 7. Accessibility
Dynamic type to 200% without overflow (tested); 48dp tap targets (tested against Android guideline); labelled tap targets (tested); status via icon + text; screen-reader labels on checkboxes ("Mark X done"); dark mode.

## 8. Privacy
See engineering/PRIVACY_MODEL.md. No account, no server, no analytics transmission, no medical fields.

## 9. Success metrics (hypotheses — see ANALYTICS.md and research/VALIDATION_DEBT.md)
- Activation (7 days): care profile + ≥3 items + ≥1 helper + ≥1 share or assignment to someone else.
- North star: completed items that had an owner, per active circle per week.

## 10. Known limitations
- No sync between phones; helpers can't update from their own phones.
- No import (export only); lost phone relies on OS backup.
- English only.
