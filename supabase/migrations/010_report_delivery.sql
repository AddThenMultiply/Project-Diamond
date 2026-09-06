-- 010: the scored instruments are no longer gated. The full report renders
-- free; the founder may then ask for a copy by email, which also books the
-- adviser's attention for the Readiness Call. These columns carry that request.

alter table public.leads
  add column if not exists report_requested boolean not null default false,
  add column if not exists report_html      text,
  add column if not exists report_sent_at   timestamptz,
  add column if not exists report_error     text;

comment on column public.leads.report_html is
  'The rendered report the founder saw, captured at the moment they asked for a copy. Our own generated markup, never user-entered HTML.';

-- The client generates the row id so it can name it when it asks the server to
-- send the copy. Inserting with an explicit id is already allowed by the
-- public insert policy; nothing else changes on the table.
