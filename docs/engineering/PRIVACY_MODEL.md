# Privacy Model

_Draft for review. Not legal advice._

## Principles
1. **Coordination, not health.** The product stores who-does-what, not medical information.
2. **Minimise.** Collect only what the coordination job needs.
3. **Local by default.** v0.1 has no account, no server, no telemetry.
4. **The user sees everything that leaves the device.** The only outbound path is the OS share sheet, initiated by the user, with visible text.

## Data inventory (v0.1)
| Data | Why | Where | Leaves device? |
|---|---|---|---|
| Care recipient name/nickname | Label the circle | SQLite on device | Only inside text the user shares |
| Member names + roles | Assign and attribute | Device | Names appear in shared updates |
| Tasks/appointments: title, date/time, repeat, owner, place, notes, important | The core job | Device | Titles/times/places/owners in shared text; **notes never** |
| Handoff notes | "What should the next person know?" | Device | Latest note (<48h) in shared update |
| Activity log | Timeline | Device | No (only in user-initiated JSON export) |
| Settings | Preferences | Device | No |
| Usage events (names + non-PII properties) | Product learning | Device, capped 1,000 | No |

**Not collected by design:** diagnoses, symptoms, medications/dosages, vitals, insurance or medical record numbers, government IDs, addresses of the cared-for person (beyond optional appointment place text), contacts, location, photos, device identifiers, advertising IDs.

**Free-text risk:** users may type health details into titles/notes/handoffs. Mitigations: inline warnings ("Avoid medical details"), notes excluded from shared text, private lock-screen reminders by default, no transmission.

## Device & OS
- Stored in the app's private SQLite database (OS sandbox; encrypted at rest when the device is locked on modern iOS/Android with a passcode).
- OS backups (Android Auto Backup to the user's Google account; iOS device backup) are left enabled so a lost phone does not lose the family's history (D-012). Decision to revisit if users object.
- Notifications: Android channel visibility `private`; our text hides titles/names by default.

## Roles (least privilege)
| Role | Can |
|---|---|
| Viewer | read only |
| Helper | add items (self/unassigned), claim/release, complete own or unassigned, edit own-created or held items, write notes |
| Coordinator | all item actions; add/remove helpers and viewers; export |
| Owner | everything, incl. roles, ownership transfer, settings, delete all data |

The owner cannot be removed (transfer first). Removed members keep history attribution but lose all abilities; their open items are released.

**Important limitation:** in the single-device MVP, roles guard against mistakes on a shared device; they are **not** a security boundary (anyone holding the unlocked phone can switch the acting person). Real enforcement arrives with server-side RLS in the sync phase.

## User rights
- Export: full JSON of all stored data (owner/coordinator).
- Delete: "Delete all data" wipes every table and cancels reminders (owner).
- Uninstalling removes app data (OS backups may retain a copy per the user's OS settings).

## Store disclosures (v0.1)
- Apple privacy label: **Data Not Collected** (nothing is transmitted to the developer).
- Google Play Data safety: **No data collected, no data shared**; data is not encrypted in transit because it is never transmitted.
- Google Play Health apps declaration: app does **not** provide health features (coordination/organisation only).

## Future (sync phase) requirements before launch
- DPIA/PIA; decide processor (Supabase/Firebase region: US + EU options; UK/EU users → UK GDPR/GDPR lawful basis = contract).
- TLS everywhere, RLS mirroring roles, invite codes hashed + expiring + revocable, audit log.
- Opt-in telemetry only, no free text, documented retention (e.g., 13 months).
- Consider HIPAA: not a covered entity/business associate when sold direct-to-consumer, but B2B2C via health plans/providers may change that — legal review required.
- FTC Health Breach Notification Rule may apply to consumer apps holding health info — another reason to keep health data out.
- AI features (future): no family data sent to a model provider without explicit opt-in, a DPA with zero retention, and on-screen disclosure.
