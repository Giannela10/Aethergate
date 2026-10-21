-- DuocGames Educativo 1.0. Apply once through Supabase migrations/SQL editor.
-- No secrets. Auth identities and roles are never supplied by the game.
begin;
create schema if not exists education_private;
revoke all on schema education_private from public, anon, authenticated;
grant usage on schema education_private to authenticated;

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 email text not null default '', display_name text not null default '', avatar_url text not null default '',
 role text not null default 'student' check (role in ('student','teacher','admin')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.subjects (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 name text not null check (length(trim(name)) between 1 and 200),
 floor integer not null check (floor in (-1,1,2,3,4,5,6,7,8)), area text not null,
 active boolean not null default true, created_at timestamptz not null default now()
);
create table public.teacher_subjects (
 teacher_id uuid not null references public.profiles(id) on delete cascade,
 subject_id uuid not null references public.subjects(id) on delete cascade,
 primary key (teacher_id,subject_id)
);
create table public.questions (
 id uuid primary key default gen_random_uuid(), subject_id uuid not null references public.subjects(id),
 floor integer not null, question_text text not null check (length(trim(question_text)) between 1 and 4000),
 option_a text not null check (length(trim(option_a)) between 1 and 1000),
 option_b text not null check (length(trim(option_b)) between 1 and 1000),
 option_c text not null check (length(trim(option_c)) between 1 and 1000),
 option_d text not null check (length(trim(option_d)) between 1 and 1000),
 difficulty text not null check (difficulty in ('easy','medium','hard')),
 active boolean not null default true, created_by uuid not null default auth.uid() references public.profiles(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.question_keys (
 question_id uuid primary key references public.questions(id) on delete cascade,
 correct_option text not null check (correct_option in ('A','B','C','D')),
 explanation text not null default '' check (length(explanation) <= 4000)
);
create table public.question_attempts (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id),
 question_id uuid not null references public.questions(id), selected_option text not null check (selected_option in ('A','B','C','D')),
 correct boolean not null, context text not null check (context in ('floor_unlock','teacher_challenge','computer','mission','training')),
 created_at timestamptz not null default now()
);
create table public.academic_progress (
 student_id uuid not null references public.profiles(id), subject_id uuid not null references public.subjects(id),
 answered integer not null default 0, correct integer not null default 0, incorrect integer not null default 0,
 updated_at timestamptz not null default now(), primary key(student_id,subject_id)
);
-- Issuance records prevent submitting unseen questions and duplicate attempts.
create table education_private.question_tickets (
 student_id uuid primary key references public.profiles(id), question_id uuid not null references public.questions(id),
 context text not null, expires_at timestamptz not null default (now() + interval '15 minutes')
);
revoke all on education_private.question_tickets from public,anon,authenticated;
create index questions_subject_active on public.questions(subject_id,active);
create index questions_creator on public.questions(created_by);
create index teacher_subjects_subject on public.teacher_subjects(subject_id);
create index attempts_student_time on public.question_attempts(student_id,created_at desc);
create index attempts_question on public.question_attempts(question_id);

create function education_private.role() returns text language sql stable security definer
set search_path = '' as $$ select role from public.profiles where id = auth.uid() $$;
create function education_private.assigned(s uuid) returns boolean language sql stable security definer
set search_path = '' as $$ select exists(select 1 from public.teacher_subjects where teacher_id=auth.uid() and subject_id=s) $$;
create function education_private.can_manage(q uuid) returns boolean language sql stable security definer
set search_path = '' as $$ select exists(select 1 from public.questions where id=q and
 (education_private.role()='admin' or (education_private.role()='teacher' and created_by=auth.uid() and education_private.assigned(subject_id)))) $$;
revoke all on function education_private.role(), education_private.assigned(uuid), education_private.can_manage(uuid) from public;
grant execute on function education_private.role(), education_private.assigned(uuid), education_private.can_manage(uuid) to authenticated;

create function education_private.new_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,email,display_name,avatar_url,role)
 values(new.id,coalesce(new.email,''),coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'),''),nullif(trim(new.raw_user_meta_data->>'full_name'),''),'Estudiante'),coalesce(new.raw_user_meta_data->>'avatar_url',''),'student');
 return new;
end $$;
create trigger education_profile after insert on auth.users for each row execute function education_private.new_profile();
-- Backfill identities that existed before this migration; do not use metadata roles.
insert into public.profiles(id,email,display_name,avatar_url)
select id,coalesce(email,''),coalesce(nullif(trim(raw_user_meta_data->>'display_name'),''),nullif(trim(raw_user_meta_data->>'full_name'),''),'Estudiante'),coalesce(raw_user_meta_data->>'avatar_url','') from auth.users on conflict(id) do nothing;

create function education_private.question_guard() returns trigger language plpgsql set search_path = '' as $$
begin
 if TG_OP='UPDATE' and (new.created_by<>old.created_by or new.id<>old.id or new.created_at<>old.created_at) then raise exception 'Immutable question identity'; end if;
 select floor into new.floor from public.subjects where id=new.subject_id and active;
 if not found then raise exception 'Inactive or unknown subject'; end if;
 new.updated_at=now();
 return new;
end $$;
create trigger question_guard before insert or update on public.questions for each row execute function education_private.question_guard();

alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.teacher_subjects enable row level security;
alter table public.questions enable row level security;
alter table public.question_keys enable row level security;
alter table public.question_attempts enable row level security;
alter table public.academic_progress enable row level security;
alter table education_private.question_tickets enable row level security;

-- Explicit grants, independent of project default privileges.
revoke all on public.profiles,public.subjects,public.teacher_subjects,public.questions,public.question_keys,public.question_attempts,public.academic_progress from anon,authenticated;
grant select on public.profiles,public.subjects,public.teacher_subjects,public.questions,public.question_keys,public.question_attempts,public.academic_progress to authenticated;
grant insert,update on public.questions,public.question_keys to authenticated;
grant insert,update,delete on public.subjects,public.teacher_subjects to authenticated;
create policy profiles_read on public.profiles for select to authenticated using(id=auth.uid() or education_private.role()='admin');
-- NO profile write grants or policies: even admin UI cannot change roles.
create policy subjects_read on public.subjects for select to authenticated using(
 education_private.role()='admin' or (education_private.role()='student' and active) or (education_private.role()='teacher' and education_private.assigned(id)));
create policy subjects_admin on public.subjects for all to authenticated using(education_private.role()='admin') with check(education_private.role()='admin');
create policy assignments_read on public.teacher_subjects for select to authenticated using(teacher_id=auth.uid() or education_private.role()='admin');
create policy assignments_admin on public.teacher_subjects for all to authenticated using(education_private.role()='admin') with check(education_private.role()='admin');
create policy questions_read on public.questions for select to authenticated using(
 education_private.role()='admin' or
 (education_private.role()='teacher' and education_private.assigned(subject_id)) or
 (education_private.role()='student' and active and exists(select 1 from public.subjects s where s.id=subject_id and s.active)));
create policy questions_insert on public.questions for insert to authenticated with check(
 created_by=auth.uid() and (education_private.role()='admin' or (education_private.role()='teacher' and education_private.assigned(subject_id))));
create policy questions_update on public.questions for update to authenticated using(education_private.can_manage(id)) with check(
 education_private.role()='admin' or (education_private.role()='teacher' and created_by=auth.uid() and education_private.assigned(subject_id)));
create policy keys_read on public.question_keys for select to authenticated using(education_private.can_manage(question_id));
create policy keys_insert on public.question_keys for insert to authenticated with check(education_private.can_manage(question_id));
create policy keys_update on public.question_keys for update to authenticated using(education_private.can_manage(question_id)) with check(education_private.can_manage(question_id));
create policy attempts_read on public.question_attempts for select to authenticated using(student_id=auth.uid() or education_private.role()='admin' or
 (education_private.role()='teacher' and exists(select 1 from public.questions q where q.id=question_id and education_private.assigned(q.subject_id))));
create policy progress_read on public.academic_progress for select to authenticated using(student_id=auth.uid() or education_private.role()='admin' or (education_private.role()='teacher' and education_private.assigned(subject_id)));

-- SECURITY INVOKER preserves RLS; question and private key commit atomically.
create function public.save_question(p_id uuid,p_data jsonb) returns uuid language plpgsql security invoker set search_path = '' as $$
declare qid uuid; sf integer;
begin
 if auth.uid() is null or coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Not authorized'; end if;
 if p_data->>'correct_option' not in ('A','B','C','D') or p_data->>'correct_option' is null then raise exception 'Invalid answer'; end if;
 select floor into strict sf from public.subjects where id=(p_data->>'subject_id')::uuid and active;
 if p_id is null then
  insert into public.questions(subject_id,floor,question_text,option_a,option_b,option_c,option_d,difficulty,active,created_by)
  values((p_data->>'subject_id')::uuid,sf,p_data->>'question_text',p_data->>'option_a',p_data->>'option_b',p_data->>'option_c',p_data->>'option_d',p_data->>'difficulty',coalesce((p_data->>'active')::boolean,true),auth.uid()) returning id into qid;
 else
  update public.questions set subject_id=(p_data->>'subject_id')::uuid,floor=sf,question_text=p_data->>'question_text',option_a=p_data->>'option_a',option_b=p_data->>'option_b',option_c=p_data->>'option_c',option_d=p_data->>'option_d',difficulty=p_data->>'difficulty',active=coalesce((p_data->>'active')::boolean,true) where id=p_id returning id into qid;
  if qid is null then raise exception 'Question not writable'; end if;
 end if;
 insert into public.question_keys(question_id,correct_option,explanation) values(qid,p_data->>'correct_option',coalesce(p_data->>'explanation',''))
 on conflict(question_id) do update set correct_option=excluded.correct_option, explanation=excluded.explanation;
 return qid;
end $$;

create function public.get_random_question(p_subject text,p_context text,p_exclude uuid default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare q public.questions; uid uuid:=auth.uid();
begin
 if uid is null or education_private.role() is distinct from 'student' then raise exception 'Student authentication required'; end if;
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

create function public.submit_answer(p_question_id uuid,p_selected_option text,p_context text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare uid uuid:=auth.uid(); key public.question_keys; q public.questions; hit boolean; ticket education_private.question_tickets;
begin
 if uid is null or education_private.role() is distinct from 'student' then raise exception 'Student authentication required'; end if;
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
revoke all on function public.save_question(uuid,jsonb), public.get_random_question(text,text,uuid), public.submit_answer(uuid,text,text) from public,anon;
grant execute on function public.save_question(uuid,jsonb), public.get_random_question(text,text,uuid), public.submit_answer(uuid,text,text) to authenticated;
revoke all on function education_private.new_profile(),education_private.question_guard() from public,anon,authenticated;
commit;
