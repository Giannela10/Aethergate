-- Read-only. Run as postgres after 007.
select to_regclass('public.campaign_saves') as campaign_table;
select c.relrowsecurity as rls_enabled
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname='campaign_saves';
select policyname,cmd,roles,qual from pg_policies
where schemaname='public' and tablename='campaign_saves';
select p.oid::regprocedure as signature,p.prosecdef as security_definer,p.proconfig,
 pg_get_userbyid(p.proowner) as function_owner,
 has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('load_campaign','save_campaign');
select count(*) as auth_users_without_profile
from auth.users u left join public.profiles p on p.id=u.id where p.id is null;
select has_table_privilege('authenticated','public.campaign_saves','SELECT') as own_read_via_rls,
 has_table_privilege('authenticated','public.campaign_saves','INSERT') as direct_insert,
 has_table_privilege('authenticated','public.campaign_saves','UPDATE') as direct_update,
 has_table_privilege('anon','public.campaign_saves','SELECT') as anonymous_read;
-- Expected: RLS=true; own SELECT policy; trusted postgres function owner;
-- authenticated_execute=true / anon_execute=false; missing profiles=0;
-- own_read_via_rls=true, direct_insert=false, direct_update=false, anonymous_read=false.
