-- 002: grant execute on RLS helper functions to the API roles.
-- Fixes: "permission denied for function current_role_atm" (42501) on
-- profiles/engagements — newer Supabase projects revoke default EXECUTE on
-- public-schema functions, so the security-definer helpers used inside RLS
-- policies must be granted explicitly. Idempotent — safe to run twice.

grant execute on function public.current_role_atm() to anon, authenticated;
grant execute on function public.is_engagement_member(uuid) to anon, authenticated;

-- Trigger functions (handle_new_user, enforce_phase_gate) run as table owners
-- via triggers and need no client-role grants.
