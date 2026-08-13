-- 007: Investor submissions staging — the intake side of the register
-- Two feeds into one review queue: founders load investors they already have
-- relationships with; the scanning/research function proposes new candidates.
-- Nothing reaches the canonical register (investor_mandates) without advisor
-- approval — the Augmentation Line: AI/founders propose, humans admit.

create table public.investor_submissions (
  id                   uuid primary key default gen_random_uuid(),
  created_at           timestamptz not null default now(),
  source               text not null default 'founder'
                         check (source in ('founder','scan','advisor')),
  submitted_by         uuid references auth.users(id),
  engagement_id        uuid references public.engagements(id),
  org_name             text not null,
  investor_type        text,
  website              text,
  contact_name         text,
  contact_email        text,
  linkedin_url         text,
  relationship         text,   -- e.g. 'our existing investor', 'warm intro available', 'met at event'
  stage                text,   -- free text at intake; normalised on promotion
  cheque               text,
  sectors              text,
  geography            text,
  female_founder_focus text,
  notes                text,
  status               text not null default 'pending'
                         check (status in ('pending','approved','rejected','merged')),
  review_note          text,
  reviewed_by          uuid references auth.users(id),
  reviewed_at          timestamptz,
  promoted_mandate_id  uuid references public.investor_mandates(id)
);

create index investor_submissions_status_idx on public.investor_submissions (status, created_at);

alter table public.investor_submissions enable row level security;

-- Founders: may submit, and see only their own submissions (never the register).
create policy investor_submissions_insert_own on public.investor_submissions for insert
  to authenticated
  with check (submitted_by = auth.uid() or public.current_role_atm() in ('advisor','admin'));

create policy investor_submissions_select_own on public.investor_submissions for select
  to authenticated
  using (submitted_by = auth.uid() or public.current_role_atm() in ('advisor','admin'));

-- Advisors/admins: full review powers (update status, promote, reject).
create policy investor_submissions_update_staff on public.investor_submissions for update
  to authenticated
  using (public.current_role_atm() in ('advisor','admin'))
  with check (public.current_role_atm() in ('advisor','admin'));

-- Promotion helper: advisor approves a submission into the canonical register.
create or replace function public.promote_investor_submission(sub_id uuid, target_register text default 'female_investors_uk')
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  s record;
  new_id uuid;
begin
  if public.current_role_atm() not in ('advisor','admin') then
    raise exception 'Only advisors or admins can promote submissions';
  end if;
  select * into s from public.investor_submissions where id = sub_id and status = 'pending';
  if not found then
    raise exception 'Submission not found or already reviewed';
  end if;
  insert into public.investor_mandates
    (org_name, investor_type, register, website, contact_email, linkedin_url,
     target_cheque, female_founder_focus, notes, status, verification_status)
  values
    (s.org_name, coalesce(s.investor_type,'other'), target_register, s.website, s.contact_email, s.linkedin_url,
     s.cheque, s.female_founder_focus,
     concat_ws(' | ', 'From submission ('||s.source||')', s.relationship, s.notes),
     'active', 'verify_before_approach')
  on conflict (org_name, register) do nothing
  returning id into new_id;
  update public.investor_submissions
     set status = case when new_id is null then 'merged' else 'approved' end,
         reviewed_by = auth.uid(), reviewed_at = now(), promoted_mandate_id = new_id
   where id = sub_id;
  return new_id;
end $$;

grant execute on function public.promote_investor_submission(uuid, text) to authenticated;
