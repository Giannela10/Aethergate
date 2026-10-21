-- Read-only deployment inspection. Execute manually in SQL Editor after 004.
select column_default from information_schema.columns
where table_schema='public' and table_name='profiles' and column_name='role';
select conname,pg_get_constraintdef(oid) from pg_constraint
where conrelid='public.profiles'::regclass and contype='c';
select tgname,pg_get_triggerdef(oid) from pg_trigger
where tgrelid='auth.users'::regclass and tgname='education_profile';
select pg_get_functiondef('education_private.new_profile()'::regprocedure);
select p.oid::regprocedure,p.prosecdef,p.proconfig
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('admin_set_user_role','admin_set_teacher_subjects');
select has_table_privilege('authenticated','public.profiles','UPDATE') as direct_profile_update,
 has_table_privilege('authenticated','public.admin_audit_log','INSERT') as forge_audit,
 has_function_privilege('anon','public.admin_set_user_role(uuid,text)','EXECUTE') as anon_role_rpc;
-- All three above must be false. authenticated RPC permission does not imply
-- authorization: the function independently checks the caller's database role.
select schemaname,tablename,policyname,cmd,qual,with_check from pg_policies
where schemaname='public' and tablename in ('profiles','teacher_subjects','admin_audit_log','question_keys');
select relname,relrowsecurity from pg_class
where oid in ('public.profiles'::regclass,'public.teacher_subjects'::regclass,'public.admin_audit_log'::regclass,'public.question_keys'::regclass);
-- For actual RLS tests use authenticated student/teacher/admin sessions.
-- The SQL Editor owner bypasses RLS and does not establish those permissions.
