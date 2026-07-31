# ATM Founder Platform — repo instructions

This repo is the **ATM Founder Platform** for addthenmultiply.com — David B Horne's advisory practice (author of *Add Then Multiply* and *Funded Female Founders*). Built by Madeleine Joubert for David. It productises ATM's two advisory service lines so one advisor runs many concurrent founder engagements.

**Core rule of the product:** AI drafts, analyses, tracks and assembles; the human advisor (David) decides, relates and signs off. Nothing customer-facing ships without a named human approval. Encode this in the UX and the database.

## The two assets

1. **Exit Ready** (`exit-ready.html`) — productises the ATM Exit Advisory Process: Founder Clarity → Gap Analysis → Business Readiness → Transaction Execution. Audience: founder-led businesses, £1m+ revenue, first external sale.
2. **Deal Ready** (`deal-ready.html`) — productises the ATM M&A Advisory Process: Strategic Logic → Target ID → Human Approach → Founder-to-Founder → HoT & DD → SPA & Completion → Integration.

Each asset = free ungated diagnostic front door + paid Supabase-backed engagement workspace. Full design: `BLUEPRINT.md`.

Content taxonomy is the **FACE methodology** (Fund, Acquire, Consolidate, Exit) — tag scores, gap items and roadmap actions F/A/C/E.

## Hard rules

- Self-contained single-file HTML pages: inline CSS/JS, no build step, no frameworks, avoid external CDNs. Mobile-responsive. **UK English everywhere.**
- Free pages have no sign-up, no gate, no tracking. Auth (Supabase magic-link) begins only at the paid workspace boundary.
- All AI calls go through Supabase Edge Functions (Claude API, server-side). Never call AI from the browser; never commit the service-role key or any API secret. Supabase URL + anon key live in one config constant.
- Phase advancement requires a `human_signoffs` row (advisor/admin only) — enforce the gate in Postgres, not just the UI. Log every AI call to `ai_runs` (task, model, input hash, output, timestamp).
- Every diagnostic scoring engine ships with a browser-console `runTests()` harness; run it after any scoring change.
- The Readiness Call CTA uses a single `BOOKING_URL` constant (mailto placeholder until the scheduler link exists).
- Deploys: GitHub Pages. If Actions-path deploys fail repeatedly, use the legacy build trigger: `POST /repos/{owner}/{repo}/pages/builds`.
- **Brand isolation:** ATM assets only. Never copy content, code or links from any other client's repositories or websites.

## Build sequence

Sprint 1: diagnostic front doors (no Supabase) · Sprint 2: Supabase spine (schema in `BLUEPRINT.md` §5) · Sprint 3: Exit Ready workspace · Sprint 4: Deal Ready pipeline · Sprint 5: advisor console.

Ask Madeleine for: Supabase credentials (Sprint 2), the scheduler URL, and sign-off on asset names before public launch.
