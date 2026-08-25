# ATM Founder Platform — Product Blueprint
**Two data-product assets on GitHub + Supabase, built from the ATM book IP and advisory processes, with an explicit AI/Human operating model.**
30 July 2026 · UK English

---

## 1. What we are building

One platform, two assets, mirroring ATM's two service lines:

| Asset | Service line it productises | Driving IP |
|---|---|---|
| **Asset 1 — Exit Ready** | ATM Exit Advisory (4 phases: Founder Clarity → Gap Analysis → Business Readiness → Transaction Execution) | *Add Then Multiply* (Ch. 8 "E is for Exit", Ch. 1–2 readiness, Appendix 3 Valuation) + *Funded Female Founders* (founder-clarity ethos, fundraising-asset discipline) |
| **Asset 2 — Deal Ready** | ATM M&A Advisory (7 phases: Strategic Logic → Target ID → Human Approach → Founder-to-Founder → HoT & DD → SPA & Completion → Integration) | *Add Then Multiply* (FACE: Fund, Acquire, Consolidate; Ch. 5–7; Appendices 1–4) + *FFF* Part Two (funding the acquisition: debt, equity, institutional structures) |

Each asset is a **diagnostic + engagement workspace**:

1. **Front door (free, ungated)** — a self-serve readiness diagnostic: single-file HTML, scored client-side, instant results page. Output: a readiness score across the phase dimensions plus a teaser gap summary. Lead generation for the Readiness Call.
2. **Engagement workspace (paid, authenticated)** — the productised advisory engagement: full gap analysis, phase-by-phase roadmap, document workspace/data room, AI-drafted deliverables, and human sign-off gates. This is where Supabase earns its place — multi-session persistence, advisor + founder roles, audit trail.

**Why this converts to scale:** the retainer model (Phases 1–3) is currently constrained by advisor hours. The platform moves every repeatable analytical and drafting task to AI, and reserves human time for the four things the process documents themselves say are irreducibly human: the founder-clarity conversation, judgement on readiness, relationships/chemistry, and negotiation. One advisor can then run many concurrent engagements at consistent, audit-defensible quality.

## 2. IP mapping — books → product features

**From *Add Then Multiply*:**
- FACE methodology → the platform's master taxonomy. Every engagement, score, and roadmap item is tagged F, A, C or E.
- Ch. 1 (values/culture, people, brand, systems) + Ch. 5–8 chapter content → diagnostic question banks and scoring rubrics per dimension.
- Appendix 3 (Valuation) → the Gap Analysis engine's reverse-engineering logic: target exit number → implied EBITDA/multiple → required growth trajectory → gap items.
- Ch. 6 (heads of terms, SPA, disclosure letter, walking away) → Deal Ready's transaction-stage checklists and document templates.
- Ch. 7 (Consolidate) → the Integration module: 100-day plan template, culture-change risk flags — "planned from the beginning, not bolted on".

**From *Funded Female Founders*:**
- Ch. 8's fundraising assets → the workspace's document checklist engine: 12-slide pitch deck structure (as a scored template), five-year monthly three-statement projections, 30–50 page business plan, data-room checklist.
- Investor research method (longlist → shortlist of 30–50 → warm-intro pathfinding) → the funding module's structured pipeline (also reusable for buyer/target pipelines in Asset 1 and 2).
- Part One (bias/uneven playing field) → positioning and tone: the product explicitly levels the playing field — founders arrive at the table with big-company-grade preparation.

## 3. The AI/Human operating model (the overlay)

Design rule, applied everywhere: **AI drafts, analyses, tracks and assembles; the human decides, relates, and signs off.** Every AI output is stored with its inputs (audit trail); every phase gate requires a human sign-off record. Nothing customer-facing leaves the platform without a named human approval.

### Asset 1 — Exit Ready

| Phase | AI does | Human (advisor) does |
|---|---|---|
| 1. Founder Clarity | Pre-meeting questionnaire; synthesis of answers into a clarity brief; "day after the sale" scenario prompts; meeting-note summarisation into the Founder Clarity Statement | Conducts the conversation — the two questions (financial target; life the day after) are asked and heard by a person. Approves the Clarity Statement |
| 2. Gap Analysis | Reverse-engineers the target: required valuation → multiple/EBITDA scenarios → dimension-by-dimension gap scoring (leadership, commercial capability, finance, plan credibility); drafts the engagement roadmap | Validates multiples and assumptions against market reality; edits and signs off the roadmap; sets priorities with the founder |
| 3. Business Readiness | Monthly re-scoring; drafts the buyer-credible business plan; org-design options for founder-independence; tracks actions; flags stalls; prepares board-pack updates | Leadership hiring and coaching; monthly advisory sessions; judgement call on "ready for market" |
| 4. Transaction Execution | Data-room assembly and completeness QA; buyer-research briefs; DD question log with drafted responses; timeline tracking | Runs the process with the specialist transaction partner; all buyer contact; negotiation; the decision to accept |

### Asset 2 — Deal Ready

| Phase | AI does | Human (advisor) does |
|---|---|---|
| 1. Strategic Logic | Build-vs-buy analysis from founder inputs; strategic-case memo draft | The honest verdict — including "M&A is the wrong route" (the process promises this; it must come from a person) |
| 2. Target Identification | Longlist research and enrichment (financials, ownership, signals); shortlist scoring against strategic criteria | Network activation; selecting who to approach; protecting relationships |
| 3. Human Approach | Pre-approach research brief per target | The approach itself — personal, unformalised, human by definition |
| 4. Founder-to-Founder | Meeting-prep briefs; post-meeting synthesis | Creating the conditions; chemistry assessment stays entirely human |
| 5. HoT & DD | HoT draft from term inputs; DD tracker with red-flag summarisation; legal-cost dashboard (the process explicitly manages advisor cost escalation) | Negotiating terms; the transparency conversations between parties; managing lawyers |
| 6. SPA & Completion | SPA version comparison; open-issues list; completion checklist | Negotiation and completion decisions |
| 7. Integration | 100-day plan generator (Consolidate playbook); synergy and milestone tracker; culture-risk flags from both sides' profiles | Leading the integration relationships; culture calls; retention of key people |

**Scale economics this buys:** phases 2, 3 (Exit) and 2, 5, 7 (M&A) are where advisor hours currently sink into analysis, drafting and tracking. Shifting those to AI-with-sign-off is what turns a hand-crafted retainer into a scalable service without touching the human moments the brand is built on.

## 4. Architecture

**Front end (GitHub):** self-contained single-file HTML pages, GitHub Pages hosting — a pattern proven in production on earlier builds. The free diagnostics are pure client-side (no accounts, no gates). The workspace is a single-page app in the same single-file discipline, talking to Supabase over its JS client.

**Back end (Supabase):** the new layer, and the reason this generation of assets outgrows the client-side-only pattern — engagements are multi-month, multi-party, and must be audit-defensible.
- **Auth:** email magic-link; roles `founder`, `advisor`, `admin`. Auth begins only at the paid engagement boundary — the free front door stays ungated.
- **Postgres + RLS:** every table row-level-secured by engagement membership. Founders see only their engagement; advisors see their portfolio.
- **Storage:** the data room — per-engagement buckets, RLS-scoped, completeness checked against the FFF Ch. 8 checklist.
- **Edge Functions:** all AI calls server-side (Claude API), never from the browser; each run logged to `ai_runs` with prompt, model, inputs hash and output.

**Engineering conventions (proven on earlier production builds):**
1. Strict brand isolation: this repo contains ATM-brand assets only — no content, code or links imported from any other client estate.
2. Pages deploys: if Actions-path deploys fail, use the legacy build trigger (`POST /repos/…/pages/builds`) — known-good fix.
3. Single-file HTML, UK English, no sign-up gates on free content.
4. Access-controlled paywall pattern (payment link → redirect with access code) available if a paid self-serve tier is wanted between the free diagnostic and the full engagement.
5. The Readiness Call CTA uses a single `BOOKING_URL` constant — now the live GoHighLevel scheduler link, swappable with one edit if the calendar changes.
6. Built-in test harness in the browser console (`runTests()`) for every diagnostic scoring engine.

## 5. Data model (Supabase schema, first cut)

```sql
-- Identity & engagement spine
create table profiles (id uuid primary key references auth.users, full_name text, role text check (role in ('founder','advisor','admin')));
create table engagements (id uuid primary key default gen_random_uuid(),
  asset text check (asset in ('exit_ready','deal_ready')),
  company_name text, founder_id uuid references profiles(id), advisor_id uuid references profiles(id),
  phase int not null default 1, status text default 'active', target_outcome jsonb, -- the founder's number + life-after statement
  created_at timestamptz default now());

-- Diagnostics & gap engine
create table assessments (id uuid primary key default gen_random_uuid(), engagement_id uuid references engagements(id),
  face_dimension text check (face_dimension in ('F','A','C','E')), dimension text, score numeric, evidence jsonb, taken_at timestamptz default now());
create table gap_items (id uuid primary key default gen_random_uuid(), engagement_id uuid references engagements(id),
  dimension text, description text, severity int, status text default 'open', owner text check (owner in ('ai','founder','advisor')));
create table roadmap_actions (id uuid primary key default gen_random_uuid(), gap_item_id uuid references gap_items(id),
  action text, due date, status text default 'todo');

-- M&A pipeline (Deal Ready; reusable as buyer pipeline in Exit Ready)
create table targets (id uuid primary key default gen_random_uuid(), engagement_id uuid references engagements(id),
  name text, stage text check (stage in ('longlist','shortlist','approached','meeting','hot','dd','spa','completed','integration','dropped')),
  enrichment jsonb, relationship_notes text);

-- Documents & data room
create table documents (id uuid primary key default gen_random_uuid(), engagement_id uuid references engagements(id),
  doc_type text, storage_path text, checklist_key text, status text check (status in ('missing','draft','ai_drafted','review','approved')));

-- The audit-defensibility layer
create table ai_runs (id uuid primary key default gen_random_uuid(), engagement_id uuid references engagements(id),
  task text, model text, input_hash text, output jsonb, created_at timestamptz default now());
create table human_signoffs (id uuid primary key default gen_random_uuid(), engagement_id uuid references engagements(id),
  gate text, signed_by uuid references profiles(id), decision text, note text, signed_at timestamptz default now());
```
RLS: membership predicate on `engagement_id` throughout; `human_signoffs` insert restricted to `advisor`/`admin`. Phase advancement (`engagements.phase`) only via a function that checks the corresponding sign-off exists — the AI/Human gate enforced in the database, not just the UI.

## 6. Build sequence

1. **Sprint 1 — Exit Ready front door.** Diagnostic single-file HTML (question bank from ATM Ch. 1–2 + Exit chapters), client-side scoring, `runTests()` harness, repo + Pages live. No Supabase dependency — ships value in days.
2. **Sprint 2 — Supabase spine.** Project setup (needs your Supabase account), schema above, RLS, magic-link auth, engagement creation flow.
3. **Sprint 3 — Exit Ready workspace.** Gap engine (reverse-engineering calculator), roadmap, document checklist, first two AI tasks via Edge Functions (clarity-brief synthesis; business-plan first draft) with sign-off gates.
4. **Sprint 4 — Deal Ready.** Reuses the spine: diagnostic front door + target pipeline + DD tracker + integration planner.
5. **Sprint 5 — Advisor console.** Portfolio view across engagements — the scale dashboard.

**Open items:** (1) Supabase account/org to create the project in. (The scheduler URL is resolved — `BOOKING_URL` now points at the GoHighLevel calendar.)

---

# v0.2 addendum — four-tier value stream (31 July 2026)

The front door was redesigned from two separate asset pages into one platform with a four-tier value stream, reflecting the commercial packaging agreed by the owners:

**Diagnostics (free) → Personalised Roadmap → Insource Sourcing → Readiness Project (full engagement).**

The tiers package the same underlying advisory phases (Exit Advisory Phases 1–4; M&A Advisory Phases 1–7); nothing in the AI/Human operating model changes. Key elements:

- **`diagnostic.html`** — a 24-metric weighted diagnostic across three pillars: Exit Readiness (35%), Deal Readiness (40%), Operational Readiness (25%). Each metric is a 1–5 evidence-anchored rubric (not self-assessed yes/no), producing a 0–100 Readiness Index with four classification bands: 85+ Transaction-Ready · 70–84 Readiness Project Candidate · 50–69 Roadmap Tier · <50 Foundation Tier. Scored entirely client-side; `runTests()` covers the scoring maths and band boundaries.
- **`funding.html`** — the *Funded Female Founders* module: the ten-asset fundraising checklist, the angels/VC/family-office comparison, a promotion-vs-prevention language checker (Kanze research), and a client-side grant application draft builder. AI-assisted drafting matched to specific grant programmes and investor mandates is the Supabase-era upgrade path.
- **Ecosystem pages** — `founders.html` (3,000 founder CEO network, ATM-owned) and `investors.html` (900 institutional relationships). Regulatory position by design: the platform prepares businesses and does not arrange investments or communicate financial promotions; investor introductions occur exclusively through ATM's authorised transaction partner (see the FCA guardrail in CLAUDE.md).
- **Verified claims** — $8.7tn opportunity (Rose Review gap applied to global GDP, per *FFF*), 13× warm-introduction advantage (British Business Bank research), promotion/prevention question bias (Kanze et al., AMJ/HBR). Network figures are owner-verified.
- Commercial terms between the platform's owners are documented privately, off-repo.
