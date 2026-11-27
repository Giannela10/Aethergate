-- Asignación explícita de preguntas a un profesor. El alumnado las sigue
-- recibiendo por asignatura mediante get_random_question.
begin;

alter table public.questions
 add column if not exists assigned_teacher_id uuid references public.profiles(id) on delete set null;
create index if not exists questions_assigned_teacher on public.questions(assigned_teacher_id,active);
update public.questions q set assigned_teacher_id=q.created_by
 where q.assigned_teacher_id is null and exists(select 1 from public.profiles p where p.id=q.created_by and p.role='teacher');
update public.questions q set assigned_teacher_id=owners.teacher_id
from (select ts.subject_id,min(ts.teacher_id::text)::uuid as teacher_id from public.teacher_subjects ts group by ts.subject_id having count(*)=1) owners
where q.assigned_teacher_id is null and q.subject_id=owners.subject_id;

create or replace function education_private.can_manage(q uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.questions where id=q and
  (education_private.role()='admin' or
   (education_private.role()='teacher' and (assigned_teacher_id=auth.uid() or
    (created_by=auth.uid() and education_private.assigned(subject_id))))))
$$;

drop policy if exists questions_read on public.questions;
create policy questions_read on public.questions for select to authenticated using(
 education_private.role()='admin' or
 (education_private.role()='teacher' and (assigned_teacher_id=auth.uid() or education_private.assigned(subject_id))) or
 (education_private.role()='student' and active and exists(select 1 from public.subjects s where s.id=subject_id and s.active)));

drop policy if exists questions_update on public.questions;
create policy questions_update on public.questions for update to authenticated using(education_private.can_manage(id)) with check(
 education_private.role()='admin' or (education_private.role()='teacher' and assigned_teacher_id=auth.uid()));

create or replace function public.save_question(p_id uuid,p_data jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare qid uuid; sf integer; assigned_id uuid;
begin
 if auth.uid() is null or coalesce(education_private.role(),'') not in ('teacher','admin') then raise exception 'Not authorized'; end if;
 if p_data->>'correct_option' not in ('A','B','C','D') or p_data->>'correct_option' is null then raise exception 'Invalid answer'; end if;
 select floor into strict sf from public.subjects where id=(p_data->>'subject_id')::uuid and active;
 if education_private.role()='teacher' then
  if not education_private.assigned((p_data->>'subject_id')::uuid) and
   (p_id is null or not exists(select 1 from public.questions where id=p_id and assigned_teacher_id=auth.uid())) then raise exception 'Subject not assigned'; end if;
  assigned_id=auth.uid();
 else
  assigned_id=nullif(p_data->>'assigned_teacher_id','')::uuid;
  if assigned_id is not null and not exists(select 1 from public.profiles where id=assigned_id and role='teacher') then raise exception 'Target must be teacher'; end if;
 end if;
 if p_id is null then
  insert into public.questions(subject_id,floor,question_text,option_a,option_b,option_c,option_d,difficulty,active,created_by,assigned_teacher_id)
  values((p_data->>'subject_id')::uuid,sf,p_data->>'question_text',p_data->>'option_a',p_data->>'option_b',p_data->>'option_c',p_data->>'option_d',p_data->>'difficulty',coalesce((p_data->>'active')::boolean,true),auth.uid(),assigned_id) returning id into qid;
 else
  update public.questions set subject_id=(p_data->>'subject_id')::uuid,floor=sf,question_text=p_data->>'question_text',option_a=p_data->>'option_a',option_b=p_data->>'option_b',option_c=p_data->>'option_c',option_d=p_data->>'option_d',difficulty=p_data->>'difficulty',active=coalesce((p_data->>'active')::boolean,true),assigned_teacher_id=assigned_id where id=p_id returning id into qid;
  if qid is null then raise exception 'Question not writable'; end if;
 end if;
 insert into public.question_keys(question_id,correct_option,explanation) values(qid,p_data->>'correct_option',coalesce(p_data->>'explanation',''))
 on conflict(question_id) do update set correct_option=excluded.correct_option, explanation=excluded.explanation;
 return qid;
end $$;

revoke all on function public.save_question(uuid,jsonb) from public,anon;
grant execute on function public.save_question(uuid,jsonb) to authenticated;
commit;
