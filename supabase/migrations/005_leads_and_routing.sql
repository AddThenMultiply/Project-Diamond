-- 005: Lead capture + routing-as-data
-- Leads: every diagnostic completion, versioned and instrument-tagged, so scores
-- from different instruments are never mixed (md: / eas: / ird: / tra: tags).
-- Routing: band -> service mapping lives in data, with partner_only enforcing the
-- FCA guardrail structurally: any investor-facing pathway must route via ATM's
-- authorised transaction partner, and no copy edit can create a direct one.

create table public.leads (
  id                 uuid primary key default gen_random_uuid(),
  created_at         timestamptz not null default now(),
  instrument         text not null check (instrument in
                       ('multiplier_diagnostic','ethical_acquisitions','investor_ready','transaction_readiness')),
  instrument_version text not null default '1.0',
  score_pct          integer not null check (score_pct between 0 and 100),
  band               text not null,
  band_tag           text not null,           -- e.g. 'md:strong-potential', 'eas:emerging'
  theme_scores       jsonb not null default '{}'::jsonb,
  answers            jsonb,
  audience_role      text check (audience_role in ('seller','buyer','advisor') or audience_role is null),
  first_name         text,
  email              text,
  company            text,
  role_title         text,
  revenue_band       text,
  consent            boolean not null default false,
  source_page        text
);

create index leads_instrument_band_idx on public.leads (instrument, band_tag);
create index leads_created_idx on public.leads (created_at);

alter table public.leads enable row level security;

-- Anyone may submit a completion (that is the point of a front door)...
create policy leads_insert_public on public.leads for insert
  to anon, authenticated
  with check (true);

-- ...but only advisors/admins ever read them back. No anon select, no update/delete.
create policy leads_select_staff on public.leads for select
  to authenticated
  using (public.current_role_atm() in ('advisor','admin'));

-- Routing configuration: the single source of truth for band -> service.
create table public.routing_config (
  id           uuid primary key default gen_random_uuid(),
  instrument   text not null,
  band_slug    text not null,                 -- matches the slug in band_tag after the prefix
  band_label   text not null,
  service      text not null,                 -- human-readable routed service
  cta          text not null,
  partner_only boolean not null default false, -- FCA: investor-facing path, partner-mediated only
  sort_order   integer not null default 0,
  unique (instrument, band_slug)
);

alter table public.routing_config enable row level security;

-- Routing is public-readable (front-end fetches it); only admins write it.
create policy routing_select_all on public.routing_config for select
  to anon, authenticated
  using (true);
create policy routing_write_admin on public.routing_config for all
  to authenticated
  using (public.current_role_atm() = 'admin')
  with check (public.current_role_atm() = 'admin');

-- Seed: Multiplier Diagnostic (canonical front door)
insert into public.routing_config (instrument, band_slug, band_label, service, cta, partner_only, sort_order) values
 ('multiplier_diagnostic','at-risk','At Risk',
  'Financial Deep Dive, then Insourced Finance Function',
  'Let''s build your foundation. Book a call to take control of your finances and prepare for growth.', false, 1),
 ('multiplier_diagnostic','emerging','Emerging',
  'Financial Modelling with Insourced CFO support and a Funding Fitness Index review',
  'You''re growth-ready. Let''s sharpen your financials and strategy to unlock the next level.', false, 2),
 ('multiplier_diagnostic','strong-potential','Strong Potential',
  'Commercial Velocity day and a Fundable Growth Sprint',
  'You''re close to scaling. We can help you fund, acquire and prepare for exit. Let''s talk.', false, 3),
 ('multiplier_diagnostic','highly-ready','Highly Ready',
  'Full FACE Pathway — Fund, Acquire, Consolidate, Exit',
  'You''re ATM Ready. With funding, acquisitions and exit in view, let''s accelerate together.', true, 4);

-- Seed: Ethical Acquisitions Scorecard (two-sided)
insert into public.routing_config (instrument, band_slug, band_label, service, cta, partner_only, sort_order) values
 ('ethical_acquisitions','at-risk','At Risk',
  'Financial Deep Dive diagnostic and risk review',
  'You are exposed to structural and ethical risks that could undermine value. Book a Deep Dive and risk review.', false, 1),
 ('ethical_acquisitions','emerging','Emerging',
  'Ethical Deal Readiness session and Funding Fitness Index',
  'Good intent with gaps in ethics governance, finance readiness or deal structuring. Let''s close them.', false, 2),
 ('ethical_acquisitions','strong-potential','Strong Potential',
  'Commercial Velocity day or Insourced CFO scoping call',
  'A solid foundation. Targeted improvements will de-risk the deal and optimise value.', false, 3),
 ('ethical_acquisitions','highly-ready','Highly Ready',
  'FACE pathway discovery — Fund, Acquire, Consolidate, Exit',
  'You are well placed for a fair, sustainable transaction and long-term value creation.', true, 4);

-- Seed: Investor Ready Diagnostic (named bands per convergence plan S3)
insert into public.routing_config (instrument, band_slug, band_label, service, cta, partner_only, sort_order) values
 ('investor_ready','not-yet','Not Yet',
  'Fundable Growth Sprint — story, model, use of funds, data room',
  'Approaching investors now risks burning your best prospects. Close the priority gaps first.', false, 1),
 ('investor_ready','nearly-ready','Nearly Ready',
  'Funding Fitness Index review and financial model hardening',
  'Foundations are in place, but the gaps will cost you meetings or valuation. Let''s close them before launch.', false, 2),
 ('investor_ready','raise-ready','Raise-Ready',
  'Raise execution support via ATM''s authorised transaction partner',
  'Strong position. Run your raise as a professional process, with introductions made through our authorised partner.', true, 3);

-- Seed: Transaction Readiness Assessment (deep module)
insert into public.routing_config (instrument, band_slug, band_label, service, cta, partner_only, sort_order) values
 ('transaction_readiness','foundation','Foundation Tier',
  'Foundational strengthening — Deep Dive and finance rhythm first',
  'Fundamental strengthening comes first. Every gap identified is fixable, and fixing it adds value.', false, 1),
 ('transaction_readiness','roadmap','Roadmap Tier',
  'Structured roadmap with targeted remediation',
  'Real value, real gaps. A structured roadmap is the right next step before any market conversation.', false, 2),
 ('transaction_readiness','readiness-project','Readiness Project Candidate',
  '30–90 day value sprint to close remaining gaps',
  'The fundamentals are strong. A focused sprint would materially improve your position at the table.', false, 3),
 ('transaction_readiness','transaction-ready','Transaction-Ready',
  'Timing, valuation and buyer conversation via the authorised transaction partner',
  'Top tier. The conversation now is timing, valuation and the right buyer — through our transaction partner.', true, 4);
