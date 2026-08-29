# Founder Readiness → GoHighLevel data map

**For:** Marcus Jones, wiring the GoHighLevel side
**From:** the ATM Founder Platform build
**Status:** live on the site; parameter names await your confirmation

When a founder finishes an assessment and clicks through to book, the booking
link now carries their result with them, so GHL can record where they came
from, which assessment they took and which band they landed in. This note sets
out exactly what arrives.

---

## 1. Band names

### Readiness Diagnostic (RD) — your action 3

Confirmed and wired. The four `RD` band values are exactly as you specified:

| Score | Band name |
|---|---|
| 85+ | Transaction-Ready |
| 70–84 | Readiness Project Candidate |
| 50–69 | Roadmap Tier |
| below 50 | Foundation Tier |

**One correction to the filename, so your notes match the repo.** You wrote
that RD is `diagnostic.html`. It is not — it is **`transaction-readiness.html`**.
Everything else in your description was right, and identified that file
precisely: it is the 24-metric instrument (`t("24 metrics defined",
METRICS.length === 24)`), titled "Transaction Readiness Assessment", and it
already carried those four band names at exactly those four thresholds. We
have tagged that page `RD`.

`diagnostic.html` is a genuinely separate, live assessment — the
**Multiplier Diagnostic**: 20 questions, six themes, instrument id
`multiplier_diagnostic`, with its own four bands at its own thresholds:

| Score | Band name |
|---|---|
| 91+ | Highly Ready |
| 71–90 | Strong Potential |
| 41–70 | Emerging |
| below 41 | At Risk |

The two pages cross-link each other: the Multiplier Diagnostic offers "go a
level deeper with the Transaction Readiness Assessment", and the Transaction
Readiness Assessment calls itself "the deal-grade instrument behind our
Multiplier Diagnostic".

We renamed nothing. Because its band vocabulary is not RD's, `diagnostic.html`
currently sends **`fr_source` only** — no assessment, no score, no band — so
it cannot contaminate your RD band picklist. **If you want its results in GHL
too, give us a fourth assessment code** (`MD` would be the obvious one) and
the four band values above, and we will wire it in one edit. Until then those
bookings arrive attributed but untagged.

### Investor Ready — now implemented

Three bands, on `investor-ready.html`. Thresholds are unchanged from the
existing scoring; only the names are new:

| Score | Band name |
|---|---|
| 80+ | Raise Ready |
| 60–79 | Almost Ready |
| below 60 | Getting Ready |

Per your instruction, the Funded Female Founders module has **no** band model
and creates no band tags.

---

## 2. What the booking link carries

Base URL is unchanged:

```
https://api.leadconnectorhq.com/widget/booking/Av6i7gL0YzbszYFfnKqQ
```

Parameters are appended to it, all values URL-encoded:

| Parameter | Value | Sent from |
|---|---|---|
| `fr_assessment` | `RD`, `IR` or `FFF` | the assessment pages |
| `fr_score` | integer percentage, `0`–`100` | scored assessments only |
| `fr_band` | the exact band name string | scored assessments only |
| `fr_source` | one controlled source value (below) | every booking link |

Which page sends what:

| Page | `fr_assessment` | Score | Band |
|---|---|---|---|
| `transaction-readiness.html` | `RD` | yes | the four RD bands |
| `investor-ready.html` | `IR` | yes | the three IR bands |
| `funding.html` | `FFF` | no | no |
| `diagnostic.html` | *(none — pending a code)* | no | no |
| all other pages with a booking CTA | *(none)* | no | no |

`fr_source` is always present. `fr_assessment` appears only on the three
assessment modules. `fr_score` and `fr_band` are **omitted entirely** where
there is no score — they are never sent empty.

Worked examples:

```
…/Av6i7gL0YzbszYFfnKqQ?fr_assessment=RD&fr_score=76&fr_band=Readiness%20Project%20Candidate&fr_source=Investor%20Network
…/Av6i7gL0YzbszYFfnKqQ?fr_assessment=IR&fr_score=72&fr_band=Almost%20Ready&fr_source=LinkedIn%20Paid
…/Av6i7gL0YzbszYFfnKqQ?fr_assessment=FFF&fr_source=Referral
…/Av6i7gL0YzbszYFfnKqQ?fr_source=Founder%20Readiness%20Direct
```

### Controlled `fr_source` values

Investor Network · LinkedIn Organic · LinkedIn Paid · Website Organic ·
Referral · Partner · Event · Outbound · Existing Client ·
Founder Readiness Direct · Direct · Other

We read `utm_source`, `src` or `source` from the URL the founder arrived on,
in that order, and match it to the list above. Matching ignores case,
punctuation and separators, so `linkedin_paid`, `LinkedIn-Paid` and
`linkedin paid` all resolve to `LinkedIn Paid`. Anything we do not recognise
becomes `Other`. Nothing in the URL at all becomes `Founder Readiness Direct`.

---

## 3. Two things to confirm, and one limitation

**The parameter names are our proposal, not a decision.** `fr_assessment`,
`fr_score`, `fr_band` and `fr_source` are placeholders we chose so the work
could ship. Tell us the field names GHL actually expects for your custom
fields and we will change them — it is a small edit and we will turn it round
on request. The same goes for the controlled values if your picklists differ.

**We collect no identity in the link.** The booking link carries no name,
email, company or phone number, and no identifier that could be joined back to
a person. The founder's identity and their marketing consent for the booking
are collected by the GHL booking form, at the point of booking — never in the
link.

One qualification, so this is not overstated. `diagnostic.html` (the
Multiplier Diagnostic) has a pre-existing lead-capture step of its own: after
scoring, it offers a form — first name, work email, company, role, revenue
band — behind an explicit consent tick, and on submit writes those answers to
ATM's own Supabase `leads` table. It is skippable (a "Skip — just show my
score" link shows results with nothing entered and nothing stored), it stores
nothing in cookies or browser storage, and it is entirely separate from this
GHL hand-off. It predates this work and we have not touched it. Full detail
has gone to Madeleine and David separately, as you asked.

**Campaign source survives one journey only.** The free pages carry no
cookies, no localStorage and no analytics — that is a deliberate design rule,
not an oversight. So the source is read from the URL the founder is on at that
moment and passed straight to GHL. In practice:

- a founder who lands on a campaign link and books in the same visit will
  carry the right source; but
- a founder who lands on a campaign link, navigates to a page whose link
  does not carry the parameter, and books from there will arrive as
  `Founder Readiness Direct`.

There is no way to close that gap without adding tracking to the free pages,
which we will not do. If reliable multi-page attribution matters more than the
no-tracking rule, that is a decision for David, not something we can engineer
around.

Finally, the link degrades safely: if anything in the parameter-building code
fails, the founder is sent to the plain booking URL. Booking never breaks
because attribution broke.
