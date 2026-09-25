# Monetization (hypotheses — nothing validated)

## Evidence recap
- Category anchors near **free**: CaringBridge (nonprofit), Lotsa, ianacare (free app) are free; Jointly is a **£2.99 one-off** per circle; CircleCare $6.99/mo or $59.99/yr (creator pays, helpers free); Caring Village charges for >5 members and users call $15–25/mo "overpriced". (COMPETITORS.md)
- Caregivers express willingness to pay for caregiving *technology* (Gerontologist study), but coordination software is perceived as low value vs. devices/services.
- Payers that demonstrably pay today: **employers** (ianacare PLUS, Wellthy, Cariloop PMPM), **local authorities/employers** (Jointly), **health plans** (ianacare via Anthem).
- WhatsApp is free and "good enough" for many (RED_TEAM #1).

## Options assessed
| Model | Fit | Risk | Verdict |
|---|---|---|---|
| Free forever (donations) | High adoption | No business | Use during validation |
| Consumer subscription (~$4–7/mo) | Matches CircleCare | Low WTP; 70% abandon in 100 days; subscription for an irregular need | **Test, don't assume** |
| Annual family plan (~$29–39/yr, one payer) | Aligns with coordinator-pays reality; Cozi Gold precedent ($39/yr) | Needs sync to justify | Best consumer candidate, tied to cloud sync |
| One-time unlock (~$4.99–9.99) | Jointly precedent; no subscription fatigue | Low LTV; server costs once sync exists | Viable for local-only version |
| B2B2C: employers' caregiver benefit | Strongest payer evidence | Long sales cycles; buyers want navigation services too | Pursue after retention evidence |
| B2B2C: carers' organisations / councils (UK) | Jointly proves model | Procurement; charity competitor | Partnership track |
| Senior living / home-care agencies | Adjacent (Caily) | Different product (staff↔family) | Out of scope |
| Ads / data sale | — | Destroys trust; health-adjacent | **Rejected** |

## Recommendation
1. **v0.1–beta: free**, no paywall, no ads. The only question is behaviour (activation, weekly reuse).
2. **Fake-door test** at the moment sync is requested: "Sync with your family's phones — $X/year for the whole family (coming soon) → notify me". Measure click-through by price cell ($19 / $29 / $39).
3. If ≥5% of activated coordinators tap the priced door and ≥30% of those leave an email, build sync as the paid tier ("Family plan": one payer, unlimited helpers).
4. In parallel, 10 conversations with HR/benefits leads and UK carers' centres to test B2B2C appetite (no outreach performed in this run).

## Kill conditions
- <2% fake-door engagement at any price AND no B2B pilot interest after 10 conversations → treat Baton as a free/open-source tool or stop.

## Unit economics sketch (hypothetical)
Supabase Pro ≈ $25/mo base covers thousands of small circles; at $29/yr, ~11 paying families cover base infra. The constraint is conversion, not cost.
