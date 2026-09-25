# Product Strategy

_Status: hypothesis. Built on public evidence only (see research/). Nothing here is validated with real users._

**Working name:** Baton (provisional; see BRAND.md). Internal codename: Family Care OS.

## Pivot summary
From: *"Family Care OS — a shared operating system for the whole family around an aging parent."*
To: **"The coordinator's shared to-do and handoff list for a parent's care — works with your family group chat, not instead of it."**

## ICP
The **primary family coordinator** for an aging parent (or two parents):
- adult child (most often a daughter), 40–64, working, possibly sandwiched with kids;
- 1–4 siblings/relatives or a neighbour help irregularly, some long-distance;
- family already uses a WhatsApp/SMS group for logistics and finds things get lost;
- care needs are practical/logistical (rides, groceries, bills, pickups, appointments, check-in calls), not a complex clinical regime;
- US, Canada, UK first (English).

Anti-ICP (MVP): professional home-care agencies; families needing medication administration tracking; care recipients living in facilities with their own portals (Caily-type).

## Trigger
A moment where coordination visibly fails or load spikes: a missed pickup/appointment, a hospital discharge, a parent losing the ability to drive, a sibling argument about "who does everything", the coordinator travelling and needing others to cover.

## JTBD
"When I'm the one holding everything together for Mum/Dad, help me **see what needs to happen, make it clear who's doing each thing, and tell everyone what's happened** — without chasing people in the group chat."

## Users
- **Primary:** the coordinator (installs, sets up, maintains).
- **Secondary:** helpers — siblings, partner, neighbour. In MVP they are **named people** in the circle; they are reached through shared text updates, or they can use a **shared family device** ("who's using this?" switcher).
- **Profile, not user:** the cared-for person.

## Core promise
"Know what needs doing for Mom today, who's on it, and what already happened."

## Aha moment (hypothesis)
The coordinator adds a handful of tasks, assigns a couple to siblings, taps **Share update**, and the family group chat receives a clean, readable summary — "Today: 10:30 Dr. Patel (Ana) · Prescription pickup — needs someone · Done: Groceries (Luis)" — instead of them typing it out.

## Core loop
1. Coordinator (or helper on shared device) opens **Today**.
2. Adds/assigns/completes items; writes a short **handoff note** after a visit.
3. **Shares update** to the family chat / asks for help on an unassigned item.
4. Recurring items regenerate; reminders bring the coordinator back.

## Activation (hypothesis)
Care profile created **+** ≥3 items **+** ≥1 other helper added **+** ≥1 shared update or item assigned to someone else — within 7 days.

## Retention hypothesis
Recurring chores (weekly groceries, monthly bills, fortnightly visits) create a natural weekly return; the handoff log becomes the family's memory, raising switching cost modestly.

## Monetization hypothesis
Free for families during validation. Two paths to test (see business/MONETIZATION.md): (1) optional one-time "supporter" unlock or low annual plan tied to cloud sync; (2) B2B2C via employers and carers' organisations (Jointly model). Consumer subscription is **not** assumed.

## Distribution hypothesis
Content aimed at the coordinator's search moments ("how to split caregiving with siblings", "caregiver handoff template"); caregiver communities (Reddit, Facebook groups, AgingCare) via genuinely useful free templates; the shared update itself is a viral surface ("Sent with Baton" footer, removable).

## Risks
1. Undifferentiated vs. free incumbents (Caring Village, CircleCare, Jointly).
2. Single-device MVP can't prove multi-user collaboration.
3. Share-to-chat may be ignored or feel like noise.
4. WTP near zero; B2B cycles long.
5. Local-only data loss (lost phone) until cloud backup exists.

## Explicitly out of scope
Diagnosis, symptoms, medication dosing/schedules, vitals, emergency triage, clinical records, insurance IDs, AI features, in-app chat, expenses (deferred wedge).
