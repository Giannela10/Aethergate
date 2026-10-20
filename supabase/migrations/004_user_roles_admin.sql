-- Apply AFTER 001 and any required profile repairs. No existing role is changed.
begin;
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check(role in ('pending','student','teacher','admin'));
alter table public.profiles alter column role set default 'pending';
create or replace function education_private.new_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,email,display_name,avatar_url,role)
 values(new.id,coalesce(new.email,''),coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'),''),nullif(trim(new.raw_user_meta_data->>'full_name'),''),'Usuario'),coalesce(new.raw_user_meta_data->>'avatar_url',''),'pending')
 on conflict(id) do nothing;
 return new;
end $$;
revoke all on function education_private.new_profile() from public,anon,authenticated;
drop trigger if exists education_profile on auth.users;
create trigger education_profile after insert on auth.users for each row execute function education_private.new_profile();

create table if not exists public.admin_audit_log (
 id uuid primary key default gen_random_uuid(),
 admin_id uuid not null references public.profiles(id),
 target_user_id uuid not null references public.profiles(id),
 action text not null, old_role text, new_role text,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists profiles_role_created on public.profiles(role,created_at desc);
create index if not exists profiles_email_lower on public.profiles(lower(email));
create index if not exists admin_audit_target_time on public.admin_audit_log(target_user_id,created_at desc);
create index if not exists admin_audit_actor_time on public.admin_audit_log(admin_id,created_at desc);
alter table public.admin_audit_log enable row level security;
revoke all on public.admin_audit_log from public,anon,authenticated;
grant select on public.admin_audit_log to authenticated;
create policy audit_admin_read on public.admin_audit_log for select to authenticated using(education_private.role()='admin');
-- No client, including admin, can write profiles or forge audit records directly.
revoke insert,update,delete on public.profiles from public,anon,authenticated;

create or replace function public.admin_set_user_role(target_user_id uuid,new_role text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare actor uuid:=auth.uid(); actor_role text; previous_role text; updated public.profiles;
begin
 if actor is null then raise exception using errcode='42501',message='Admin required'; end if;
 -- Serialize ALL role changes. Two simultaneous demotions cannot remove both admins.
 perform pg_catalog.pg_advisory_xact_lock(804004);
 select p.role into actor_role from public.profiles p where p.id=actor for update;
 if actor_role is distinct from 'admin' then raise exception using errcode='42501',message='Admin required'; end if;
 if new_role is null or new_role not in ('pending','student','teacher','admin') then raise exception 'Invalid role'; end if;
 select p.role into previous_role from public.profiles p where p.id=target_user_id for update;
 if not found then raise exception 'Profile not found'; end if;
 if previous_role='admin' and new_role<>'admin' and (select count(*) from public.profiles p where p.role='admin')<=1 then
  raise exception 'LAST_ADMIN';
 end if;
 if previous_role<>new_role then
  update public.profiles p set role=new_role,updated_at=now() where p.id=target_user_id returning p.* into updated;
  insert into public.admin_audit_log(admin_id,target_user_id,action,old_role,new_role)
  values(actor,target_user_id,'role_changed',previous_role,new_role);
 else
  select p.* into updated from public.profiles p where p.id=target_user_id;
 end if;
 return to_jsonb(updated);
end $$;
revoke all on function public.admin_set_user_role(uuid,text) from public,anon,authenticated;
grant execute on function public.admin_set_user_role(uuid,text) to authenticated;

-- Replace assignments atomically. The identity and admin role are checked again
-- in PostgreSQL; a forged client role has no effect.
create or replace function public.admin_set_teacher_subjects(target_user_id uuid,subject_ids uuid[])
returns jsonb language plpgsql security definer set search_path = '' as $$
declare actor uuid:=auth.uid(); actor_role text; target_role text;
begin
 if actor is null then raise exception using errcode='42501',message='Admin required'; end if;
 perform pg_catalog.pg_advisory_xact_lock(804004);
 select p.role into actor_role from public.profiles p where p.id=actor for update;
 if actor_role is distinct from 'admin' then raise exception using errcode='42501',message='Admin required'; end if;
 select p.role into target_role from public.profiles p where p.id=target_user_id for update;
 if target_role is distinct from 'teacher' then raise exception 'Target must be teacher'; end if;
 if subject_ids is null or exists(select 1 from unnest(subject_ids) s(id) where s.id is null or not exists(select 1 from public.subjects x where x.id=s.id)) then raise exception 'Invalid subjects'; end if;
 delete from public.teacher_subjects t where t.teacher_id=target_user_id;
 insert into public.teacher_subjects(teacher_id,subject_id) select target_user_id,s.id from (select distinct unnest(subject_ids) id) s;
 insert into public.admin_audit_log(admin_id,target_user_id,action,old_role,new_role,details)
 values(actor,target_user_id,'subjects_assigned',target_role,target_role,jsonb_build_object('subject_ids',subject_ids));
 return jsonb_build_object('ok',true);
end $$;
revoke all on function public.admin_set_teacher_subjects(uuid,uuid[]) from public,anon,authenticated;
grant execute on function public.admin_set_teacher_subjects(uuid,uuid[]) to authenticated;
-- Existing direct assignment policies are admin-only, kept for compatibility.
drop policy if exists assignments_read on public.teacher_subjects;
create policy assignments_read on public.teacher_subjects for select to authenticated using(
 education_private.role()='admin' or (education_private.role()='teacher' and teacher_id=auth.uid()));
drop policy if exists assignments_admin on public.teacher_subjects;
create policy assignments_admin on public.teacher_subjects for all to authenticated using(education_private.role()='admin') with check(education_private.role()='admin');

-- Staff may also play without changing their role; pending remains blocked.
create or replace function public.get_random_question(p_subject text,p_context text,p_exclude uuid default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare q public.questions; uid uuid:=auth.uid();
begin
 if uid is null or coalesce(education_private.role(),'') not in ('student','teacher','admin') then raise exception 'Playable account required'; end if;
 if p_context not in ('floor_unlock','teacher_challenge','computer','mission','training') or p_context is null then raise exception 'Invalid context'; end if;
 if p_context='floor_unlock' and p_subject<>'INF_GENERAL' then raise exception 'Unsupported floor pilot'; end if;
 select x.* into q from public.questions x join public.subjects s on s.id=x.subject_id
 where s.code=p_subject and s.active and x.active and exists(select 1 from public.question_keys k where k.question_id=x.id)
 order by (x.id is distinct from p_exclude) desc,random() limit 1;
 if not found then raise exception 'No active questions'; end if;
 insert into education_private.question_tickets(student_id,question_id,context) values(uid,q.id,p_context)
 on conflict(student_id) do update set question_id=excluded.question_id,context=excluded.context,expires_at=now()+interval '15 minutes';
 return to_jsonb(q);
end $$;
create or replace function public.submit_answer(p_question_id uuid,p_selected_option text,p_context text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare uid uuid:=auth.uid(); key public.question_keys; q public.questions; hit boolean; ticket education_private.question_tickets;
begin
 if uid is null or coalesce(education_private.role(),'') not in ('student','teacher','admin') then raise exception 'Playable account required'; end if;
 if p_selected_option not in ('A','B','C','D') or p_selected_option is null then raise exception 'Invalid option'; end if;
 if p_context not in ('floor_unlock','teacher_challenge','computer','mission','training') or p_context is null then raise exception 'Invalid context'; end if;
 select * into ticket from education_private.question_tickets where student_id=uid for update;
 if not found or ticket.question_id<>p_question_id or ticket.context<>p_context or ticket.expires_at<now() then raise exception 'Expired or missing question'; end if;
 select x.* into q from public.questions x join public.subjects s on s.id=x.subject_id where x.id=p_question_id and x.active and s.active;
 if not found then raise exception 'Question not available'; end if;
 select * into strict key from public.question_keys where question_id=p_question_id;
 hit=key.correct_option=p_selected_option;
 delete from education_private.question_tickets where student_id=uid;
 insert into public.question_attempts(student_id,question_id,selected_option,correct,context) values(uid,p_question_id,p_selected_option,hit,p_context);
 insert into public.academic_progress(student_id,subject_id,answered,correct,incorrect) values(uid,q.subject_id,1,case when hit then 1 else 0 end,case when hit then 0 else 1 end)
 on conflict(student_id,subject_id) do update set answered=public.academic_progress.answered+1,correct=public.academic_progress.correct+excluded.correct,incorrect=public.academic_progress.incorrect+excluded.incorrect,updated_at=now();
 return jsonb_build_object('correct',hit,'explanation',key.explanation,'question_id',p_question_id,'selected',p_selected_option);
end $$;
commit;
