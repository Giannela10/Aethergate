-- Run the ENTIRE file in Supabase SQL Editor as the migration owner (postgres).
-- Requires public.profiles with id, role and updated_at (migration 001).
-- Does not invoke the RPC or change existing accounts.
begin;

create table if not exists public.admin_audit_log (
 id uuid primary key default gen_random_uuid(),
 admin_id uuid not null references public.profiles(id),
 target_user_id uuid not null references public.profiles(id),
 action text not null,
 old_role text,
 new_role text,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.admin_audit_log enable row level security;
revoke all on public.admin_audit_log from public, anon, authenticated;
grant select on public.admin_audit_log to authenticated;
-- Existing audit read policies are preserved. A newly created table denies
-- client reads until an appropriate SELECT policy is installed.

-- Parameter names cannot be renamed with CREATE OR REPLACE. Remove only
-- functions with this exact public name, including conflicting overloads.
-- RESTRICT (never CASCADE): any dependent object aborts the whole transaction,
-- preserving the previous functions and reporting the dependency to the operator.
do $migration$
declare v_signature text;
begin
 for v_signature in
  select p.oid::pg_catalog.regprocedure::text
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'admin_set_user_role'
    and p.prokind = 'f'
 loop
  execute pg_catalog.format('drop function %s restrict', v_signature);
 end loop;
end
$migration$;

create function public.admin_set_user_role(
 target_user_id uuid,
 new_role text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
 caller_id uuid := auth.uid();
 v_target_id uuid := $1;
 v_new_role text := $2;
 v_caller_role text;
 v_old_role text;
 v_updated public.profiles;
begin
 if caller_id is null then
  raise exception using errcode = '42501', message = 'Admin access required';
 end if;
 -- Same lock as 004/005 and admin_set_teacher_subjects: serialize role changes
 -- before checking authorization and counting admins, including concurrent calls.
 perform pg_catalog.pg_advisory_xact_lock(804004);
 select p.role into v_caller_role
 from public.profiles p where p.id = caller_id for update;
 if v_caller_role is distinct from 'admin' then
  raise exception using errcode = '42501', message = 'Admin access required';
 end if;
 if v_new_role is null or v_new_role not in ('pending','student','teacher','admin') then
  raise exception 'Invalid role';
 end if;
 select p.role into v_old_role
 from public.profiles p where p.id = v_target_id for update;
 if not found then
  raise exception 'Profile not found';
 end if;
 -- Also protect the last admin when targeted by another caller.
 if v_old_role = 'admin' and v_new_role <> 'admin'
    and (select count(*) from public.profiles p where p.role = 'admin') <= 1 then
  raise exception 'LAST_ADMIN';
 end if;
 if v_old_role is distinct from v_new_role then
  update public.profiles p
  set role = v_new_role, updated_at = now()
  where p.id = v_target_id returning p.* into v_updated;
  insert into public.admin_audit_log
   (admin_id,target_user_id,action,old_role,new_role,created_at)
  values (caller_id,v_target_id,'role_change',v_old_role,v_new_role,now());
 else
  select p.* into v_updated from public.profiles p where p.id = v_target_id;
 end if;
 -- Godot expects a JSON object containing the updated profile, not a boolean.
 return to_jsonb(v_updated);
end
$function$;

revoke all on function public.admin_set_user_role(uuid, text) from public, anon, authenticated;
grant execute on function public.admin_set_user_role(uuid, text) to authenticated;

notify pgrst, 'reload schema';
commit;

-- Read-only verification: exactly ONE row; arg_names={target_user_id,new_role},
-- result_type=jsonb, security_definer=true, authenticated_execute=true,
-- anon_execute=false. The owner must be the trusted migration owner (postgres).
select p.oid::regprocedure as signature,
 p.proargnames as arg_names,
 pg_catalog.pg_get_function_result(p.oid) as result_type,
 p.prosecdef as security_definer, p.proconfig,
 pg_catalog.pg_get_userbyid(p.proowner) as owner,
 has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'admin_set_user_role';
