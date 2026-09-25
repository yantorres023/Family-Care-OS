# Evidence Ledger

_All evidence is public/secondary, gathered 2026-09-25 by web search. No interviews, no beta users. Every assumption about actual behaviour with THIS product is UNVALIDATED_WITH_REAL_USERS. Source URLs are listed in MARKET_RESEARCH.md and COMPETITORS.md; short keys used here._

Statuses: SUPPORTED · WEAK · CONTRADICTED · UNVALIDATED_WITH_REAL_USERS

---

### A1. Many adults coordinate care for an aging parent
- **Supporting:** 63M US caregivers (AARP/NAC 2025), 51M caring for 50+; 5.8M UK (Carers UK); 13.4M Canada, 53% of adult-care caregivers care for a parent (StatCan).
- **Contrary:** none material.
- **Confidence:** High. **Status:** SUPPORTED
- **Falsify:** n/a (population fact).

### A2. Coordination is fragmented across chat, calls, calendars, paper
- **Supporting:** forum threads describe group text + shared calendar + notes (AgingCare); paper log books sold; parallel WhatsApp groups (substack essay).
- **Contrary:** no quantitative prevalence found; some families say group text "works fine".
- **Confidence:** Medium. **Status:** SUPPORTED (qualitatively)
- **Falsify:** survey showing majority of multi-helper families report no coordination problems.

### A3. The core pain is "who is doing what / what already happened", not medical
- **Supporting:** unequal division is the main sibling conflict source (Eur J Ageing; PMC division-of-care); 37.9% of Reddit caregiver posts mention relationship strain (JMIR Aging 2025); 67.8% mention functional problems (practical ADL help, not diagnosis).
- **Contrary:** perceived tech usefulness highest for "communication with health care team" (60.5%, Frontiers 2025) — a medical-adjacent need.
- **Confidence:** Medium. **Status:** WEAK→SUPPORTED (inferred from conflict literature; not measured as "coordination pain")
- **Falsify:** interviews where coordinators rank "clinical info" over "who does what" as top pain.

### A4. One primary coordinator does most of the work; others are peripheral
- **Supporting:** primary-caregiver pattern is dominant in sibling research; daughters/closest sibling default; forum posts about siblings who don't help.
- **Contrary:** "team" arrangements exist; long-distance siblings want visibility.
- **Confidence:** High. **Status:** SUPPORTED
- **Falsify:** usage data where ≥2 members create/complete items weekly in most families.

### A5. Family members won't all install another app
- **Supporting:** 70% median abandonment within 100 days (JMIR); "easy to install" top criterion; WhatsApp ubiquity; InfoSAGE low organic uptake.
- **Contrary:** paid apps (CircleCare, Jointly) exist with invite-all models; Jointly offered at scale by councils.
- **Confidence:** Medium-High. **Status:** SUPPORTED (as a risk)
- **Falsify:** invite acceptance ≥60% and week-2 activity of invitees ≥40% in beta.

### A6. A structured handoff note creates disproportionate value
- **Supporting:** existence of handoff templates and log books; sibling "what happened" confusion in forums.
- **Contrary:** handoff logs are most common where paid aides rotate — may be less relevant to single-coordinator families.
- **Confidence:** Low-Medium. **Status:** UNVALIDATED_WITH_REAL_USERS
- **Falsify:** <20% of weekly active coordinators write ≥1 handoff/week.

### A7. Sharing a text summary into the existing group chat is an acceptable collaboration bridge
- **Supporting:** WhatsApp ubiquity; people already coordinate there; zero install cost for recipients.
- **Contrary:** one-way; recipients can't mark items done; might just add noise to the chat.
- **Confidence:** Low. **Status:** UNVALIDATED_WITH_REAL_USERS
- **Falsify:** share action used by <25% of activated coordinators in week 1, or qualitative feedback that it clutters the chat.

### A8. Users will pay a consumer subscription
- **Supporting:** CircleCare charges $6.99/mo; Caring Village paid tiers exist; WTP studies show openness to paying for caregiving tech.
- **Contrary:** most competitors are free; users call $15/mo "overpriced"; Jointly £2.99 one-off; employers pay in the enterprise market.
- **Confidence:** Low. **Status:** WEAK
- **Falsify:** <2% conversion at a fake-door paywall among activated users.

### A9. Older adults (the cared-for person) won't be primary users
- **Supporting:** ~76–78% of 65+ own smartphones but the installer is the adult child; InfoSAGE dyads needed researcher support.
- **Contrary:** many 65+ are capable users; some want to see their own schedule.
- **Confidence:** Medium. **Status:** SUPPORTED (for MVP scoping) — design for readable large text anyway.
- **Falsify:** meaningful share of installs where the cared-for person is the owner.

### A10. Medical data is not needed for the core job
- **Supporting:** coordination tasks (rides, groceries, bills, pickups) are logistical; competitors' medical features are where bugs/complaints cluster.
- **Contrary:** caregivers value meds lists; a "pick up prescription" task is adjacent to medication.
- **Confidence:** Medium. **Status:** WEAK→SUPPORTED — tasks may *mention* a pickup, but we never store dosage/diagnosis.
- **Falsify:** majority of beta feedback requests medication schedules as a precondition to use.

### A11. Notifications will become noise if not controlled
- **Supporting:** family group-chat fatigue widely reported; caregiver notification fatigue (Medisafe).
- **Contrary:** reminders are a core value for coordinators.
- **Confidence:** Medium. **Status:** SUPPORTED (as a design constraint)
- **Falsify:** notification disable rate <10% at 30 days.

### A12. Privacy/trust concerns are an adoption barrier
- **Supporting:** privacy is one of six abandonment categories (JMIR); CareZone shutdown data loss; health-app store scrutiny.
- **Contrary:** people freely put this info in WhatsApp.
- **Confidence:** Medium. **Status:** SUPPORTED
- **Falsify:** no privacy objections surfaced in first 20 user conversations.

### A13. Real-time multi-user sync is required to prove the value
- **Supporting:** "shared view" is the promise.
- **Contrary:** A4 + A5 suggest the coordinator gets most value alone; share-to-chat may suffice to validate demand.
- **Confidence:** Low. **Status:** UNVALIDATED_WITH_REAL_USERS
- **Falsify:** beta coordinators rate "others can't edit" as a blocker (>40% mention it unprompted).

### A14. Employers / carer orgs are the most credible payer
- **Supporting:** ianacare PLUS (>400k lives), Wellthy/Cariloop PMPM, Jointly via councils/employers; 81% of employees say caregiving benefits improve retention (Cariloop).
- **Contrary:** long B2B sales cycles; buyers want navigation services, not just software.
- **Confidence:** Medium. **Status:** WEAK
- **Falsify:** 0 of 10 HR/benefits or carers-centre conversations express pilot interest.
