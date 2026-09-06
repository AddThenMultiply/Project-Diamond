-- 011: tighten who may call the SECURITY DEFINER helpers.
--
-- Supabase's security advisor (6 September) flagged every helper as callable
-- by anonymous visitors through /rest/v1/rpc. Trigger functions never need a
-- caller, and the two data helpers are for the server (service role) only.
-- current_role_atm() and is_engagement_member() stay callable by anon and
-- authenticated because the row-level policies evaluate them for every
-- request; for an anonymous visitor they simply return null or false.

revoke execute on function public.assign_default_advisor()        from public, anon, authenticated;
revoke execute on function public.enforce_document_status_gate()  from public, anon, authenticated;
revoke execute on function public.enforce_phase_gate()            from public, anon, authenticated;
revoke execute on function public.handle_new_user()               from public, anon, authenticated;
revoke execute on function public.touch_updated_at()              from public, anon, authenticated;
revoke execute on function public.get_ai_dossier(uuid)            from public, anon, authenticated;
revoke execute on function public.promote_investor_submission(uuid, text) from public, anon, authenticated;
revoke execute on function public.current_role_atm()              from public;
revoke execute on function public.is_engagement_member(uuid)      from public;

-- Pin the search path on the one helper the advisor flagged for it.
alter function public.touch_updated_at() set search_path = public;
