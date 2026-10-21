-- Read-only checks to run in SQL Editor AFTER 001 (no accounts created).
-- This checks schema/grants; it does not replace real-role integration tests.
select c.relname as table_name,c.relrowsecurity as rls_enabled
from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in
('profiles','subjects','teacher_subjects','questions','question_keys','question_attempts','academic_progress')
order by c.relname;

select schemaname,tablename,policyname,cmd,roles
from pg_catalog.pg_policies where schemaname='public'
and tablename in ('profiles','subjects','teacher_subjects','questions','question_keys','question_attempts','academic_progress')
order by tablename,policyname;

select t.tgname as trigger_name,t.tgenabled as enabled,p.prosecdef as security_definer,p.proconfig as function_settings
from pg_catalog.pg_trigger t join pg_catalog.pg_proc p on p.oid=t.tgfoid
where t.tgrelid='auth.users'::regclass and t.tgname='education_profile';

select has_table_privilege('authenticated','public.profiles','UPDATE') as client_can_update_role,
has_table_privilege('authenticated','public.question_attempts','INSERT') as client_can_forge_attempts,
has_table_privilege('authenticated','education_private.question_tickets','SELECT') as client_can_read_tickets;
-- All three privilege flags above must be false.

select p.proname,p.prosecdef as security_definer,p.proconfig as function_settings,
has_function_privilege('anon',p.oid,'EXECUTE') as anonymous_can_execute
from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('save_question','get_random_question','submit_answer');
-- anonymous_can_execute must be false. save_question is intentionally invoker.
