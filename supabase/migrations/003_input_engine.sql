-- 003: The input engine — structured intake for both sides of the platform,
-- and the AI dossier assembler. Idempotent — safe to run twice.
--
-- Founder side: founder_intake (one row per engagement) captures objective,
-- the human questions (the number, life after), business facts, needs/fears,
-- and which fundraising assets they already hold.
-- Investor side: investor_mandates (Story-C investor database layer) —
-- advisor/admin only in round one; investors never touch the platform directly
-- and founder data is never exposed to them (FCA guardrail: introductions
-- happen offline through the authorised transaction partner).
-- get_ai_dossier(engagement) assembles everything the AI needs as one JSONB.

-- ---------- Founder intake ----------
create table if not exists public.founder_intake (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements(id) on delete cascade,
  objective text not null check (objective in ('acquire_growth','exit')),
  -- the human questions (Phase 1 of both processes)
  financial_target numeric,
  life_after text,
  timeline_months int,
  -- business facts
  sector text,
  region text,
  revenue_band text,
  ebitda_band text,
  recurring_revenue_pct int check (recurring_revenue_pct between 0 and 100),
  team_size int,
  founder_dependency int check (founder_dependency between 1 and 5),
  -- needs, wants, fears (free text — primary AI input)
  biggest_need text,
  biggest_fear text,
  non_negotiables text,
  -- capital parameters
  funding_need numeric,
  equity_available_pct int check (equity_available_pct between 0 and 100),
  -- fundraising assets held (FFF Ch. 8 checklist as booleans)
  assets_held jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (engagement_id)
);

alter table public.founder_intake enable row level security;

drop policy if exists founder_intake_select on public.founder_intake;
create policy founder_intake_select on public.founder_intake for select
  using (public.is_engagement_member(engagement_id) or public.current_role_atm() in ('advisor','admin'));

drop policy if exists founder_intake_insert on public.founder_intake;
create policy founder_intake_insert on public.founder_intake for insert
  with check (public.is_engagement_member(engagement_id) or public.current_role_atm() in ('advisor','admin'));

drop policy if exists founder_intake_update on public.founder_intake;
create policy founder_intake_update on public.founder_intake for update
  using (public.is_engagement_member(engagement_id) or public.current_role_atm() in ('advisor','admin'));

-- ---------- Investor mandates (advisor/admin only in round one) ----------
create table if not exists public.investor_mandates (
  id uuid primary key default gen_random_uuid(),
  org_name text not null,
  investor_type text not null check (investor_type in
    ('pe_buyout','growth_equity','family_office','strategic','angel','debt')),
  cheque_min numeric,
  cheque_max numeric,
  revenue_min numeric,
  ebitda_min numeric,
  sectors text[] default '{}',
  geographies text[] default '{}',
  stage text,
  involvement text,
  horizon_years int,
  must_haves text,
  dealbreakers text,
  relationship_owner text,
  status text not null default 'active' check (status in ('active','paused','archived')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.investor_mandates enable row level security;

drop policy if exists investor_mandates_all on public.investor_mandates;
create policy investor_mandates_all on public.investor_mandates for all
  using (public.current_role_atm() in ('advisor','admin'))
  with check (public.current_role_atm() in ('advisor','admin'));

-- ---------- AI dossier assembler ----------
-- One call returns the complete, structured input for any AI task on an
-- engagement. Security definer + explicit membership check; every Edge
-- Function should build its prompt from this, so the AI always sees the
-- same audited picture the humans see.
create or replace function public.get_ai_dossier(eng uuid)
returns jsonb
language sql stable security definer set search_path = public
as $$
  select case
    when not (public.is_engagement_member(eng) or public.current_role_atm() in ('advisor','admin'))
    then null
    else jsonb_build_object(
      'engagement', (select to_jsonb(e) - 'id' from public.engagements e where e.id = eng),
      'intake',     (select to_jsonb(fi) - 'id' - 'engagement_id' from public.founder_intake fi where fi.engagement_id = eng),
      'assessments',(select coalesce(jsonb_agg(to_jsonb(a) - 'id' - 'engagement_id' order by a.taken_at desc), '[]'::jsonb)
                       from public.assessments a where a.engagement_id = eng),
      'open_gaps',  (select coalesce(jsonb_agg(to_jsonb(g) - 'id' - 'engagement_id' order by g.severity desc), '[]'::jsonb)
                       from public.gap_items g where g.engagement_id = eng and g.status = 'open'),
      'roadmap',    (select coalesce(jsonb_agg(to_jsonb(r) - 'id' order by r.due nulls last), '[]'::jsonb)
                       from public.roadmap_actions r where r.engagement_id = eng),
      'documents',  (select coalesce(jsonb_agg(jsonb_build_object('checklist_key', d.checklist_key, 'status', d.status)), '[]'::jsonb)
                       from public.documents d where d.engagement_id = eng),
      'targets',    (select coalesce(jsonb_agg(to_jsonb(t) - 'id' - 'engagement_id' order by t.stage), '[]'::jsonb)
                       from public.targets t where t.engagement_id = eng),
      'generated_at', now()
    )
  end;
$$;

grant execute on function public.get_ai_dossier(uuid) to authenticated;

-- updated_at maintenance
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists founder_intake_touch on public.founder_intake;
create trigger founder_intake_touch before update on public.founder_intake
  for each row execute function public.touch_updated_at();

drop trigger if exists investor_mandates_touch on public.investor_mandates;
create trigger investor_mandates_touch before update on public.investor_mandates
  for each row execute function public.touch_updated_at();
