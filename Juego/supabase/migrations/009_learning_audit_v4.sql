-- Additive administration and aggregate statistics. Manual deployment only.
begin;
create function public.admin_save_subject(p_id uuid,p_data jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare sid uuid; requested_floor integer;
begin
 if auth.uid() is null or education_private.role() is distinct from 'admin' then raise exception 'Admin required'; end if;
 requested_floor:=(p_data->>'floor')::integer;
	if p_id is not null and exists(select 1 from public.subjects where id=p_id and code is distinct from p_data->>'code') then raise exception 'Subject code is immutable; existing game references must remain valid'; end if;
 if p_data->>'code' !~ '^[A-Z0-9_]{2,60}$' or nullif(trim(p_data->>'name'),'') is null or nullif(trim(p_data->>'area'),'') is null then raise exception 'Invalid subject'; end if;
 if p_id is not null and exists(select 1 from public.subjects where id=p_id and floor<>requested_floor) and (exists(select 1 from public.questions where subject_id=p_id) or exists(select 1 from public.learning_activities where subject_id=p_id)) then raise exception 'Cannot relocate a subject with existing educational content'; end if;
 if p_id is null then
  insert into public.subjects(code,name,floor,area,active) values(p_data->>'code',p_data->>'name',requested_floor,p_data->>'area',coalesce((p_data->>'active')::boolean,true)) returning id into sid;
 else
  update public.subjects set code=p_data->>'code',name=p_data->>'name',floor=requested_floor,area=p_data->>'area',active=coalesce((p_data->>'active')::boolean,true) where id=p_id returning id into sid;
  if not found then raise exception 'Subject missing'; end if;
 end if;
 insert into public.admin_audit_log(admin_id,target_user_id,action,details) values(auth.uid(),auth.uid(),'subject_saved',jsonb_build_object('subject_id',sid));
 return sid;
end $$;
create function education_private.activity_audit_v4() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 insert into public.admin_audit_log(admin_id,target_user_id,action,details) values(auth.uid(),auth.uid(),'learning_activity_'||lower(TG_OP),jsonb_build_object('activity_id',new.id,'subject_id',new.subject_id,'active',new.active));
 return new;
end $$;
create trigger learning_activity_audit after insert or update on public.learning_activities for each row execute function education_private.activity_audit_v4();
revoke all on function education_private.activity_audit_v4() from public,anon,authenticated;
create function public.education_statistics_v4() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Staff required'; end if;
 return public.learning_statistics() || coalesce((select jsonb_agg(to_jsonb(stats)) from (
 select q.id,q.subject_id,'Banco de preguntas original'::text as unit,q.question_text as prompt,count(t.id) as attempts,count(t.id) filter(where t.correct) as correct,count(t.id) filter(where not t.correct) as incorrect,0 as reflections
 from public.questions q left join public.question_attempts t on t.question_id=q.id
 where education_private.role()='admin' or education_private.assigned(q.subject_id) group by q.id
 ) stats),'[]'::jsonb);
end $$;
create view education_private.learning_attempt_stream_v4 as
select a.subject_id,t.correct,t.created_at from public.learning_attempts t join public.learning_activities a on a.id=t.activity_id where not t.is_training
union all
select q.subject_id,t.correct,t.created_at from public.question_attempts t join public.questions q on q.id=t.question_id;
revoke all on education_private.learning_attempt_stream_v4 from public,anon,authenticated;
create function public.learning_history_v4() returns jsonb language plpgsql security definer set search_path='' as $$
declare subjects jsonb; days jsonb; published jsonb;
begin
 if coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Staff required'; end if;
 select coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) into subjects from (
  select s.id,s.name,count(t.created_at) as answered,count(*) filter(where t.correct) as correct,count(*) filter(where t.correct=false) as incorrect,count(t.created_at) filter(where t.correct is null) as reflections
  from public.subjects s left join education_private.learning_attempt_stream_v4 t on t.subject_id=s.id
  where education_private.role()='admin' or education_private.assigned(s.id) group by s.id
 ) r;
 select coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) into days from (
  select to_char(t.created_at at time zone 'UTC','YYYY-MM-DD') as day,count(*) as answered,count(*) filter(where t.correct) as correct
  from education_private.learning_attempt_stream_v4 t where t.created_at>now()-interval '30 days' and (education_private.role()='admin' or education_private.assigned(t.subject_id)) group by 1 order by 1 desc
 ) r;
 select coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) into published from (
  select a.prompt,a.unit,a.active,a.created_at,a.updated_at from public.learning_activities a where education_private.role()='admin' or education_private.assigned(a.subject_id) order by a.updated_at desc limit 100
 ) r;
 return jsonb_build_object('subjects',subjects,'days',days,'published',published);
end $$;
revoke all on function public.admin_save_subject(uuid,jsonb),public.education_statistics_v4() from public,anon;
grant execute on function public.admin_save_subject(uuid,jsonb),public.education_statistics_v4() to authenticated;
revoke all on function public.learning_history_v4() from public,anon;
grant execute on function public.learning_history_v4() to authenticated;
notify pgrst,'reload schema';
commit;
