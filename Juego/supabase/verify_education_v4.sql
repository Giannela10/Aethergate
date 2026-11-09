-- Read-only verification after manual application of 008 and 009.
select n.nspname,c.relname,c.relrowsecurity
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where (n.nspname,c.relname) in (('public','learning_activities'),('public','learning_access'),('public','learning_attempts'),('education_private','activity_solutions'),('education_private','activity_tickets'));
-- Both private solution permissions must be false. No client writes to access.
select has_table_privilege('authenticated','education_private.activity_solutions','SELECT') as solutions_exposed,
has_table_privilege('anon','education_private.activity_solutions','SELECT') as anonymous_solutions_exposed,
has_table_privilege('authenticated','public.learning_access','INSERT,UPDATE') as access_client_writable;
select n.nspname,p.proname,p.prosecdef,p.proconfig
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('save_learning_activity','get_learning_activity','submit_learning_activity','learning_staff_bank','learning_statistics','education_statistics_v4','learning_history_v4','admin_save_subject');
select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies
where tablename in ('learning_activities','learning_access','learning_attempts','activity_solutions','activity_tickets') or policyname like 'educational_images_%';
select id,public,file_size_limit,allowed_mime_types from storage.buckets where id='educational-images';
-- Also test with authorized student and teacher sessions. Catalog inspection is
-- not proof that real RLS, callbacks, SMTP or cross-device synchronization work.
