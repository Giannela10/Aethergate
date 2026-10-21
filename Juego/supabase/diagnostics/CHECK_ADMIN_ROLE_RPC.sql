-- Read-only SQL Editor diagnosis. No account changes.
select to_regprocedure('public.admin_set_user_role(uuid,text)') as role_rpc,
 to_regclass('public.admin_audit_log') as audit_table;
select p.oid::regprocedure as signature,p.proargnames,p.prosecdef,p.proconfig,
 pg_get_userbyid(p.proowner) as owner,
 has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname='admin_set_user_role';
select id,email,display_name,role from public.profiles
where email='nicolashernandezdelarosa@gmail.com';
-- UUID captured from the selected UI entry, never inferred from display_name.
select id,display_name,role from public.profiles
where id='6b7748aa-71a5-46dc-9f4a-c27f1e6ec93e'::uuid;
