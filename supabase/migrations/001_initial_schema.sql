-- ============================================================
-- ATM Founder Platform — Sprint 2: Supabase spine
-- Schema per BLUEPRINT.md §5, extended for Sprints 3–5
-- (DD tracker, integration planner, denormalised engagement_id
--  on roadmap_actions for simpler RLS).
-- Run in the Supabase SQL editor, or apply as a CLI migration.
-- UK English. Idempotent where practical.
-- ============================================================

-- ---------- Identity & engagement spine ----------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role text not null default 'founder' check (role in ('founder','advisor','admin')),
  created_at timestamptz not null default now()
);

-- Auto-create a profile row whenever a user signs up (magic link)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table if not exists public.engagements (
  id uuid primary key default gen_random_uuid(),
  asset text not null check (asset in ('exit_ready','deal_ready')),
  company_name text not null,
  founder_id uuid references public.profiles (id),
  advisor_id uuid references public.profiles (id),
  phase int not null default 1,
  status text not null default 'active' check (status in ('active','paused','completed','closed')),
  target_outcome jsonb,           -- the founder's number + life-after statement
  created_at timestamptz not null default now()
);

-- ---------- Diagnostics & gap engine ----------

create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  face_dimension text check (face_dimension in ('F','A','C','E')),
  dimension text,
  score numeric,
  evidence jsonb,
  taken_at timestamptz not null default now()
);

create table if not exists public.gap_items (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  dimension text,
  description text not null,
  severity int check (severity between 1 and 5),
  status text not null default 'open' check (status in ('open','in_progress','closed')),
  owner text check (owner in ('ai','founder','advisor')),
  created_at timestamptz not null default now()
);

create table if not exists public.roadmap_actions (
  id uuid primary key default gen_random_uuid(),
  gap_item_id uuid references public.gap_items (id) on delete cascade,
  engagement_id uuid not null references public.engagements (id) on delete cascade,  -- denormalised for RLS
  action text not null,
  due date,
  status text not null default 'todo' check (status in ('todo','doing','done')),
  created_at timestamptz not null default now()
);

-- ---------- M&A pipeline (Deal Ready; reusable as buyer pipeline) ----------

create table if not exists public.targets (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  name text not null,
  stage text not null default 'longlist' check (stage in
    ('longlist','shortlist','approached','meeting','hot','dd','spa','completed','integration','dropped')),
  enrichment jsonb,
  relationship_notes text,
  created_at timestamptz not null default now()
);

-- ---------- Due diligence tracker (Sprint 4) ----------

create table if not exists public.dd_items (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  target_id uuid references public.targets (id) on delete cascade,
  area text not null,               -- e.g. Financial, Legal, Commercial, People, Tax
  question text not null,
  response text,
  red_flag boolean not null default false,
  status text not null default 'open' check (status in ('open','answered','resolved','red')),
  created_at timestamptz not null default now()
);

-- ---------- Integration planner / 100-day plan (Sprint 4) ----------

create table if not exists public.integration_actions (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  target_id uuid references public.targets (id) on delete cascade,
  day_offset int not null default 0,     -- days from completion (0–100)
  action text not null,
  owner text,
  culture_risk boolean not null default false,
  status text not null default 'todo' check (status in ('todo','doing','done')),
  created_at timestamptz not null default now()
);

-- ---------- Documents & data room ----------

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  doc_type text,
  storage_path text,
  checklist_key text,
  status text not null default 'missing' check (status in ('missing','draft','ai_drafted','review','approved')),
  updated_at timestamptz not null default now()
);

-- one row per checklist item per engagement (Edge Functions upsert on this pair)
create unique index if not exists documents_engagement_checklist_uq
  on public.documents (engagement_id, checklist_key);

-- ---------- The audit-defensibility layer ----------

create table if not exists public.ai_runs (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  task text not null,
  model text,
  input_hash text,
  output jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.human_signoffs (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references public.engagements (id) on delete cascade,
  gate text not null,               -- e.g. 'advance_to_2', 'clarity_statement', 'business_plan'
  signed_by uuid not null references public.profiles (id),
  decision text not null check (decision in ('approved','rejected','needs_work')),
  note text,
  signed_at timestamptz not null default now()
);

-- ---------- Helper functions (security definer, used by RLS) ----------

create or replace function public.current_role_atm()
returns text
language sql stable security definer set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()), 'founder');
$$;

create or replace function public.is_engagement_member(eng uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.engagements e
    where e.id = eng
      and (e.founder_id = auth.uid()
           or e.advisor_id = auth.uid()
           or public.current_role_atm() = 'admin')
  );
$$;

-- ---------- The AI/Human gate, enforced in the database ----------
-- engagements.phase may only advance when a matching approved
-- human sign-off exists (gate = 'advance_to_<new phase>'),
-- and only an advisor/admin may perform the update.

create or replace function public.enforce_phase_gate()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.phase is distinct from old.phase then
    if new.phase < old.phase then
      -- allow stepping back without a gate (correcting mistakes), advisors only
      if public.current_role_atm() not in ('advisor','admin') then
        raise exception 'Only an advisor may change the engagement phase.';
      end if;
      return new;
    end if;
    if public.current_role_atm() not in ('advisor','admin') then
      raise exception 'Only an advisor may advance the engagement phase.';
    end if;
    if not exists (
      select 1 from public.human_signoffs s
      where s.engagement_id = new.id
        and s.gate = 'advance_to_' || new.phase
        and s.decision = 'approved'
    ) then
      raise exception 'Phase gate: no approved human sign-off recorded for advance_to_%', new.phase;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_phase_gate on public.engagements;
create trigger trg_phase_gate
  before update on public.engagements
  for each row execute function public.enforce_phase_gate();

-- ---------- Row Level Security ----------

alter table public.profiles            enable row level security;
alter table public.engagements         enable row level security;
alter table public.assessments         enable row level security;
alter table public.gap_items           enable row level security;
alter table public.roadmap_actions     enable row level security;
alter table public.targets             enable row level security;
alter table public.dd_items            enable row level security;
alter table public.integration_actions enable row level security;
alter table public.documents           enable row level security;
alter table public.ai_runs             enable row level security;
alter table public.human_signoffs      enable row level security;

-- profiles: read own profile; advisors/admins may read all (portfolio view)
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select
  using (id = auth.uid() or public.current_role_atm() in ('advisor','admin'));
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid() and role = (select role from public.profiles p2 where p2.id = auth.uid()));
-- note: role changes are done by an admin in the dashboard/SQL, not by users.

-- engagements
drop policy if exists engagements_select on public.engagements;
create policy engagements_select on public.engagements for select
  using (founder_id = auth.uid() or advisor_id = auth.uid()
         or public.current_role_atm() = 'admin');
drop policy if exists engagements_insert on public.engagements;
create policy engagements_insert on public.engagements for insert
  with check (founder_id = auth.uid() or public.current_role_atm() in ('advisor','admin'));
drop policy if exists engagements_update on public.engagements;
create policy engagements_update on public.engagements for update
  using (public.is_engagement_member(id));

-- generic membership policies for child tables
drop policy if exists assessments_all on public.assessments;
create policy assessments_all on public.assessments for all
  using (public.is_engagement_member(engagement_id))
  with check (public.is_engagement_member(engagement_id));

drop policy if exists gap_items_all on public.gap_items;
create policy gap_items_all on public.gap_items for all
  using (public.is_engagement_member(engagement_id))
  with check (public.is_engagement_member(engagement_id));

drop policy if exists roadmap_actions_all on public.roadmap_actions;
create policy roadmap_actions_all on public.roadmap_actions for all
  using (public.is_engagement_member(engagement_id))
  with check (public.is_engagement_member(engagement_id));

drop policy if exists targets_all on public.targets;
create policy targets_all on public.targets for all
  using (public.is_engagement_member(engagement_id))
  with check (public.is_engagement_member(engagement_id));

drop policy if exists dd_items_all on public.dd_items;
create policy dd_items_all on public.dd_items for all
  using (public.is_engagement_member(engagement_id))
  with check (public.is_engagement_member(engagement_id));

drop policy if exists integration_actions_all on public.integration_actions;
create policy integration_actions_all on public.integration_actions for all
  using (public.is_engagement_member(engagement_id))
  with check (public.is_engagement_member(engagement_id));

drop policy if exists documents_all on public.documents;
create policy documents_all on public.documents for all
  using (public.is_engagement_member(engagement_id))
  with check (public.is_engagement_member(engagement_id));

-- ai_runs: members may read; only the service role (Edge Functions) writes.
drop policy if exists ai_runs_select on public.ai_runs;
create policy ai_runs_select on public.ai_runs for select
  using (public.is_engagement_member(engagement_id));
-- (no insert/update/delete policy for authenticated users — service role bypasses RLS)

-- human_signoffs: members read; only advisor/admin members insert; no edits or deletes (audit trail)
drop policy if exists human_signoffs_select on public.human_signoffs;
create policy human_signoffs_select on public.human_signoffs for select
  using (public.is_engagement_member(engagement_id));
drop policy if exists human_signoffs_insert on public.human_signoffs;
create policy human_signoffs_insert on public.human_signoffs for insert
  with check (public.is_engagement_member(engagement_id)
              and public.current_role_atm() in ('advisor','admin')
              and signed_by = auth.uid());

-- ---------- Storage: per-engagement data room ----------
-- Create bucket 'dataroom' (private). Paths are '<engagement_id>/<filename>'.
insert into storage.buckets (id, name, public)
values ('dataroom', 'dataroom', false)
on conflict (id) do nothing;

drop policy if exists dataroom_rw on storage.objects;
create policy dataroom_rw on storage.objects for all
  using (bucket_id = 'dataroom'
         and public.is_engagement_member(((string_to_array(name, '/'))[1])::uuid))
  with check (bucket_id = 'dataroom'
              and public.is_engagement_member(((string_to_array(name, '/'))[1])::uuid));
