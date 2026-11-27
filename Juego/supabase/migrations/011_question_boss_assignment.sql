-- Asigna preguntas de alternativa a un boss concreto y las sirve durante
-- la opción "Preguntas asignadas" de la actividad de ese mentor.
begin;

alter table public.questions
 add column if not exists assigned_boss_id text not null default '';
alter table public.questions drop constraint if exists questions_assigned_boss_id_check;
alter table public.questions add constraint questions_assigned_boss_id_check check (assigned_boss_id in (
 '', 'profesor_datos','profesor_algoritmos','profesor_redes','docente_enfermeria',
 'docente_odontologia','coordinador_profesores','profesor_ingles','profesor_etica',
 'profesor_lenguaje','profesor_matematicas','director'
));
create index if not exists questions_assigned_boss on public.questions(assigned_boss_id,active);

create or replace function public.save_question(p_id uuid,p_data jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare qid uuid; sf integer; assigned_id uuid; boss_id text;
begin
 if auth.uid() is null or coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Not authorized'; end if;
 if p_data->>'correct_option' not in ('A','B','C','D') or p_data->>'correct_option' is null then raise exception 'Invalid answer'; end if;
 select floor into strict sf from public.subjects where id=(p_data->>'subject_id')::uuid and active;
 if education_private.role()='teacher' then
  if not education_private.assigned((p_data->>'subject_id')::uuid) and
   (p_id is null or not exists(select 1 from public.questions where id=p_id and assigned_teacher_id=auth.uid())) then raise exception 'Subject not assigned'; end if;
  assigned_id=auth.uid();
  select coalesce(assigned_boss_id,'') into boss_id from public.questions where id=p_id and assigned_teacher_id=auth.uid();
  boss_id=coalesce(p_data->>'assigned_boss_id',boss_id,'');
 else
  assigned_id=nullif(p_data->>'assigned_teacher_id','')::uuid;
  if assigned_id is not null and not exists(select 1 from public.profiles where id=assigned_id and role='teacher') then raise exception 'Target must be teacher'; end if;
  boss_id=coalesce(p_data->>'assigned_boss_id','');
 end if;
 if boss_id not in ('','profesor_datos','profesor_algoritmos','profesor_redes','docente_enfermeria','docente_odontologia','coordinador_profesores','profesor_ingles','profesor_etica','profesor_lenguaje','profesor_matematicas','director') then raise exception 'Invalid boss'; end if;
 if p_id is null then
  insert into public.questions(subject_id,floor,question_text,option_a,option_b,option_c,option_d,difficulty,active,created_by,assigned_teacher_id,assigned_boss_id)
  values((p_data->>'subject_id')::uuid,sf,p_data->>'question_text',p_data->>'option_a',p_data->>'option_b',p_data->>'option_c',p_data->>'option_d',p_data->>'difficulty',coalesce((p_data->>'active')::boolean,true),auth.uid(),assigned_id,boss_id) returning id into qid;
 else
  update public.questions set subject_id=(p_data->>'subject_id')::uuid,floor=sf,question_text=p_data->>'question_text',option_a=p_data->>'option_a',option_b=p_data->>'option_b',option_c=p_data->>'option_c',option_d=p_data->>'option_d',difficulty=p_data->>'difficulty',active=coalesce((p_data->>'active')::boolean,true),assigned_teacher_id=assigned_id,assigned_boss_id=boss_id where id=p_id returning id into qid;
  if qid is null then raise exception 'Question not writable'; end if;
 end if;
 insert into public.question_keys(question_id,correct_option,explanation) values(qid,p_data->>'correct_option',coalesce(p_data->>'explanation',''))
 on conflict(question_id) do update set correct_option=excluded.correct_option, explanation=excluded.explanation;
 return qid;
end $$;

create or replace function public.get_random_question(p_subject text,p_context text,p_exclude uuid default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare q public.questions; uid uuid:=auth.uid();
begin
 if uid is null or education_private.role() is distinct from 'student' then raise exception 'Student authentication required'; end if;
 if p_context not in ('floor_unlock','teacher_challenge','computer','mission','training') or p_context is null then raise exception 'Invalid context'; end if;
 if p_context='floor_unlock' and p_subject<>'INF_GENERAL' then raise exception 'Unsupported floor pilot'; end if;
 select x.* into q from public.questions x join public.subjects s on s.id=x.subject_id
 where s.code=p_subject and s.active and x.active and x.assigned_boss_id='' and exists(select 1 from public.question_keys k where k.question_id=x.id)
 order by (x.id is distinct from p_exclude) desc,random() limit 1;
 if not found then raise exception 'No active questions'; end if;
 insert into education_private.question_tickets(student_id,question_id,context) values(uid,q.id,p_context)
 on conflict(student_id) do update set question_id=excluded.question_id,context=excluded.context,expires_at=now()+interval '15 minutes';
 return to_jsonb(q);
end $$;

create or replace function public.get_boss_question(p_boss_id text,p_exclude uuid default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare q public.questions; uid uuid:=auth.uid();
begin
 if uid is null or education_private.role() is distinct from 'student' then raise exception 'Student authentication required'; end if;
 if p_boss_id not in ('profesor_datos','profesor_algoritmos','profesor_redes','docente_enfermeria','docente_odontologia','coordinador_profesores','profesor_ingles','profesor_etica','profesor_lenguaje','profesor_matematicas','director') then raise exception 'Invalid boss'; end if;
 select x.* into q from public.questions x join public.subjects s on s.id=x.subject_id
 where x.assigned_boss_id=p_boss_id and x.active and s.active and exists(select 1 from public.question_keys k where k.question_id=x.id)
 order by (x.id is distinct from p_exclude) desc,random() limit 1;
 if not found then raise exception 'No active questions for this boss'; end if;
 insert into education_private.question_tickets(student_id,question_id,context) values(uid,q.id,'teacher_challenge')
 on conflict(student_id) do update set question_id=excluded.question_id,context=excluded.context,expires_at=now()+interval '15 minutes';
 return to_jsonb(q);
end $$;

revoke all on function public.save_question(uuid,jsonb),public.get_boss_question(text,uuid) from public,anon;
grant execute on function public.save_question(uuid,jsonb),public.get_boss_question(text,uuid) to authenticated;
commit;
