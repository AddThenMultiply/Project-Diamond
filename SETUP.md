# Sprints 2–5: Setup guide

What was built, and the exact steps to make it live. UK English. ~15 minutes of dashboard work.

## What's in this drop

| File | Sprint | What it is |
|---|---|---|
| `supabase/migrations/001_initial_schema.sql` | 2 | Full schema, RLS, phase-gate trigger, storage bucket + policies |
| `assets/supabase.js` | 2 | Vendored supabase-js v2.111.0 UMD build (no external CDN, per repo rules) |
| `exit-ready-workspace.html` | 2 + 3 | Magic-link auth, engagement creation, gap engine (reverse-engineering calculator with `runTests()`), dimension scoring → gap items, roadmap, FFF Ch. 8 document checklist, buyer pipeline, AI task buttons, audit trail, phase gates |
| `deal-ready-workspace.html` | 4 | Target pipeline board (longlist → integration), DD tracker with red flags, 100-day integration planner (seedable standard plan), phase gates, audit trail |
| `advisor-console.html` | 5 | Portfolio dashboard: KPIs, per-engagement phase/gaps/red-flags/docs/sign-off state, attention list. Advisor/admin role required |
| `supabase/functions/clarity-brief/index.ts` | 3 | Edge Function: questionnaire → draft Founder Clarity Brief, logged to `ai_runs` |
| `supabase/functions/business-plan/index.ts` | 3 | Edge Function: gap analysis + roadmap → draft business plan, logged to `ai_runs`, document marked `ai_drafted` |

Config already in place in all three HTML files (single constant block at the top of the script):
`SUPABASE_URL = https://wfejarowrlalwgbqvloi.supabase.co` and the publishable key you provided.

## Step 1: Run the schema (5 min)

Supabase dashboard → **SQL Editor** → paste the whole of
`supabase/migrations/001_initial_schema.sql` → **Run**.

Idempotent: safe to run twice. Creates: `profiles`, `engagements`, `assessments`,
`gap_items`, `roadmap_actions`, `targets`, `dd_items`, `integration_actions`,
`documents`, `ai_runs`, `human_signoffs`, all RLS policies, the phase-gate trigger,
the auto-profile trigger, and the private `dataroom` storage bucket.

**The phase gate lives in Postgres:** `engagements.phase` cannot advance without an
approved `human_signoffs` row for `advance_to_<n>`, written by an advisor/admin.
The UI respects it; the database enforces it.

## Step 2: Auth settings (3 min)

Dashboard → **Authentication → URL Configuration**:

- **Site URL:** `https://addthenmultiply.github.io/Project-Diamond/`
- **Redirect URLs:** add
  - `https://addthenmultiply.github.io/Project-Diamond/exit-ready-workspace.html`
  - `https://addthenmultiply.github.io/Project-Diamond/deal-ready-workspace.html`
  - `https://addthenmultiply.github.io/Project-Diamond/advisor-console.html`
  - `http://localhost:8000/*` (local testing)

**Authentication → Providers → Email:** magic link is on by default; you can disable
"Confirm email" friction if you want first-click sign-in.

## Step 3: Make David and you advisors (1 min)

Sign in once via any workspace page (this creates your `profiles` row), then in SQL Editor:

```sql
update public.profiles set role = 'advisor'
where id = (select id from auth.users where email = 'david@addthenmultiply.com');
update public.profiles set role = 'admin'
where id = (select id from auth.users where email = 'madeleine.joubert@gmail.com');
```

## Step 4: Edge Functions (optional now; needed for the two AI buttons)

Requires the Supabase CLI and the Claude API key:

```bash
supabase link --project-ref wfejarowrlalwgbqvloi
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...        # never commit this
supabase functions deploy clarity-brief
supabase functions deploy business-plan
```

Until deployed, the AI buttons in the workspace show a graceful "not deployed yet"
message: everything else works without them. Every run is logged to `ai_runs`
(task, model, input hash, output) and nothing customer-facing ships without a
`human_signoffs` record: the AI/Human operating model, encoded.

## Step 5: Commit and deploy

```bash
git add assets/ supabase/ exit-ready-workspace.html deal-ready-workspace.html advisor-console.html SETUP.md
git commit -m "Sprints 2-5: Supabase spine, Exit Ready workspace, Deal Ready pipeline, advisor console"
git push
```

GitHub Pages serves the new pages automatically. If the Pages deploy misbehaves,
use the legacy build trigger (repo convention): `POST /repos/{owner}/{repo}/pages/builds`.

## Testing

- Each page has a browser-console test harness: open DevTools → type `runTests()`.
  - `exit-ready-workspace.html`: 9 tests on the gap engine + severity mapping
  - `deal-ready-workspace.html`: 7 tests on phases, pipeline stages, 100-day plan
  - `advisor-console.html`: 7 tests on the portfolio aggregation
- End-to-end smoke test: sign in by magic link → create an engagement → run the gap
  calculator → generate gap items → add a roadmap action → try to advance the phase
  as a founder (blocked) → sign in as advisor → approve the gate → phase advances.

## Decisions taken (flag if you want them changed)

1. **Workspace = new files**, not a locked section, auth starts at the paid boundary,
   free diagnostics stay ungated (repo hard rule), and the diagnostic pages can simply
   link to the workspace.
2. **`supabase/` folder lives in the repo** as the source of truth for schema and
   functions; you run the SQL via the dashboard until you adopt the CLI.
3. **`BOOKING_URL`** is the live GoHighLevel scheduler link, one-line swap if the calendar changes.
4. **Asset names** remain the working titles pending David's sign-off.
5. Two schema additions beyond BLUEPRINT §5, needed by Sprints 3–4: `dd_items`,
   `integration_actions`; plus `engagement_id` denormalised onto `roadmap_actions` for
   single-hop RLS, and a unique index on `documents (engagement_id, checklist_key)`.
