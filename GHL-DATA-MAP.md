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

### Readiness Diagnostic — your action 3

The four band names you asked for are live, on **`transaction-readiness.html`**
(the 24-metric Transaction Readiness Assessment):

| Score | Band name |
|---|---|
| 85+ | Transaction-Ready |
| 70–84 | Readiness Project Candidate |
| 50–69 | Roadmap Tier |
| below 50 | Foundation Tier |

**One thing to flag.** Your note attached these four names to
`diagnostic.html`. That is a different instrument — the 20-question Multiplier
Diagnostic — and it has its own four bands at its own thresholds:

| Score | Band name |
|---|---|
| 91+ | Highly Ready |
| 71–90 | Strong Potential |
| 41–70 | Emerging |
| below 41 | At Risk |

We have not renamed either set. We have tagged `diagnostic.html` as `RD`, as
specified, so `fr_band` from that page sends *Highly Ready / Strong Potential /
Emerging / At Risk*. `transaction-readiness.html` currently sends no assessment
tag at all, because your spec listed only three assessment codes.

**Please tell us which you meant.** Either is a small change:

- if `RD` means the Multiplier Diagnostic, you need the four names in the
  second table above as your band values, and nothing changes on our side; or
- if `RD` means the Transaction Readiness Assessment, we will move the `RD`
  tag onto that page and you need the first table; or
- if you want both, give us a fourth assessment code and we will wire it.

Right now the two instruments have different band vocabularies, so please do
not create a single band field expecting only the first table's four values.

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

`fr_source` is always present. `fr_assessment` appears only on the three
assessment modules. `fr_score` and `fr_band` are **omitted entirely** where
there is no score — they are never sent empty.

Worked examples:

```
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

**We collect no identity.** The booking link carries no name, email, company
or phone number, and no identifier that could be joined back to a person. The
founder's identity and their marketing consent are collected by the GHL
booking form, at the point of booking — never by the platform, and never in
the link. (Separately, the Multiplier Diagnostic offers a founder the option
to enter their details to receive a follow-up, behind an explicit consent
tick; that is stored in ATM's own database and forms no part of this
hand-off.)

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
