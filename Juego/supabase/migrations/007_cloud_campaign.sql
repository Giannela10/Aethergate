-- Execute the entire file in Supabase SQL Editor as postgres, after 001–006.
-- Reuses existing Auth users and preserves all existing profiles and roles.
begin;

insert into public.profiles (id,email,display_name,role)
select u.id,coalesce(u.email,''),
 coalesce(nullif(u.raw_user_meta_data->>'display_name',''),nullif(u.raw_user_meta_data->>'full_name',''),'Usuario'),
 'pending'
from auth.users u
where not exists (select 1 from public.profiles p where p.id=u.id)
on conflict (id) do nothing;

create table if not exists public.campaign_saves (
 user_id uuid primary key references auth.users(id) on delete cascade,
 payload jsonb not null check (jsonb_typeof(payload)='object'),
 previous_payload jsonb,
 revision bigint not null check (revision > 0),
 request_id text not null,
 updated_at timestamptz not null default now()
);
alter table public.campaign_saves enable row level security;
revoke all on public.campaign_saves from public,anon,authenticated;
grant select on public.campaign_saves to authenticated;
drop policy if exists campaign_read_own on public.campaign_saves;
create policy campaign_read_own on public.campaign_saves for select to authenticated
 using ((select auth.uid())=user_id);

create or replace function public.load_campaign() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_row public.campaign_saves;
begin
 if v_uid is null or not exists (select 1 from public.profiles p where p.id=v_uid and p.role in ('student','teacher','admin')) then
  raise exception using errcode='42501',message='Playable account required';
 end if;
 select * into v_row from public.campaign_saves where user_id=v_uid;
 if not found then return jsonb_build_object('payload','{}'::jsonb,'revision',0); end if;
 return jsonb_build_object('payload',v_row.payload,'revision',v_row.revision);
end $$;

create or replace function public.save_campaign(p_payload jsonb,p_revision bigint,p_request_id text,p_backup boolean default false) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_row public.campaign_saves; v_current bigint := 0;
begin
 if v_uid is null or not exists (select 1 from public.profiles p where p.id=v_uid and p.role in ('student','teacher','admin')) then
  raise exception using errcode='42501',message='Playable account required';
 end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object'
    or not (p_payload ? 'version' and p_payload ? 'save_version')
    or coalesce(p_payload->>'version','') not in ('1','2') or coalesce(p_payload->>'save_version','') not in ('1','2')
    or octet_length(p_payload::text)>1500000
    or p_revision is null or p_revision<0
    or p_request_id is null or p_request_id !~ '^[a-f0-9]{32}$' then
  raise exception using errcode='22023',message='Invalid campaign payload';
 end if;
 -- Serialize first insert and updates for this account, including two devices.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_uid::text,7007));
 select * into v_row from public.campaign_saves where user_id=v_uid for update;
 if found then
  v_current := v_row.revision;
  -- A request whose response was lost can be retried without writing twice.
  if v_row.request_id=p_request_id and v_row.revision=p_revision+1 and v_row.payload=p_payload then
   return jsonb_build_object('revision',v_row.revision,'request_id',v_row.request_id);
  end if;
 end if;
 if v_current<>p_revision then return jsonb_build_object('conflict',true); end if;
 insert into public.campaign_saves(user_id,payload,revision,request_id)
 values(v_uid,p_payload,1,p_request_id)
 on conflict(user_id) do update set previous_payload=case when p_backup then campaign_saves.payload else campaign_saves.previous_payload end,
  payload=excluded.payload,revision=campaign_saves.revision+1,
  request_id=excluded.request_id,updated_at=now()
 returning * into v_row;
 return jsonb_build_object('revision',v_row.revision,'request_id',v_row.request_id);
end $$;

revoke all on function public.load_campaign() from public,anon,authenticated;
revoke all on function public.save_campaign(jsonb,bigint,text,boolean) from public,anon,authenticated;
grant execute on function public.load_campaign(),public.save_campaign(jsonb,bigint,text,boolean) to authenticated;
notify pgrst,'reload schema';
commit;
