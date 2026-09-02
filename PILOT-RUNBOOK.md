# Pilot Runbook: proving the platform end to end

Three pilot founders, one advisor, ~4 weeks. Everything below is UK English and assumes the live site at `https://addthenmultiply.github.io/Project-Diamond/`.

## Part 1: One-time setup (~15 minutes, Supabase dashboard)

Do these in order. Steps 1–3 are required before any founder signs in.

1. **Run migration 002 (fixes login).** SQL Editor → paste `supabase/migrations/002_grant_rls_helpers.sql` → Run. Without this, every workspace query fails with "permission denied for function current_role_atm". (Migration 001 is already applied: verified against the live project.)
2. **Auth redirect URLs.** Authentication → URL Configuration → Site URL `https://addthenmultiply.github.io/Project-Diamond/`; add redirect URLs for `exit-ready-workspace.html`, `deal-ready-workspace.html`, `advisor-console.html` (full URLs) and `http://localhost:8107/*` for local testing.
3. **Email sending: do not skip.** Supabase's built-in email service is rate-limited to a couple of magic-link emails per hour, enough for one person testing, not for a pilot day. Authentication → Emails → set up custom SMTP (any provider; even a Gmail app password works for a pilot) before founders try to sign in.
4. **Advisor roles.** Sign in once yourself (creates your profile row), then SQL Editor:
   `update public.profiles set role='admin' where id = (select id from auth.users where email='<your email>');`
   Repeat with `role='advisor'` for the advisor account the pilots will use.
5. **Edge Functions (optional for week 1).** The two AI buttons (Clarity Brief, Business Plan draft) need: `supabase link --project-ref wfejarowrlalwgbqvloi`, `supabase secrets set ANTHROPIC_API_KEY=...`, `supabase functions deploy clarity-brief business-plan`. Until then the buttons fail gracefully and everything else works.

## Part 2: The pilot protocol (per founder)

**Session 0: front door (founder alone, ~20 min).**
Founder takes the free diagnostic (`diagnostic.html`), notes their Readiness Index and band, and books the call via the CTA. *Capture: score, band, three gaps, time-to-complete, and whether the results felt honest.*

**Session 1: Founder Clarity (advisor + founder, 60 min).**
The two questions: what do you want financially, and what does life look like the day after? Advisor creates the engagement in `exit-ready-workspace.html` (founder's email as owner), enters the target outcome. *Capture: whether the workspace's structure helped or hindered the conversation.*

**Session 2: Gap Analysis (advisor, then joint review).**
Run the reverse-engineering calculator (target → required EBITDA/multiple), score the dimensions, generate gap items, build the first roadmap actions. Advisor signs off the phase gate; verify the founder *cannot* advance the phase themselves (the Postgres gate should block them, this is a selling point, test it deliberately).

**Weeks 2–4: Business Readiness rhythm.**
Founder works the roadmap; documents checklist fills; advisor reviews weekly in `advisor-console.html`. If Edge Functions are deployed, generate one Clarity Brief and one Business Plan draft, and have the advisor edit + approve, that's the AI-drafts/human-signs-off loop demonstrated live.

**Founder mix suggestion:** run two pilots through Exit Ready and one through Deal Ready (`deal-ready-workspace.html`: target pipeline, DD tracker, 100-day plan) so both assets get proven.

## Part 3: The proof pack (what to capture for the sale)

The point of the pilot is evidence. Collect, per founder:

| Evidence | Where it lives |
|---|---|
| Readiness Index before / after 4 weeks | diagnostic + workspace re-score |
| Gap items opened vs closed | workspace / advisor console |
| Documents assembled (of the FFF checklist) | workspace checklist |
| AI drafts produced and hours of advisor time they replaced | `ai_runs` table + advisor's estimate |
| Every decision gate with a named human approval | `human_signoffs` table |
| Founder quote on the experience | ask at exit interview |

Three founders × four weeks of that table is the pitch: *"the methodology, productised, here is the audit trail."*

## Scaling auth: supporting hundreds of logins

The platform's auth already scales (Supabase handles 50,000 monthly active users on every tier); the only bottleneck is **email delivery**. Fix that once and you're done:

1. **Transactional email provider (the core fix).** Create an account with **Resend** (recommended: first-class Supabase integration, 3,000 emails/month free, then ~£16/month for 50,000) or Postmark/AWS SES. Verify your sending domain there (it gives you three DNS records (SPF, DKIM, DMARC) to add), then copy its SMTP credentials into Supabase → Authentication → Emails → **SMTP Settings**. Magic links now come from your own domain with proper deliverability instead of Supabase's shared, throttled mailer.
2. **Raise the rate limits.** Supabase → Authentication → Rate Limits → increase "emails per hour" from the default (only applies once custom SMTP is on) to e.g. 300/hour. This is the setting that turns "2 logins an hour" into "hundreds".
3. **Sending domain: one decision needed.** Best deliverability and brand: `auth.addthenmultiply.com` (needs David to add the three DNS records, a 10-minute favour that doesn't expose anything). If you want zero dependency on David pre-sale, buy a neutral domain you own (e.g. a product-named .com) and switch to his domain after the sale, the swap is just re-verifying in Resend and editing the SMTP "from" address.
4. **Sessions do the heavy lifting.** A magic-link email is needed only for *sign-in*, not every visit, Supabase keeps founders logged in with refresh tokens for weeks. Hundreds of users does not mean hundreds of emails a day; expect roughly one email per founder per device per month.
5. **Optional, for zero-email logins at scale:** enable Google and/or LinkedIn OAuth (Authentication → Providers), one-click sign-in for founders, no email round-trip at all. Worth adding before opening the platform to the 3,000-CEO network.
6. **Supabase Pro plan (£20/month) before real founders depend on it.** Free-tier projects **pause after a week of inactivity** and have daily backup limits, fine for building, not for a live pilot holding client engagement data. Upgrade the `wfejarowrlalwgbqvloi` project before founder one signs in.

Order of operations for the pilot: Resend account → domain decision + DNS → SMTP into Supabase → raise rate limit → Pro plan → test with your own email → invite founders.

## Known limits during pilot

- Booking CTA is the live GoHighLevel scheduler (`BOOKING_URL`), opens the booking calendar in a new tab.
- Diagnostic results do not auto-flow into the workspace yet (founder's scores are re-entered at engagement creation), candidate for the next build once pilot feedback is in.
- Advisor console shows portfolio state, not revenue, by design at this stage.
