# Fake-Door Checkout Card — Figma Copy (Persian, RTL)
Purpose: Show in last 10 min of interview to elicit disbelief / trust needs. NOT a final design. One card + 2 variants.
Figma setup: Frame 360x640, font Vazirmatn, RTL, colors neutral (no pink branding to test discretion).

## Card A — Discreet Checkout (main stimulus, show first)
Title: `تسویه حساب محرمانه`
Subtitle: `بدون نام فروشگاه در هیچ مرحله‌ای`

[Section 1 — بسته‌بندی]
- icon: 📦 + headline: `بسته خنثی بدون لوگو`
- body: `جعبه کرافت ساده، بدون نام «روم به دیوار». فاکتور داخل بسته، بدون اسم محصول روی لیبل.`
- chip: `+ ۱۵ هزار تومان`

[Section 2 — تحویل]
- radio 1 (selected): `تحویل در لاکر نزدیک شما — بدون دیدار با پیک (پارک ملت، کد ۴ رقمی)`
- radio 2: `ارسال با پیک بدون لوگو — تماس با عنوان «بسته پستی»`
- note small: `پیک از محتوای بسته اطلاع ندارد.`

[Section 3 — پرداخت و پیامک]
- `نام در صورتحساب بانکی: «RDV*Services»`
- `پیامک: «بسته شما رسید» — بدون نام محصول`
- pay button: `پرداخت ۲۴۸٬۰۰۰ تومان`

Footer microcopy: `آیکون اپ در گوشی: «یادداشت‌ها». اعلان بدون پیش‌نمایش.`

## Card B — Variant to A/B probe (show only if time)
Same as A but:
- `بسته خنثی رایگان برای سفارش بالای ۳۰۰ هزار تومان`
- Delivery option 3: `تحویل در محل کار / آدرس آشنا`
Use to ask: «کدوم رو باور می‌کنی؟ برای کدوم پول می‌دی؟»

## Moderator prompts (say while showing)
1. «اولین حست چیه؟ چی باورت نمی‌شه؟»
2. «کدوم جمله حس امنیت می‌ده، کدوم شک‌برانگیزه؟»
3. «اسم RDV*Services در بانک کافیه؟ چی پیشنهاد می‌دی؟»
4. «لاکر رو واقعا استفاده می‌کنی؟ چرا/چرا نه؟»
5. «برای بسته خنثی چقدر بیشتر می‌دی؟ صفر؟ ۵-۱۰٪؟»

## Designer notes (Figma)
- Build as component `FakeDoor/Checkout-FA` with props: `packaging={paid|free}`, `delivery={locker|courier|work}`.
- Keep branding OFF intentionally — test if neutral beats branded.
- Accessibility: min touch 44px, contrast AA, full RTL mirroring.
- Prototype: static image screen-share is enough; no interaction needed for interviews.
- Do NOT build backend — this is stimulus only. Log disbelief quotes in synthesis-template.md.

## What to capture
- Believability (1-5 quick rating after showing)
- Top fear remaining even with this design
- WTP answer
