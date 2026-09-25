# Competitor Analysis

_Source method: web search extracts (2026-09-25). Pricing and ratings change often; re-verify before external use. Nothing here is from hands-on use of the apps._

| Product | Target | Positioning | Key features | Pricing | Platform | Review themes / complaints | Privacy model | Medical features | Family collab |
|---|---|---|---|---|---|---|---|---|---|
| **CaringBridge** (nonprofit) | Patients/families in a health journey | Broadcast health updates to a wide circle | Journal/updates, guestbook, Planner (meals, errands) | Free, ad-free, donation-funded | Web, iOS, Android | Strong for storytelling, weak for day-to-day operations | Private sites; nonprofit "privacy not profit" | Health updates (narrative) | Broadcast model; helpers sign up for tasks |
| **Lotsa Helping Hands** | Large volunteer circles | Delegate tasks across a community | Calendar of needs, volunteers claim, announcements | Free | Web, iOS (2.7★/47), Android (~3.0) | Crashes at login; can't edit notes/announcements; no daily check-in | Private invite-only community | Minimal | Claim-a-task model |
| **ianacare** | Working caregivers (via employers) | Rally friends & family; employer benefit | Post needs (rides, meals), team, PLUS navigators | Free app; PLUS via employers/health plans (>400k covered lives in 2022) | iOS, Android, web | (few public reviews found) | Enterprise | Low | Team + requests |
| **Caring Village** | Family caregivers | All-in-one care coordination | To-dos, calendar, meds, journal, documents, messaging | Free ≤5 members; paid larger villages (users cite $15/$25/mo as "overpriced") | iOS, Android, web | Glitchy, double-posts, calendar off by one day, medication entries duplicate; 5-member cap resented | Standard SaaS | Medication tracking | Yes, capped |
| **CircleCare** | Adult children of aging parents | Keep family aligned on meds, appointments, tasks | Care circles, meds, appointments, tasks, docs (1GB) | $6.99/mo or $59.99/yr; only creator pays; Android free tier: 1 circle, 2 caregivers | iOS, Android | New (2026); little review history | Standard SaaS | Medications | Yes |
| **Jointly** (Carers UK) | UK carers | Designed by carers for carers; group messaging + lists | Messaging, to-dos, meds list, calendar, contacts, device integrations | **£2.99 one-off per circle**; free via many employers/local authorities | iOS, Android, web | Dated UI (INFERENCE from age; not verified) | Charity-run | Medication list | Yes, unlimited members |
| **Cozi** | Families (general) | Family organizer | Shared calendar, to-dos, shopping, meals | Free (30-day calendar window since 2024) / Gold $39/yr per group | iOS, Android, web | Free tier now crippled; ads | Ad-supported | None | Group-based sharing |
| **Caily** | Senior-living communities | HIPAA messaging between staff and families | Daily updates, secure messaging | B2B | iOS, Android | — | HIPAA | Yes (via facility) | Family ↔ staff |
| **CareZone** (defunct) | Families managing meds | Meds + family coordination | Meds, journal, calendar | Was free | — | **Shut down 2024 (Walmart Health), users lost data** | — | Heavy | Yes |
| **Wellthy / Cariloop** | Employees (via employer) | Human care-coordinator concierge | Care coordinators + platform | PMPM employer contracts; Wellthy direct ~$200–400/mo | Web/app | — | Enterprise | Navigation (non-clinical) | Some |
| **WhatsApp / SMS / iMessage** | Everyone | General messaging | Chat, voice, media | Free | All | Logistics buried; no ownership/status; notification fatigue | E2E encrypted (WhatsApp) | None | Universal |
| **Google/Apple shared calendars & notes** | Everyone | General productivity | Calendar, shared lists | Free | All | No care context; no activity log | Platform | None | Shared, but per-item |

Sources: [CaringBridge](https://www.caringbridge.org/resources/what-is-caringbridge), [CaringBridge Planner](https://admin.caringbridge.org/resources/caringbridge-planner-makes-it-easy-to-request-help/), [Lotsa on App Store](https://apps.apple.com/us/app/-/id606923858), [Lotsa sentiment report](https://marlvel.ai/intel-report/lifestyle/lotsa-helping-hands), [ianacare pricing](https://support.ianacare.com/hc/en-us/articles/35224684278541-How-much-does-ianacare-cost), [ianacare TechCrunch](https://techcrunch.com/2022/01/04/ianacare-picks-up-12-1m-to-fundamentally-change-the-family-caregiver-experience/), [Caring Village pricing](https://caringvillage.com/pricing/), [Caring Village negative reviews](https://appgrooves.com/app/caring-village-by-segue-technologies-inc/negative), [CircleCare App Store](https://apps.apple.com/us/app/circlecare-family-caregiver/id6757629684), [CircleCare FAQ](https://circlecare.app/faq/), [Jointly (Carers UK)](https://www.carersuk.org/help-and-advice/technology-and-equipment/jointly-app-for-carers/), [Jointly price via Medway Council](https://www.medway.gov.uk/directory_record/48940/jointly_mobile_and_online_care_coordination_app), [Cozi Gold](https://www.cozi.com/cozi-gold-features/), [Cozi review 2026](https://www.usecalendara.com/blog/cozi-review-2026), [Caily](https://www.caily.com/), [CareZone shutdown via Carelo](https://getcarelo.com/carezone), [Wellthy employers](https://wellthy.com/for-employers), [Wellthy vs Cariloop](https://www.myshortlister.com/compare/cariloop-vs-wellthy).

## Observations

1. **The category is crowded and mostly free.** Any "Family Care OS" that is just tasks + calendar + meds + chat is undifferentiated (Caring Village, CircleCare, Jointly all exist).
2. **Almost every competitor drifts into medication tracking.** This adds regulatory surface, privacy risk and clinical feel, and is where the reported bugs cluster (Caring Village duplicate meds, off-by-one calendar).
3. **Everyone assumes all family members will join the app.** None found position around *working with* the existing group chat.
4. **Reliability is a differentiator** in a category of 2.7–3.0★ apps.
5. **Trust/longevity** matters (CareZone). Local-first storage and plain-text export are a credible answer.
6. **Payers that actually pay today:** employers (ianacare PLUS, Wellthy, Cariloop), local authorities/employers (Jointly). Consumer subscription is thin (CircleCare's model is new and unproven).

## Positioning gap we target

> The primary coordinator's reliable, non-medical "who's doing what" list and handoff log, that works *with* the family group chat instead of demanding everyone install another app.
