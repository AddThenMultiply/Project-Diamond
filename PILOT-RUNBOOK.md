# Pilot Runbook — proving the platform end to end

Three pilot founders, one advisor, ~4 weeks. Everything below is UK English and assumes the live site at `https://madeleinejoubert-ui.github.io/addthenmultiply/`.

## Part 1 — One-time setup (~15 minutes, Supabase dashboard)

Do these in order. Steps 1–3 are required before any founder signs in.

1. **Run migration 002 (fixes login).** SQL Editor → paste `supabase/migrations/002_grant_rls_helpers.sql` → Run. Without this, every workspace query fails with "permission denied for function current_role_atm". (Migration 001 is already applied — verified against the live project.)
2. **Auth redirect URLs.** Authentication → URL Configuration → Site URL `https://madeleinejoubert-ui.github.io/addthenmultiply/`; add redirect URLs for `exit-ready-workspace.html`, `deal-ready-workspace.html`, `advisor-console.html` (full URLs) and `http://localhost:8107/*` for local testing.
3. **Email sending — do not skip.** Supabase's built-in email service is rate-limited to a couple of magic-link emails per hour — enough for one person testing, not for a pilot day. Authentication → Emails → set up custom SMTP (any provider; even a Gmail app password works for a pilot) before founders try to sign in.
4. **Advisor roles.** Sign in once yourself (creates your profile row), then SQL Editor:
   `update public.profiles set role='admin' where id = (select id from auth.users where email='<your email>');`
   Repeat with `role='advisor'` for the advisor account the pilots will use.
5. **Edge Functions (optional for week 1).** The two AI buttons (Clarity Brief, Business Plan draft) need: `supabase link --project-ref wfejarowrlalwgbqvloi`, `supabase secrets set ANTHROPIC_API_KEY=...`, `supabase functions deploy clarity-brief business-plan`. Until then the buttons fail gracefully and everything else works.

## Part 2 — The pilot protocol (per founder)

**Session 0 — front door (founder alone, ~20 min).**
Founder takes the free diagnostic (`diagnostic.html`), notes their Readiness Index and band, and books the call via the CTA. *Capture: score, band, three gaps, time-to-complete, and whether the results felt honest.*

**Session 1 — Founder Clarity (advisor + founder, 60 min).**
The two questions: what do you want financially, and what does life look like the day after? Advisor creates the engagement in `exit-ready-workspace.html` (founder's email as owner), enters the target outcome. *Capture: whether the workspace's structure helped or hindered the conversation.*

**Session 2 — Gap Analysis (advisor, then joint review).**
Run the reverse-engineering calculator (target → required EBITDA/multiple), score the dimensions, generate gap items, build the first roadmap actions. Advisor signs off the phase gate; verify the founder *cannot* advance the phase themselves (the Postgres gate should block them — this is a selling point, test it deliberately).

**Weeks 2–4 — Business Readiness rhythm.**
Founder works the roadmap; documents checklist fills; advisor reviews weekly in `advisor-console.html`. If Edge Functions are deployed, generate one Clarity Brief and one Business Plan draft, and have the advisor edit + approve — that's the AI-drafts/human-signs-off loop demonstrated live.

**Founder mix suggestion:** run two pilots through Exit Ready and one through Deal Ready (`deal-ready-workspace.html` — target pipeline, DD tracker, 100-day plan) so both assets get proven.

## Part 3 — The proof pack (what to capture for the sale)

The point of the pilot is evidence. Collect, per founder:

| Evidence | Where it lives |
|---|---|
| Readiness Index before / after 4 weeks | diagnostic + workspace re-score |
| Gap items opened vs closed | workspace / advisor console |
| Documents assembled (of the FFF checklist) | workspace checklist |
| AI drafts produced and hours of advisor time they replaced | `ai_runs` table + advisor's estimate |
| Every decision gate with a named human approval | `human_signoffs` table |
| Founder quote on the experience | ask at exit interview |

Three founders × four weeks of that table is the pitch: *"the methodology, productised — here is the audit trail."*

## Known limits during pilot

- Booking CTA is a mailto placeholder (`BOOKING_URL`) — swap when the scheduler exists.
- Diagnostic results do not auto-flow into the workspace yet (founder's scores are re-entered at engagement creation) — candidate for the next build once pilot feedback is in.
- Advisor console shows portfolio state, not revenue — by design at this stage.
