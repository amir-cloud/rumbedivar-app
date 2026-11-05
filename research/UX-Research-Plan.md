# UX Research Plan — RumbDivar (روم به دیوار)
**Tagline:** هرچیزی که روتون نمیشه بخرید!
**Date:** 2026-11-05 | **Owner:** Product/UX | **Status:** Ready to run

## 1. Background
Flutter app, RTL Persian. Current build: Splash → Login → Home placeholder (welcome only).
No catalog, search, cart, checkout, delivery, notifications yet. This research decides what discreet-commerce MVP to build next.

Market confirmed: **Iran only**. Language: **Persian-only**. Offer interviewer gender choice.

## 2. Goal & Decisions to Inform
Primary: Discover needs (not usability — nothing to test yet).
Decisions:
- Which 2-3 embarrassment categories / jobs to prioritize for MVP
- Requirements for discreet checkout + delivery + app privacy
- Language/tone that feels safe in Persian
- What NOT to build

## 3. Research Questions
1. What categories trigger embarrassment buying in-person vs online, and why?
2. End-to-end JTBD: trigger → search → evaluate → pay → receive → unbox/hide?
3. Trust breakers at each step? (packaging, courier talk, payment descriptor, SMS, app icon/name, notification preview, family opening package)
4. Why choose RumbDivar over Digikala / SnappMarket / Instagram shops / pharmacy?
5. Who will never buy online regardless?
6. What Persian wording feels respectful vs shaming?
7. Payment + delivery prefs for sensitive orders? (online vs COD, home vs work vs pickup locker)
8. App privacy expectations? (biometric lock, discreet icon, no-preview notifications, guest mode)

Success = Top 5 insights + 8-12 prioritized opportunities with evidence, mapped to future flows.

## 4. Methods (1 week, ample budget)
- **A. Core: 8-10 moderated remote discovery interviews, 45 min, camera-off, alias.** Best for shame/anxiety probing. Wed-Thu.
- **B. Parallel: unmoderated async survey + 3-day diary (n=25-40).** Quantifies frequency, categories, WTP for discretion. Runs Mon-Thu via paid panel.
- **C. Light fake-door:** 1 Figma concept of discreet checkout (neutral box, no-logo courier, pickup option) shown in last 10 min of interview for reaction. No build.

Why not: no usability test (nothing built), no focus groups (no candor on embarrassment in groups), no long ethnography (too slow).

Budget use: panel recruiting speed, high incentives for sensitive topic (interview 40-60 USD equiv, async 10-15), professional Persian transcription, Meet/Zoom + Miro/Dovetail/Notion.

## 5. Schedule
- **Mon AM:** Lock screener, launch panel + async, prep guide, consent forms
- **Mon PM-Tue:** Recruiting sprint (12 booked for 8-10 shows), async inflow
- **Wed-Thu:** 4-5 interviews/day, 15-min debrief between
- **Fri AM (3h):** Affinity + JTBD + Frequency x Embarrassment matrix + RICE-lite
- **Fri PM (1h):** Readout + 1-pager + backlog

## 6. Recruitment (see screener-persian.md)
Iranian adults 18-45, smartphone, bought online last 3 months, delayed/avoided a purchase due to embarrassment (must-have).
Quotas: 50/50 women/men, Tehran/big-city vs small city, lives alone vs with family/parents/dorm, Digikala power users vs Instagram-shop buyers.
Exclude: <18, never bought online, competitor employees, researched in last 3 months.
Ethics: alias, can skip any Q, female/male interviewer choice, anonymized transcripts, delete raw video 90 days, separate consent for clips.

## 7. Data Collection
E-consent (Persian) + verbal re-confirm. Record Meet/Zoom, Persian auto-transcript + human clean.
Standard notes in Notion/Dovetail: facts / quotes / pains / workarounds / trust-needs / implications, tagged by journey stage.
Storage: `research/raw-restricted/` (no PII in synthesis), `research/transcripts-anonymized/`.

## 8. Analysis
1. Independent coding of 2-3 transcripts → align codebook (trigger/barrier/workaround/trust-need/language)
2. Affinity by journey stage
3. JTBD: Job / workaround / pain / design implication
4. Prioritize: Reach (async n) x Confidence (interview evidence) / Effort
Rule: insight needs ≥3 participants + 1 verbatim. Keep disconfirming cases.

## 9. Sharing
- 60-min readout: 20m insights + 20m highlight reel (5x30s, voice-altered) + 20m MVP prioritization (recorded)
- 1-pager (FA+EN): decision, top 5, what we won't build — pinned in team channel + repo wiki
- Backlog stories with evidence links + metrics (e.g. discreet-delivery selection rate, zero privacy tickets)
- Raw pack: anonymized transcripts, board link, survey charts

## 10. Risks
Low candor → alias + skip rule + no real product names required. No-shows → over-recruit 12. Transcription errors → human clean. Small-city under-rep → quota enforcement.
