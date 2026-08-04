-- 004: Research-driven intake and mandate fields (persona research, Aug 2026).
-- Evidence: ~47% of dead deals die on diligence surprises (Axial Dead Deal
-- Report); PE screens hard at ~15% single-customer concentration; sell-side
-- QoE ≈ +0.4x EBITDA; emotional readiness is the strongest predictor of
-- exit-process abandonment; first-time acquirers succeed 23% vs 54% for
-- serial acquirers. These fields capture the "uncomfortable" data early so
-- the platform converts diligence surprises into pre-disclosed structure.
-- Idempotent — safe to run twice.

-- ---------- Founder intake: deal-reality fields ----------
alter table public.founder_intake
  add column if not exists adjusted_ebitda numeric,
  add column if not exists ebitda_adjustments text,
  add column if not exists top5_customer_pct int check (top5_customer_pct between 0 and 100),
  add column if not exists top1_customer_pct int check (top1_customer_pct between 0 and 100),
  add column if not exists growth_rate_pct numeric,
  add column if not exists financials_hygiene text check (financials_hygiene in
    ('audited','externally_reviewed','management_monthly','annual_only')),
  add column if not exists valuation_expectation numeric,
  add column if not exists valuation_basis text,
  add column if not exists skeletons text,
  -- exit persona
  add column if not exists exit_intent text check (exit_intent in
    ('full_sale','majority_with_rollover','minority','stay_on')),
  add column if not exists emotional_readiness int check (emotional_readiness between 1 and 5),
  add column if not exists structure_openness jsonb not null default '{}'::jsonb,
  -- acquirer persona
  add column if not exists acquisition_criteria text,
  add column if not exists integration_owner text,
  add column if not exists prior_acquisitions int,
  add column if not exists pg_willing boolean,
  add column if not exists existing_leverage text;

-- ---------- Investor mandates: the quantified routing fields ----------
alter table public.investor_mandates
  add column if not exists control_pref text check (control_pref in ('majority','minority','either')),
  add column if not exists concentration_tolerance_pct int check (concentration_tolerance_pct between 0 and 100),
  add column if not exists founder_transition text check (founder_transition in
    ('exit_at_close','transition_1_3yr','stay_and_roll','flexible')),
  add column if not exists structures_offered jsonb not null default '{}'::jsonb,
  add column if not exists leverage_appetite text;
