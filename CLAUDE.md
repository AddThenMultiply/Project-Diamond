# ATM Founder Platform — repo instructions

This repo is the **ATM Founder Platform** for addthenmultiply.com — David B Horne's advisory practice (author of *Add Then Multiply* and *Funded Female Founders*). Built by Madeleine Joubert for David. It productises ATM's two advisory service lines so one advisor runs many concurrent founder engagements.

**Core rule of the product:** AI drafts, analyses, tracks and assembles; the human advisor (David) decides, relates and signs off. Nothing customer-facing ships without a named human approval. Encode this in the UX and the database.

## The platform (four-tier value stream)

Public site pages (all single-file HTML): `index.html` (overview + value stream + ecosystem) · `diagnostic.html` (the free front-door **Multiplier Diagnostic**: 20 questions across six themes, 1–5 scale, finance/funding/exit weighted ×1.5, bands Highly Ready 91+ / Strong Potential 71 / Emerging 41 / At Risk) · `transaction-readiness.html` (the deal-grade **Transaction Readiness Assessment**: 24 weighted metrics, Exit 35% / Deal 40% / Operational 25%, 1–5 rubric per metric, bands Transaction-Ready 85+ / Readiness Project Candidate 70 / Roadmap Tier 50 / Foundation Tier) · `investor-ready.html` (14-question Investor Ready diagnostic, bands Raise Ready 80+ / Almost Ready 60 / Getting Ready) · `ethical-acquisitions.html` (Ethical Acquisitions Scorecard) · `roadmap.html` · `sourcing.html` · `readiness-project.html` (the three engagement tiers) · `funding.html` (FFF module: assets checklist, capital-routes table, promotion-language checker, grant application builder) · `investors.html` (900 institutional relationships) · `founders.html` (3,000 founder CEO network). `exit-ready.html` is a legacy redirect to the diagnostic — keep it. `deal-ready.html` is now the "Grow by Acquiring" landing page (the acquisition fork from the homepage hero).

**The two scored front doors are different instruments and must not be conflated:** `diagnostic.html` is the 20-question Multiplier Diagnostic; `transaction-readiness.html` is the 24-metric Transaction Readiness Assessment. They have different band vocabularies. Booking hand-offs tag the latter as `RD` — see `GHL-DATA-MAP.md`.

Authenticated pages (behind the paid workspace boundary): `intake.html` · `exit-ready-workspace.html` · `deal-ready-workspace.html` · `investor-mandates.html` (advisor-only register) · `advisor-console.html`.

Value stream: **Diagnostics (free) → Personalised Roadmap → Insource Sourcing → Readiness Project (full engagement)**, which maps onto the ATM Exit Advisory phases (Founder Clarity → Gap Analysis → Business Readiness → Transaction Execution) and the 7-phase M&A Advisory Process. Content taxonomy is the **FACE methodology** (Fund, Acquire, Consolidate, Exit). Full design: `BLUEPRINT.md`.

Voice: ATM founder-first — warm, direct, UK English ("an exit is a life event"). Rigour in substance, warmth in tone — never institutional jargon.

**Visual system (the live palette — every page declares it in one `:root` block):** ink `#111827` · slate `#475569` · off-white background `#F8FAFC` · borders `#E2E8F0` · charcoal `#2B2A29` (`--navy`: header bars, headings, booking-CTA anchors) · amber accent `#B45309` (`--accent`: form/submit buttons, links) with hover `#8A3E06` · brand-mark orange `#F38E00` (the "MULTIPLY" wordmark only) · Georgia serif headings, system sans body. Status tokens: good `#15803D`, warn `#B45309`, bad `#B91C1C`.

CTA rule: **booking/navigation anchors (`a.cta`, `a.book-cta`) are charcoal `--navy`; form and submit buttons (`button.cta`, `.btn`, `button.gold`) are amber `--accent`.** No other primary-action colours — there is no accent blue on the site, and `#0A192F`/`#D4AF37` (a former gold-on-dark identity) must never reappear.

## Hard rules

- Self-contained single-file HTML pages: inline CSS/JS, no build step, no frameworks, avoid external CDNs. Mobile-responsive. **UK English everywhere.**
- Free pages have no sign-up, no gate, no tracking. Auth (Supabase magic-link) begins only at the paid workspace boundary.
- All AI calls go through Supabase Edge Functions (Claude API, server-side). Never call AI from the browser; never commit the service-role key or any API secret. Supabase URL + anon key live in one config constant.
- Phase advancement requires a `human_signoffs` row (advisor/admin only) — enforce the gate in Postgres, not just the UI. Log every AI call to `ai_runs` (task, model, input hash, output, timestamp).
- Every diagnostic scoring engine ships with a browser-console `runTests()` harness; run it after any scoring change.
- The Readiness Call CTA uses a single `BOOKING_URL` constant (the GoHighLevel scheduler link — swap in one place if the calendar changes).
- Deploys: GitHub Pages. If Actions-path deploys fail repeatedly, use the legacy build trigger: `POST /repos/{owner}/{repo}/pages/builds`.
- **Brand isolation:** ATM assets only. Never copy content, code or links from any other client's repositories or websites.
- **Regulatory guardrail (FCA):** the platform must never arrange investments, match founders to investors, or publish financial promotions. Investor introductions happen only through ATM's authorised transaction partner, offline. Keep the wording on `investors.html` ("does not arrange investments…") intact in spirit whenever editing.
- **Verified numbers only:** the 3,000 founder CEO network and 900 investor relationships are real, owner-verified figures. Do not invent statistics; book-sourced claims ($8.7tn opportunity, 13× warm introductions, Kanze research) must keep their citations.
- **Commercial terms are private:** the Story-C Ltd / ATM revenue-share agreement is documented in a private annex outside this repo. Never publish fee splits, settlement terms or the ownership structure on the public site.

## Build sequence

Sprint 1: diagnostic front doors (no Supabase) · Sprint 2: Supabase spine (schema in `BLUEPRINT.md` §5) · Sprint 3: Exit Ready workspace · Sprint 4: Deal Ready pipeline · Sprint 5: advisor console.

Ask Madeleine for: Supabase credentials (Sprint 2), the scheduler URL, and sign-off on asset names before public launch.
