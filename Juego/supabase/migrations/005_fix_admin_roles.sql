-- Manual corrective migration, after 004_user_roles_admin.sql.
-- Does NOT change any user's role and does NOT invoke the RPC.
begin;
do $$
begin
 if to_regclass('public.admin_audit_log') is null then
  raise exception 'Apply 004_user_roles_admin.sql first: admin_audit_log is missing';
 end if;
end $$;

create or replace function public.admin_set_user_role(target_user_id uuid,new_role text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 v_actor uuid:=auth.uid();
 v_target uuid:=$1;
 v_new_role text:=$2;
 v_actor_role text;
 v_old_role text;
 v_updated public.profiles;
begin
 if v_actor is null then raise exception using errcode='42501',message='Admin required'; end if;
 perform pg_catalog.pg_advisory_xact_lock(804004);
 select p.role into v_actor_role from public.profiles p where p.id=v_actor for update;
 if v_actor_role is distinct from 'admin' then raise exception using errcode='42501',message='Admin required'; end if;
 if v_new_role is null or v_new_role not in ('pending','student','teacher','admin') then raise exception 'Invalid role'; end if;
 select p.role into v_old_role from public.profiles p where p.id=v_target for update;
 if not found then raise exception 'Profile not found'; end if;
 if v_old_role='admin' and v_new_role<>'admin' and (select count(*) from public.profiles p where p.role='admin')<=1 then
  raise exception 'LAST_ADMIN';
 end if;
 if v_old_role<>v_new_role then
  update public.profiles p set role=v_new_role,updated_at=now() where p.id=v_target returning p.* into v_updated;
  insert into public.admin_audit_log(admin_id,target_user_id,action,old_role,new_role)
  values(v_actor,v_target,'role_changed',v_old_role,v_new_role);
 else
  select p.* into v_updated from public.profiles p where p.id=v_target;
 end if;
 return to_jsonb(v_updated);
end $$;
revoke all on function public.admin_set_user_role(uuid,text) from public,anon,authenticated;
grant execute on function public.admin_set_user_role(uuid,text) to authenticated;
revoke insert,update,delete on public.profiles from public,anon,authenticated;
notify pgrst, 'reload schema';
commit;

-- Read-only verification. All should show the intended signature, a trusted
-- owner, SECURITY DEFINER=true, search_path="", authenticated=true, anon=false.
select p.oid::regprocedure as signature,p.proargnames,p.prosecdef,p.proconfig,
 pg_get_userbyid(p.proowner) as owner,
 has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname='admin_set_user_role';
