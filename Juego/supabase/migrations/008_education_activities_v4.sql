-- DuocGames 4.0. Additive: apply manually after 007. No accounts/roles changed.
begin;
create table public.learning_activities (
 id uuid primary key default gen_random_uuid(),
 subject_id uuid not null references public.subjects(id),
 unit text not null check(length(trim(unit)) between 1 and 200),
 kind text not null check(kind in ('multiple_choice','true_false','ordering','identify','physical_zone','sequence','matching','practical','reflection')),
 prompt text not null check(length(trim(prompt)) between 1 and 4000),
 content jsonb not null check(jsonb_typeof(content)='object'),
 image_path text, difficulty text not null check(difficulty in ('easy','medium','hard')),
 active boolean not null default false,
 access_challenge boolean not null default false,
 mentor_id text not null default '',
 retry_delay_seconds integer not null default 0 check(retry_delay_seconds between 0 and 300),
 max_attempts_per_day integer not null default 0 check(max_attempts_per_day between 0 and 100),
 created_by uuid not null default auth.uid() references public.profiles(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table education_private.activity_solutions (
 activity_id uuid primary key references public.learning_activities(id),
 answer jsonb not null, explanation text not null check(length(trim(explanation)) between 1 and 4000)
);
create table education_private.activity_tickets (
 user_id uuid primary key references public.profiles(id), activity_id uuid not null references public.learning_activities(id),
 context text not null, expires_at timestamptz not null, activity_updated_at timestamptz not null
);
create table public.learning_attempts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 activity_id uuid not null references public.learning_activities(id), correct boolean,
 context text not null, is_training boolean not null default false, created_at timestamptz not null default now()
);
create table public.learning_access (
 user_id uuid not null references public.profiles(id), floor integer not null,
 activity_id uuid references public.learning_activities(id),
 educational_xp integer not null default 25, created_at timestamptz not null default now(), primary key(user_id,floor)
);
create index learning_activities_subject_published on public.learning_activities(subject_id,active,access_challenge);
create index learning_attempts_user_activity_time on public.learning_attempts(user_id,activity_id,created_at desc);
-- Preserve legacy floor-3 passes using server-validated attempts, not client JSON.
insert into public.learning_access(user_id,floor,activity_id)
select distinct t.student_id,3,null from public.question_attempts t join public.questions q on q.id=t.question_id
where t.correct and t.context='floor_unlock' and q.floor=3
on conflict(user_id,floor) do nothing;
alter table public.learning_activities enable row level security;
alter table public.learning_attempts enable row level security;
alter table public.learning_access enable row level security;
alter table education_private.activity_solutions enable row level security;
alter table education_private.activity_tickets enable row level security;
revoke all on public.learning_activities,public.learning_attempts,public.learning_access from public,anon,authenticated;
revoke all on education_private.activity_solutions,education_private.activity_tickets from public,anon,authenticated;
grant select on public.learning_activities,public.learning_access to authenticated;
-- Student activity documents contain NO answer or explanation. Staff solutions use a guarded RPC.
create policy learning_activity_read on public.learning_activities for select to authenticated using (
 education_private.role()='admin' or
 (education_private.role()='teacher' and education_private.assigned(subject_id)) or
 (education_private.role()='student' and active and exists(select 1 from public.subjects s where s.id=subject_id and s.active))
);
create policy learning_access_own on public.learning_access for select to authenticated using(user_id=auth.uid());

create function public.save_learning_activity(p_id uuid,p_data jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); sid uuid; aid uuid; k text; c jsonb; a jsonb; n integer; mf integer; sf integer;
begin
 if uid is null or coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Staff required'; end if;
 sid:=(p_data->>'subject_id')::uuid;
 if not exists(select 1 from public.subjects where id=sid and active) then raise exception 'Unknown subject'; end if;
 select floor into sf from public.subjects where id=sid;
 if coalesce(p_data->>'mentor_id','')<>'' then
  mf:=('{"profesor_datos":3,"profesor_algoritmos":3,"profesor_redes":3,"docente_enfermeria":4,"docente_odontologia":4,"coordinador_profesores":4,"profesor_ingles":6,"profesor_etica":6,"profesor_lenguaje":7,"profesor_matematicas":7,"director":8}'::jsonb->> (p_data->>'mentor_id'))::integer;
  if mf is null or mf<>sf then raise exception 'Mentor and subject floor mismatch'; end if;
 end if;
 if education_private.role()<>'admin' and not education_private.assigned(sid) then raise exception 'Subject not assigned'; end if;
 if p_id is not null and not exists(select 1 from public.learning_activities where id=p_id and (education_private.role()='admin' or (created_by=uid and education_private.assigned(subject_id)))) then raise exception 'Activity not writable'; end if;
 k:=p_data->>'kind'; c:=p_data->'content'; a:=p_data->'answer';
 if coalesce((p_data->>'access_challenge')::boolean,false) and coalesce((p_data->>'max_attempts_per_day')::integer,0)<>0 then raise exception 'Access challenges require unlimited retries'; end if;
 if c is null or jsonb_typeof(c)<>'object' or a is null or octet_length(p_data::text)>50000 then raise exception 'Invalid content'; end if;
 if c ?| array['answer','correct','correct_option','solution','explanation'] then raise exception 'Private keys in public content'; end if;
 if k in ('multiple_choice','identify','physical_zone','true_false') then
  if jsonb_typeof(c->'options') is distinct from 'array' then raise exception 'Options required'; end if;
  n:=jsonb_array_length(c->'options');
  if exists(select 1 from jsonb_array_elements(c->'options') x where jsonb_typeof(x)<>'string' or length(trim(x#>>'{}')) not between 1 and 1000) then raise exception 'Options must be nonempty text'; end if;
  if (k='multiple_choice' and n<>4) or (k='true_false' and n<>2) or n<2 or n>8 then raise exception 'Invalid option count'; end if;
  if jsonb_typeof(a) is distinct from 'number' or a::text !~ '^[0-9]+$' or (a::text)::integer<0 or (a::text)::integer>=n then raise exception 'Invalid option key'; end if;
 elsif k in ('ordering','sequence','matching','practical') then
  if jsonb_typeof(c->'items') is distinct from 'array' or jsonb_typeof(a) is distinct from 'array' then raise exception 'Items and ordered answer required'; end if;
  n:=jsonb_array_length(c->'items');
  if exists(select 1 from jsonb_array_elements(c->'items') x where jsonb_typeof(x)<>'string' or length(trim(x#>>'{}')) not between 1 and 1000) then raise exception 'Items must be nonempty text'; end if;
  if n<2 or n>12 or jsonb_array_length(a)<>n then raise exception 'Invalid sequence length'; end if;
  if exists(select 1 from jsonb_array_elements(a) x where jsonb_typeof(x)<>'number' or x::text !~ '^[0-9]+$' or (x::text)::integer<0 or (x::text)::integer>=n) or (select count(distinct x) from jsonb_array_elements(a) x)<>n then raise exception 'Answer must be a permutation of item indices'; end if;
 elsif k='reflection' then
  if coalesce((p_data->>'access_challenge')::boolean,false) then raise exception 'Reflection cannot gate access'; end if;
 else raise exception 'Unsupported kind'; end if;
 if nullif(p_data->>'image_path','') is not null and not exists(select 1 from storage.objects where bucket_id='educational-images' and name=p_data->>'image_path') then raise exception 'Authorized image missing'; end if;
 if p_id is null then
  insert into public.learning_activities(subject_id,unit,kind,prompt,content,image_path,difficulty,active,access_challenge,created_by)
  values(sid,p_data->>'unit',k,p_data->>'prompt',c,nullif(p_data->>'image_path',''),p_data->>'difficulty',coalesce((p_data->>'active')::boolean,false),coalesce((p_data->>'access_challenge')::boolean,false),uid) returning id into aid;
 else
  update public.learning_activities set subject_id=sid,unit=p_data->>'unit',kind=k,prompt=p_data->>'prompt',content=c,image_path=nullif(p_data->>'image_path',''),difficulty=p_data->>'difficulty',active=coalesce((p_data->>'active')::boolean,false),access_challenge=coalesce((p_data->>'access_challenge')::boolean,false),updated_at=now() where id=p_id returning id into aid;
 end if;
 insert into education_private.activity_solutions values(aid,a,p_data->>'explanation') on conflict(activity_id) do update set answer=excluded.answer,explanation=excluded.explanation;
 update public.learning_activities set mentor_id=coalesce(p_data->>'mentor_id',''),retry_delay_seconds=coalesce((p_data->>'retry_delay_seconds')::integer,0),max_attempts_per_day=coalesce((p_data->>'max_attempts_per_day')::integer,0) where id=aid;
 return aid;
end $$;

create function public.get_learning_activity(p_floor integer,p_context text default 'training',p_mentor text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); a public.learning_activities;
begin
 if uid is null or coalesce(education_private.role(),'') not in ('student','teacher','admin') then raise exception 'Playable account required'; end if;
 if p_context not in ('floor_unlock','teacher_challenge','mission','training') or p_context is null then raise exception 'Invalid context'; end if;
 select x.* into a from public.learning_activities x join public.subjects s on s.id=x.subject_id
 where x.active and s.active and s.floor=p_floor and (p_context<>'floor_unlock' or x.access_challenge)
 and (p_mentor is null or x.mentor_id=p_mentor)
 and (education_private.role()<>'teacher' or education_private.assigned(x.subject_id))
 and not exists(select 1 from public.learning_attempts recent where recent.user_id=uid and recent.activity_id=x.id and recent.created_at>now()-x.retry_delay_seconds*interval '1 second')
 and (x.max_attempts_per_day=0 or (select count(*) from public.learning_attempts daily where daily.user_id=uid and daily.activity_id=x.id and daily.created_at>=(date_trunc('day',now() at time zone 'UTC') at time zone 'UTC'))<x.max_attempts_per_day)
 order by (select max(t.created_at) from public.learning_attempts t where t.user_id=uid and t.activity_id=x.id) asc nulls first,random() limit 1;
 if not found then return jsonb_build_object('error','No hay una actividad publicada disponible. Puede haber una espera entre intentos; prueba más tarde o consulta al docente.'); end if;
 insert into education_private.activity_tickets values(uid,a.id,p_context,now()+interval '20 minutes',a.updated_at)
 on conflict(user_id) do update set activity_id=excluded.activity_id,context=excluded.context,expires_at=excluded.expires_at,activity_updated_at=excluded.activity_updated_at;
 return to_jsonb(a)||jsonb_build_object('floor',p_floor);
end $$;

create function public.submit_learning_activity(p_id uuid,p_answer jsonb,p_context text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); ticket education_private.activity_tickets; a public.learning_activities; solution education_private.activity_solutions; hit boolean; f integer; gained integer:=0; n integer;
begin
 if uid is null or coalesce(education_private.role(),'') not in ('student','teacher','admin') then raise exception 'Playable account required'; end if;
 select * into ticket from education_private.activity_tickets where user_id=uid for update;
 if not found or ticket.activity_id is distinct from p_id or ticket.context is distinct from p_context or ticket.expires_at<now() then raise exception 'Expired or missing activity'; end if;
 select x.* into strict a from public.learning_activities x join public.subjects s on s.id=x.subject_id where x.id=p_id and x.active and s.active;
 if education_private.role()='teacher' and not education_private.assigned(a.subject_id) then raise exception 'Subject not assigned'; end if;
 if a.updated_at is distinct from ticket.activity_updated_at then raise exception 'Activity changed; request a fresh question'; end if;
 select * into strict solution from education_private.activity_solutions where activity_id=p_id;
 if p_answer is null or octet_length(p_answer::text)>8000 then raise exception 'Invalid answer'; end if;
 if a.kind in ('multiple_choice','true_false','identify','physical_zone') then
  n:=jsonb_array_length(a.content->'options');
  if jsonb_typeof(p_answer) is distinct from 'number' or p_answer::text !~ '^[0-9]+$' or (p_answer::text)::integer<0 or (p_answer::text)::integer>=n then raise exception 'Invalid selection'; end if;
 elsif a.kind='reflection' then
  if jsonb_typeof(p_answer) is distinct from 'string' or length(trim(p_answer#>>'{}')) not between 1 and 4000 then raise exception 'Reflection text required'; end if;
 else
  n:=jsonb_array_length(a.content->'items');
  if jsonb_typeof(p_answer) is distinct from 'array' then raise exception 'Sequence required'; end if;
  if jsonb_array_length(p_answer)<>n or (select count(distinct x) from jsonb_array_elements(p_answer) x)<>n or exists(select 1 from jsonb_array_elements(p_answer) x where jsonb_typeof(x)<>'number' or x::text !~ '^[0-9]+$' or (x::text)::integer<0 or (x::text)::integer>=n) then raise exception 'Invalid answer permutation'; end if;
 end if;
 hit:=case when a.kind='reflection' then null else solution.answer=p_answer end;
 delete from education_private.activity_tickets where user_id=uid;
 insert into public.learning_attempts(user_id,activity_id,correct,context,is_training) values(uid,p_id,hit,p_context,education_private.role()<>'student');
 select floor into f from public.subjects where id=a.subject_id;
 if hit and p_context='floor_unlock' and a.access_challenge and education_private.role()='student' then
  insert into public.learning_access(user_id,floor,activity_id) values(uid,f,p_id) on conflict do nothing;
  if found then gained:=25; end if;
 end if;
 return jsonb_build_object('correct',hit,'reflection',a.kind='reflection','explanation',solution.explanation,'floor',f,'educational_xp',gained,'verified',true,'practice',education_private.role()<>'student');
end $$;

create function public.learning_staff_bank() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Staff required'; end if;
 return coalesce((select jsonb_agg(to_jsonb(a)||jsonb_build_object('answer',k.answer,'explanation',k.explanation,'floor',s.floor)) from public.learning_activities a join education_private.activity_solutions k on k.activity_id=a.id join public.subjects s on s.id=a.subject_id where education_private.role()='admin' or education_private.assigned(a.subject_id)),'[]'::jsonb);
end $$;

create function public.learning_statistics() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Staff required'; end if;
 return coalesce((select jsonb_agg(to_jsonb(stats)) from (
 select a.id,a.subject_id,a.unit,a.prompt,count(t.id) as attempts,count(t.id) filter(where t.correct) as correct,count(t.id) filter(where t.correct=false) as incorrect,count(t.id) filter(where t.correct is null) as reflections
 from public.learning_activities a left join public.learning_attempts t on t.activity_id=a.id and not t.is_training
 where education_private.role()='admin' or education_private.assigned(a.subject_id) group by a.id
 ) stats),'[]'::jsonb);
end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('educational-images','educational-images',false,5242880,array['image/png','image/jpeg','image/webp']) on conflict(id) do nothing;
create policy educational_images_read on storage.objects for select to authenticated using(bucket_id='educational-images' and education_private.role() in ('student','teacher','admin'));
create policy educational_images_insert on storage.objects for insert to authenticated with check(bucket_id='educational-images' and education_private.role() in ('teacher','admin') and (storage.foldername(name))[1]=auth.uid()::text);
-- Immutable uploads. No overwrite/delete policy: published activity images remain available.
revoke all on function public.save_learning_activity(uuid,jsonb),public.get_learning_activity(integer,text,text),public.submit_learning_activity(uuid,jsonb,text),public.learning_staff_bank(),public.learning_statistics() from public,anon;
grant execute on function public.save_learning_activity(uuid,jsonb),public.get_learning_activity(integer,text,text),public.submit_learning_activity(uuid,jsonb,text),public.learning_staff_bank(),public.learning_statistics() to authenticated;
notify pgrst,'reload schema';
commit;
