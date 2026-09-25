# Manual QA checklist (on-device; cannot be automated in this environment)

Run on: 1 recent Android (13+), 1 older Android (8–10), 1 recent iPhone, 1 small iPhone (SE).

- [ ] Fresh install → onboarding → Today in <2 min.
- [ ] Assign a timed task to me for +70 min → permission prompt appears once (not at launch) → reminder arrives ~10 min later (1h lead), lock screen shows "Care reminder" without title.
- [ ] Deny permission → app fully works; Settings shows "Notifications are turned off".
- [ ] Tap reminder → opens the task.
- [ ] Reboot phone → pending reminder still fires (Android boot receiver).
- [ ] Change device time zone → task times unchanged on screen (wall-clock), reminders rescheduled on next launch.
- [ ] DST weekend: reminder at 10:00 local fires at 10:00 local.
- [ ] Share update → WhatsApp and SMS receive readable text; emoji and accents intact.
- [ ] Export → JSON file opens and contains all data.
- [ ] Delete all data → onboarding; reminders cancelled.
- [ ] Accessibility: TalkBack/VoiceOver reads "Mark {task} done"; largest system font on Today/Tasks.
- [ ] Dark mode legible.
- [ ] Kill app during save → relaunch shows consistent data.
