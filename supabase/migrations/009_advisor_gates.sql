-- 005: advisor assignment + advisor-only document approval + scoped intake reads
-- Closes the three structural findings from the August 2026 site audit:
--   1. engagements were created with no advisor_id, so the advisor console
--      (which filters on advisor_id) showed an empty portfolio for advisor roles;
--   2. any engagement member could set a document's status to 'approved' —
--      customer-facing approval must be a named human advisor decision,
--      enforced in Postgres like the phase gate;
--   3. any advisor could read every founder_intake regardless of engagement.

-- ---------- 1. Auto-assign the advisor on engagement creation ----------
-- With a single practising advisor this is deterministic. When there are
-- several, replace with an explicit assignment control in the console.

create or replace function public.assign_default_advisor()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.advisor_id is null then
    select id into new.advisor_id
    from public.profiles
    where role = 'advisor'
    order by created_at
    limit 1;
    -- fall back to an admin so the engagement is never unowned
    if new.advisor_id is null then
      select id into new.advisor_id
      from public.profiles
      where role = 'admin'
      order by created_at
      limit 1;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_assign_advisor on public.engagements;
create trigger trg_assign_advisor
  before insert on public.engagements
  for each row execute function public.assign_default_advisor();

-- Backfill engagements created before this trigger existed
update public.engagements
set advisor_id = (
  select id from public.profiles where role = 'advisor'
  order by created_at limit 1
)
where advisor_id is null
  and exists (select 1 from public.profiles where role = 'advisor');

-- ---------- 2. Document approval is an advisor/admin decision ----------
-- 'approved' (entering or leaving it) and 'ai_drafted' may only be set by an
-- advisor/admin session, or by the platform itself (Edge Functions run with
-- the service role, where auth.uid() is null). Founders keep
-- missing/draft/review for their own uploads.

create or replace function public.enforce_document_status_gate()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  entering_protected boolean;
  leaving_approved boolean;
begin
  entering_protected :=
    new.status in ('approved','ai_drafted')
    and (tg_op = 'INSERT' or new.status is distinct from old.status);
  leaving_approved :=
    tg_op = 'UPDATE' and old.status = 'approved'
    and new.status is distinct from old.status;

  if (entering_protected or leaving_approved)
     and auth.uid() is not null
     and public.current_role_atm() not in ('advisor','admin') then
    raise exception 'Only an advisor may set a document to % status.', new.status;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_document_status_gate on public.documents;
create trigger trg_document_status_gate
  before insert or update on public.documents
  for each row execute function public.enforce_document_status_gate();

-- ---------- 3. Intake visible to engagement members and admin only ----------
-- is_engagement_member() already admits the assigned advisor; the blanket
-- advisor clause let any advisor read every intake.

drop policy if exists founder_intake_select on public.founder_intake;
create policy founder_intake_select on public.founder_intake for select
  using (public.is_engagement_member(engagement_id) or public.current_role_atm() = 'admin');

drop policy if exists founder_intake_update on public.founder_intake;
create policy founder_intake_update on public.founder_intake for update
  using (public.is_engagement_member(engagement_id) or public.current_role_atm() = 'admin');
