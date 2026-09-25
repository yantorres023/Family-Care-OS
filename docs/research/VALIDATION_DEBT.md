# Validation Debt & Beta Gates

_Nothing below has been tested with real users. Thresholds are experimental starting points, not proven benchmarks._

## Validation debt
| # | Hypothesis | Metric | Pass | Fail | Cheapest test |
|---|---|---|---|---|---|
| V1 | Coordinators will set up a circle and add real tasks | % installs reaching care profile + ≥3 items in 24h | ≥50% | <25% | TestFlight/Play internal beta, 30 coordinators |
| V2 | Coordinators add other people (family invite acceptance proxy) | % activated circles with ≥1 helper | ≥60% | <30% | Same beta |
| V3 | (Sync phase) Invited family actually join | invite acceptance within 7 days | ≥50% | <20% | Fake invite link that opens a waitlist page, before building sync |
| V4 | Tasks get completed through the app | weekly `task_completed` per active circle | ≥5 | <2 | Beta |
| V5 | Weekly reuse | week-2 retention (active on ≥2 days in week 2) | ≥35% | <15% | Beta |
| V6 | More than one person contributes | circles with ≥2 distinct actors completing/creating in a week (shared device) OR ≥1 share/week | ≥40% | <15% | Beta + in-app one-question survey |
| V7 | Notifications help, not annoy | reminder disable rate by day 30 | ≤15% | ≥35% | Beta settings counts |
| V8 | Users prefer this to WhatsApp alone | "Would you be disappointed if Baton went away?" very disappointed | ≥40% (Sean Ellis) | <20% | Survey at day 14 |
| V9 | Share-to-chat is the right bridge | % activated coordinators sharing ≥1/week | ≥30% | <10% | Beta |
| V10 | Handoff notes create value | % weekly-active circles with ≥1 note | ≥30% | <10% | Beta |
| V11 | Willingness to pay | fake-door tap rate at $19/$29/$39 per year | ≥5% | <2% | Fake door in beta build |
| V12 | Medical features are not a precondition | % of feedback requesting meds/health tracking as blocker | ≤20% | ≥50% | Beta feedback tagging |
| V13 | Privacy stance matters | % citing "no account / on device" as reason to try | ≥20% | – | Onboarding exit survey |

## Beta gates (after 4 weeks, n ≥ 30 activated coordinators)
| Gate | Continue | Iterate | Kill / pivot |
|---|---|---|---|
| Activation (V1+V2) | ≥40% | 20–40% | <20% |
| Week-2 retention (V5) | ≥35% | 15–35% | <15% |
| Weekly completed owned tasks (V4) | ≥5 | 2–5 | <2 |
| Multi-member signal (V6) | ≥40% | 15–40% | <15% |
| Notification disable (V7) | ≤15% | 15–35% | ≥35% |
| Sean Ellis (V8) | ≥40% | 20–40% | <20% |

**Kill/pivot rules**
- Activation <20% **and** retention <15% → the problem isn't painful enough in this form: stop or pivot to templates/content only.
- Retention OK but multi-member signal <15% and share <10% → it's a personal to-do list; either reposition as "caregiver's personal organiser" or stop (crowded).
- Multi-member signal ≥40% and ≥30% ask for other phones → build sync (TECHNICAL_PLAN §Sync) as the paid tier.
- ≥50% of feedback demands medication tracking → do **not** add it without regulatory/privacy review; consider partnering instead.

## Next 3 experiments
1. **Template test (no app, 1 week):** publish the "weekly family update" and "handoff note" templates on a landing page; measure downloads/email signups from caregiver communities (per DISTRIBUTION.md rules). Tests demand for the job.
2. **Closed beta (4 weeks):** 30–50 coordinators via TestFlight + Play internal testing; weekly 1-question in-app pulse; evaluate against beta gates.
3. **Sync fake door (in beta):** "Let Luis update from his phone" → price cells → waitlist. Tests the collaboration + WTP hypotheses before building a backend.
