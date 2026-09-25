# Technical Plan

## Stack
Flutter 3.47.5 (stable) / Dart 3.13. Targets Android and iOS. App lives in `/app`.

| Concern | Choice | Why |
|---|---|---|
| State | `CareStore` (`ChangeNotifier`) + `StoreScope` (`InheritedNotifier`) | One small store; no state-management dependency (D-008) |
| Navigation | `Navigator` + `MaterialPageRoute`; `IndexedStack` for tabs | 4 tabs + a few pushed screens; no router needed |
| Storage | `sqflite` (SQLite), hand-written migrations | Durable, transactional, testable via `sqflite_common_ffi` |
| Dates | `CivilDate` + minutes-of-day | Wall-clock semantics; DST-safe (D-009) |
| Notifications | `flutter_local_notifications` + `timezone` + `flutter_timezone` | Local only, inexact scheduling (no exact-alarm permission) |
| Sharing | `share_plus` | OS share sheet → WhatsApp/SMS/email |
| IDs | `uuid` v4 | Sync-ready globally unique ids |
| Formatting | `intl` with device locale | 12/24h and date order follow the phone |

## Layers
```
lib/
  core/       CivilDate, Clock, formatting
  domain/     models, recurrence, permissions, TodayView, ShareSummary,
              ReminderPlanner, handoff suggestion   ← pure Dart, unit-tested
  data/       CareRepository (interface), ChangeSet, SqliteCareRepository,
              InMemoryCareRepository
  services/   NotificationService, ShareService, Analytics (+ fakes)
  state/      CareStore (commands, permission checks, activity log), StoreScope
  ui/         screens/, widgets/, theme
```
Rules: domain has no Flutter imports except `intl`; UI never talks to the repository directly; every write is a `ChangeSet` applied atomically, and memory is updated only after the write succeeds.

## Data model (schema v2)
`circles`, `members` (soft-remove via `removed_at`), `items` (tombstone via `deleted_at`, `series_id` links recurrences, `anchor_day` for monthly), `handoffs`, `activity` (append-only, human-readable snapshot), `settings` (key/value), `analytics_events` (capped). Migrations are an append-only list (`migrations[]`); downgrade throws rather than corrupting. v1→v2 upgrade is tested with real data.

## Recurrence
Completing an occurrence spawns the next as a new row in the same series (D-010). Overdue → roll forward to ≥ today. Reopen removes the untouched spawned copy. A second copy is never spawned while one is open.

## Notifications
`ReminderPlanner` (pure) computes the full desired set; `LocalNotificationService.replaceAll` cancels everything and schedules exactly that set after each change and at launch. Cap 48 (iOS allows 64 pending). Horizon 30 days. `AndroidScheduleMode.inexactAllowWhileIdle`; Android channel importance default, visibility private. iOS permission is not requested at init; requested in context. Tapping a reminder opens the item.

## Offline behaviour
Always offline; there is no network code. Share sheet is the only outbound path and is user-initiated.

## Sync (not built — design for the next phase)
Why not now: no credentials in this run; Supabase free tier pauses after 7 days idle; server-side family data needs a reviewed security posture (D-005).

Planned design:
1. **Backend:** Supabase (Postgres + Auth + RLS) or Firebase (Firestore + rules). Preference: Supabase for SQL/RLS parity with the local schema.
2. **Identity:** email magic link / Sign in with Apple / Google. Members gain an optional `user_id`.
3. **Invites:** owner/coordinator creates an invite code (random 128-bit, stored hashed, expires in 7 days, single use, role pre-set, revocable). Accepting links the user to an existing named member (so history stays attributed).
4. **Authorization:** the same `PermissionPolicy` rules re-implemented as RLS policies; client checks remain for UX only.
5. **Replication:** each row has `updated_at`; push local `ChangeSet`s as an outbox; pull by `updated_at > cursor`. Conflict rule: last-writer-wins per row, except (a) completion wins over edits, (b) tombstones win, (c) activity/handoffs are append-only (no conflicts).
6. **Removal/revocation:** removing a member deletes their circle membership server-side; RLS denies further reads; their device purges the circle on next sync.
7. **Deleted circle:** owner-only; server tombstones then hard-deletes after 30 days; all devices purge.
8. **Contract tests:** `test/data/repository_contract.dart` must pass for the sync repository.

## Testing
| Layer | What | Where |
|---|---|---|
| Domain | dates, DST, month-end, recurrence roll-forward, permissions matrix, Today bucketing/sorting, share text (incl. notes never included, emoji, caps), reminder planning (lead across midnight, private text, cap, digest), time-zone conversion in NY/London DST, analytics sanitiser, handoff drafting | `test/domain/` |
| Data | repository contract (in-memory + SQLite), round-trip of every field incl. SQL-injection-like text and 4000-char notes, v1→v2 migration, downgrade refusal, corrupt enum/date degradation, analytics cap | `test/data/` |
| State | setup validation, persistence across reload, duplicate detection, recurrence spawn/undo, member removal releases tasks, owner protection & transfer, helper/viewer enforcement, reminders reschedule/permission-once/denied, share, export, delete-all, failed-write consistency | `test/state/` |
| UI | onboarding end-to-end, Today sections, complete+undo, editor, duplicate dialog, handoff drafting, member removal, actor switch, share, timeline filter, delete-all confirm, 200% text, tap-target guidelines | `test/ui/` |

Not testable here: real notification delivery, share sheet on device, OS backup/restore. Covered by the manual QA script in `release/QA_CHECKLIST.md`.

## CI (`.github/workflows/ci.yml`)
1. `checks` (ubuntu): `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test`.
2. `android` (ubuntu, JDK 17): `flutter build apk --release`, `flutter build appbundle --release` (debug-signed), artifacts uploaded.
3. `ios` (macOS): `flutter test`, `flutter build ios --release --no-codesign`, zipped `Runner.app` uploaded.

## Android specifics
`applicationId app.baton.family_care`; core-library desugaring (required by notifications); permissions: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` only; no exact alarms; release signing currently uses debug keys → **must be replaced** (see RELEASE_REPORT.md).

## iOS specifics
Bundle id `app.baton.familyCare`; display name "Baton"; UIScene lifecycle (Flutter default); `UNUserNotificationCenter` delegate set in `AppDelegate`. Signing/provisioning is a human action.
