# Survey Import Guide — Porsline / Typeform / Google Form
Source of truth: `survey-import-ready.md` + `survey-questions.csv`.
Results template: `async-results-template.csv`.

## Porsline (recommended for Iran)
1. New survey → language fa, RTL, font Vazirmatn.
2. Create 19 questions manually from `survey-questions.csv` (Porsline has no question-CSV import — use CSV as checklist).
   - Q1-Q3, Q16: mandatory. Rest optional with «رد می‌کنم» option.
   - Q2/Q6/Q7: multi-select. Q12: ranking (or 7x Likert 1-7 if ranking unavailable).
   - Q19 validation: regex `^09\d{9}$` OR starts with `@`.
3. Logic: Q2 if only «خرید نکردم» → end screen A (disqualify). Q3 if ≠ «بله» → end screen A. Q16 if «خیر» → end screen B (keep survey, no scheduling).
4. End screens:
   - A: «ممنون از وقتت! این موج فقط برای کسانی است که تجربه عقب انداختن خرید داشته‌اند.»
   - B qualify: «عالی! برای مصاحبه واجد شرایطی. [scheduling link]»
5. Footer every page: «ناشناس، حذف داده با درخواست در ۷۲ ساعت: [contact]».
6. Export daily: Results → Export CSV → save as `research/async-results-YYYY-MM-DD.csv` (keep header from `async-results-template.csv`).

## Typeform
1. Create → import via copy-paste per question (Typeform has no bulk CSV either).
2. Use Welcome Screen = Q0 text from `survey-import-ready.md`.
3. Logic Maps mirror Porsline rules above. Notifications: Slack/email on Q16=بله.
4. Export CSV → rename columns to match `async-results-template.csv` headers.

## Google Form (fallback, free)
1. New Form → settings: collect email OFF, confirmation message = end screen B.
2. Sections: S1 screener (Q1-Q3) → Go to section based on answer for disqualify.
3. S2 main (Q4-Q15), S3 scheduling (Q16-Q19).
4. Responses → Sheets → File → Download CSV → conform to template headers.

## QA before launch (15 min)
- [ ] Test disqualify path (Q2=never, Q3=خیر)
- [ ] Test qualify path (Q3=بله, Q16=بله → alias+contact required)
- [ ] Mobile check: Persian renders RTL, ranking usable on 360px
- [ ] One pilot response end-to-end → exports to template CSV cleanly
