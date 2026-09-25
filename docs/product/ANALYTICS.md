# Analytics Plan

_All metrics are hypotheses. In v0.1 events are **stored only on the device** (`analytics_events` table, capped at 1,000 rows) and viewable in Settings → Usage counts. Nothing is transmitted. A beta that needs aggregate metrics must add explicit opt-in telemetry (see PRIVACY_MODEL.md §Future)._

## Event catalogue (implemented in `lib/services/analytics.dart`)
| Event | When | Properties (allow-listed, no free text) |
|---|---|---|
| `family_created` | setup completes | – |
| `care_profile_created` | setup completes | – |
| `onboarding_completed` | setup completes | `helpers` (int), `starter_tasks` (int) |
| `member_invited` | a helper is added (MVP: by name, no invite) | `method=local_name`, `role` |
| `task_created` | task created | `recurring`, `has_time`, `assigned`, `source` |
| `event_created` | appointment created | same as above |
| `task_assigned` | owner set/changed | `self` |
| `task_completed` | item completed | `by_assignee`, `was_assigned`, `recurring`, `overdue_days` |
| `handoff_added` | note saved | `length_bucket` (short/medium/long) |
| `timeline_viewed` | Timeline tab opened | – |
| `notification_opened` | reminder tapped | – |
| `update_shared` | share sheet completed (not dismissed) | – |
| `help_requested` | "Ask the family chat" completed | – |

Privacy guard: `sanitizeProps` drops any property whose value is not a bool, a small int, or a `snake_case` token ≤32 chars — so titles, names and notes can never be logged (unit-tested).

## Candidate metrics
- **Activation (7 days from install):** care profile created AND ≥3 items AND ≥1 helper added AND (≥1 `update_shared` OR ≥1 `task_assigned` with `self=false`).
- **North star:** completed items with an owner (`task_completed` where `was_assigned=true`) per active circle per week.
- **Collaboration proxy (single-device):** share-to-chat rate; share of completions where `by_assignee=false` on shared devices (actor ≠ owner).
- **Handoff value:** % of weekly-active circles with ≥1 `handoff_added`.
- **Noise:** reminder disable rate (settings change), `notification_opened` / reminders scheduled.
- **Retention:** week-2 and week-4 return (any event on ≥2 distinct days in the week).

## Instrumentation gaps
- No install/session event (can't compute retention without opt-in telemetry or store console data).
- Share success on Android often reports `unavailable`; counted as success.
