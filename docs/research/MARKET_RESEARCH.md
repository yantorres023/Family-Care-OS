# Market Research & Wedge Comparison

_Run date: 2026-09-25. Method: public-evidence triangulation via web search. **No human interviews were conducted.** Direct page fetches were blocked by the sandbox egress policy (aarp.org, pubmed, reddit, substack all returned 403), so numbers below come from search-engine extracts of the cited pages. Every figure should be re-verified against the primary source before external use._

Labels used: **FACT** (reported by a cited source), **INFERENCE** (reasoned from facts), **HYPOTHESIS** (to be tested), **UNVALIDATED_WITH_REAL_USERS** (nothing we have touches real users).

---

## 1. Market size (FACT)

| Market | Figure | Source |
|---|---|---|
| US | 63M family caregivers in 2025 (+45% / ~20M vs. 2015); ~1 in 4 adults. 51M care for someone 50+. | AARP/NAC *Caregiving in the US 2025* — [AARP](https://www.aarp.org/caregiving/basics/caregiving-in-us-survey-2025/), [AARP PRI](https://www.aarp.org/pri/topics/ltss/family-caregiving/caregiving-in-the-us-2025/) |
| US | ~11% of caregivers live >1 hour away; long-distance caregivers report more emotional distress (47%). | Search extract of CGUS 2025 coverage ([retirementlivingsourcebook](https://www.retirementlivingsourcebook.com/proagingnews/caregiving-in-the-us-2025-a-comprehensive-overview)) |
| UK | 5.8M unpaid carers; care valued at £184B/yr. | [Carers UK State of Caring 2025](https://www.carersuk.org/reports/state-of-caring-2025-the-cost-of-caring-the-impact-of-caring-across-carers-lives/) |
| Canada | 13.4M (42%) provide unpaid care to children or adults; among carers of care-dependent adults, 53% care for a parent. Most often aged 45–64. | [Statistics Canada, 2022 data](https://www150.statcan.gc.ca/n1/daily-quotidien/221108/dq221108b-eng.htm), [StatCan sandwiched study](https://www150.statcan.gc.ca/n1/daily-quotidien/240402/dq240402d-eng.htm) |
| Older adults & phones | ~76–78% of US 65+ own a smartphone (Pew 2024, via secondary sources). | [retirementliving.com](https://www.retirementliving.com/cell-phones-for-seniors/how-many-seniors-have-smartphones) |

INFERENCE: The population is large and growing in all target markets. Market size is not the constraint; **adoption and retention** are.

## 2. Who installs and manages the product? (FACT → INFERENCE)

- FACT: Caregiving systems are typically *primary caregiver*, *partnership* or *team*; one sibling (often a daughter, often the one living closest) usually becomes primary. 62% agree daughters are the unspoken default; 36% say the closest sibling takes it on. ([ResearchGate: Collaboration among siblings](https://www.researchgate.net/publication/233164904_Collaboration_Among_Siblings_Providing_Care_for_Older_Parents), [Burd Home Health survey](https://www.burdhomehealth.com/post/who-cares-for-mom-and-dad-study))
- FACT: Unequal division of care is the most common source of sibling discord; unequal allocation → distress and anger; shared responsibility → less stress. ([Tensions among siblings in parent care, Eur J Ageing](https://link.springer.com/article/10.1007/s10433-009-0109-9), [Division of Parent Care Among Adult Children, PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC7751154/))
- FACT (consumer survey, lower quality): 69% have fought with a sibling over a parent's care; 47% felt resentment over an unfair load; money is #1 conflict source (36%), time/effort imbalance #2 (26%). ([Bay Alarm Medical "Sibling Scorecard"](https://www.bayalarmmedical.com/caregiver-support/the-sibling-scorecard/))
- FACT: Reddit caregiving posts: 37.9% disclose *caregiving relationship strain*; 67.8% disclose care-recipient functional problems. ([JMIR Aging 2025, Reddit content analysis](https://aging.jmir.org/2025/1/e71452))
- FACT: Younger and male caregivers rate technology as more useful for caregiving. ([Frontiers Public Health 2025, n=483](https://pmc.ncbi.nlm.nih.gov/articles/PMC12116359/))

**INFERENCE — the installer is the primary coordinator** (most often an adult daughter aged ~40–64, working, sometimes "sandwiched"). The care recipient is rarely the primary user. Other siblings are *secondary, reluctant* users. **This is the single most important design constraint**: the product must deliver value to the coordinator even if nobody else installs it.

## 3. Current workarounds (FACT)

- Families use group texts, shared calendars, and shared notes; group texts "become a mess of logistics"; threads "get way too long". ([AgingCare forum thread on apps for 4 siblings](https://www.agingcare.com/questions/any-suggestions-on-a-caregiver-app-would-like-one-that-we-4-one-far-away-could-use-to-share-the-resp-486616.htm), [The Caregiver Space](https://thecaregiverspace.org/sibling-caregiving-not-helping-eldercare/))
- Families run parallel WhatsApp groups (one with parents, one without) to divide caring responsibilities. (search extract of [substack essay on family WhatsApp groups](https://whatdidshesay.substack.com/p/family-whatsapp-groups))
- Paper caregiver log books and printable shift-handoff templates are sold on Amazon and offered free by startups — evidence that **handoff logs are a real, recurring practice**. ([Amazon log book](https://www.amazon.com/Caregiver-Daily-Log-Book-Caregiving/dp/B0GYT1W4Y2), [Sagebeam shift report template](https://www.mysagebeam.com/resources/home-caregiver-shift-report-template))

## 4. Adoption barriers (FACT)

- Most caregiver apps do 1–2 things; caregivers cite time cost of learning technology. ([Park et al. 2022 scoping review, n=175 apps](https://pmc.ncbi.nlm.nih.gov/articles/PMC8829719/))
- Median 70% of users abandon lifestyle/mental-health apps within 100 days; reasons include technical issues, privacy, poor UX, time/financial cost, changing needs. ([JMIR scoping review of app abandonment](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11694054/))
- "Easy to install", "easy to learn" and "cost" are the top purchase criteria; "reliability" top in use. ([Gerontologist, WTP for caregiving tech](https://academic.oup.com/gerontologist/article/56/5/817/2605281))
- InfoSAGE (AHRQ-funded family care coordination platform): 257 registered users over the study — feasible, but small organic uptake even with institutional backing. ([AHRQ final report](https://digital.ahrq.gov/sites/default/files/docs/citation/r01hs021495-safran-final-report-2019.pdf))
- Platform risk / trust: CareZone (acquired by Walmart) was shut down with Walmart Health in 2024; families lost their data. ([Carelo](https://getcarelo.com/carezone), [TendTo](https://tendto.ai/compare/carezone))

## 5. Willingness to pay (FACT → skeptical INFERENCE)

- Caregivers report willingness to pay up to ~$70/month for caregiving *technologies* (mostly devices/services, older study). ([Gerontologist](https://academic.oup.com/gerontologist/article/56/5/817/2605281))
- Market prices for coordination apps are **low or free**: CaringBridge free (nonprofit), Lotsa free, ianacare free (employer-paid PLUS), Jointly £2.99 one-off per circle, CircleCare $6.99/mo or $59.99/yr (only creator pays), Caring Village free ≤5 members with paid tiers users call "overpriced". See COMPETITORS.md.
- INFERENCE: Stated WTP for coordination software is weak; free alternatives + WhatsApp anchor price near zero. Consumer subscription is **unproven**; B2B2C (employers, carers' organisations, councils — the Jointly model) is the most evidenced payer.

## 6. Wedge comparison

Scores 1–5 (5 best). Evidence strength = how directly public evidence supports the pain.

| Wedge | Pain evidence | Frequency | Single-player value (works if siblings don't install) | Differentiation vs. WhatsApp | Medical/privacy risk (5 = low) | Build feasibility w/o backend | Total |
|---|---|---|---|---|---|---|---|
| **A. Task coordination — "who is doing what"** | 4 (sibling-inequity literature) | 4 | 4 (coordinator's own list) | 4 (ownership + due + status is structurally absent in chat) | 5 | 5 | **26** |
| **B. Appointments/logistics** | 3 | 2–3 (irregular) | 3 | 3 (calendars already do this) | 3 (drifts to medical notes) | 4 | 18–19 |
| **C. Handoff / "what happened"** | 3 (log books exist, handoff templates) | 4 | 3 | 5 (chat buries history; a structured note is findable) | 4 | 5 | **24** |
| **D. Documents/admin** | 3 | 1 (rare, bursty) | 4 | 3 | 1 (IDs, insurance, POA) | 2 (needs secure storage) | 14 |
| **E. Shared expenses** | 4 (money #1 conflict source) | 2 | 2 (only valuable when others participate) | 4 | 3 (financial data) | 3 | 18 |

**Decision:** combine **A + C** as the wedge (with B folded into A as a dated "appointment" task type), defer D and E. A answers *"who is doing what, when"*; C answers *"what already happened and what should the next person know"*. They share one data model (items + activity log) so the combined build cost is small.

E (expenses) has strong conflict evidence but only works once multiple members participate; it is the **best second wedge** once collaboration is proven.

## 7. Why people still use WhatsApp despite dedicated apps (INFERENCE from the above)

1. It is already installed by everyone, including the parent (zero adoption cost).
2. Message = notification = done; no data model to learn.
3. Coordination is irregular; a dedicated app is forgotten between crises (70%/100-day abandonment).
4. Dedicated apps ask *every* member to install and sign up — the least-engaged sibling becomes the bottleneck.
5. Many dedicated apps lead with medication/health tracking, which feels clinical and raises privacy worry.
6. Dedicated apps have had reliability problems (Lotsa 2.7★ iOS, crash complaints; Caring Village "buggy") and shutdown risk (CareZone).

**Design implication:** do not try to *replace* the group chat. Make the coordinator's structured list the source of truth, and make it trivial to **push a clean plain-text summary into the existing chat**. Helpers can stay in WhatsApp.
