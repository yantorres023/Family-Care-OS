# UX Spec — Baton MVP

## Principles
1. **Three questions on one screen:** What needs to happen today? Who is doing it? What changed?
2. **Domestic, not clinical.** Warm terracotta palette, no crosses/hearts-with-pulses, no medical vocabulary ("Needs someone", not "Unassigned care task").
3. **Works alone.** Every screen is useful to a coordinator with zero other installs.
4. **Quiet by default.** Reminders only for my own items; private lock-screen text.
5. **Never colour alone.** Every status = icon + words.

## Navigation
Bottom bar: **Today · Tasks · Timeline · Family** (Settings via gear on Family). FAB "Add" on Today/Tasks when the acting person can create. App-bar avatar = who is using the app (tap to switch) when >1 person.

## Screens
| Screen | Purpose | Key elements |
|---|---|---|
| Onboarding (4 steps) | Set up in <2 min | Welcome + boundary note → names → helpers (optional, "they don't need the app") → starter-task chips + custom |
| Today | Daily answer | Handoff card / prompt · needs-someone banner · Overdue · Today · Coming up · Done today · "Send update to family chat" |
| Tasks | Everything open | Filters: All open / Mine / Needs someone / Done (30 days) |
| Item detail | One thing | When, repeats, where, who, notes, added-by; Mark done · I'll do it · I can't do this · Ask the family chat; history |
| Item editor | Create/edit | Task/Appointment segmented; title; Today/Tomorrow/No date/Pick; optional time; repeats; who; place (appt); notes (with medical-details warning); important |
| Handoff editor | Note for next person | Prompt + example, "Start from today's list" draft, 2000-char field |
| Timeline | What changed | Everything / Notes only; day headers; avatar + icon + sentence; note bodies inline |
| Family | Who helps | Care recipient card (rename), people with role + open count, Add helper, how-it-works card, switch-user |
| Member | One person | Their open items; rename; role; make owner; remove (states tasks that will be released) |
| Settings | Control | Reminders (on/off, lead time, all-day time, morning summary, private lock screen, OS-permission warning), sharing footer + preview, export, delete all, boundary text, on-device usage counts, about |

## Copy rules
- Say "Needs someone", "I'll do it", "I can't do this", "Note for the next person".
- Never say "patient", "care plan", "compliance", "adherence", "vitals".
- Errors say what happened and that nothing was changed.

## Interaction details
- Checkbox completes instantly; SnackBar: "Done. Next one: Tuesday." + Undo.
- Deleting asks for confirmation; recurring deletion explains future repeats stop.
- Removing a member states "N open tasks will be marked Needs someone".
- Delete-all requires typing DELETE.

## Accessibility checklist (tested items marked ✓)
- ✓ 200% text scale on Today/Tasks/Timeline/Family: no overflow.
- ✓ Android tap-target (48dp) and labelled-tap-target guidelines on Today.
- ✓ Checkbox semantics "Mark {title} done".
- Avatars expose member name to screen readers; decorative icons have semantic labels where meaningful ("Important", "Appointment").
- Headers marked as semantic headers.
- Dark theme supported via system setting.

## Notification behaviour
| Trigger | Who | Default text (private mode) |
|---|---|---|
| Item assigned to me with a time | me | "Care reminder — You have something due: Today, 3:00 PM. Open Baton for details." (1h before) |
| Item assigned to me, all-day | me | same, at 9:00 on the day |
| Morning summary (opt-in) | me | "Today — 3 things planned today." |

Not implemented in MVP (require multi-device sync): "task assigned to you by someone else", "task completed", "handoff added", "schedule changed" notifications. The Timeline and shared updates cover these for now.

## Screenshots
Rendered from the real widget tree with fictional sample data: `release/screenshots/` (regenerate with `cd app && flutter test tool/screenshots_test.dart`).
