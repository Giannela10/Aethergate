-- Execute manually in Supabase SQL Editor. Never run using the game's API key.
-- Existing profiles and their roles remain untouched.
begin;
create or replace function education_private.new_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,email,display_name,avatar_url,role)
 values(new.id,coalesce(new.email,''),
 coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'),''),nullif(trim(new.raw_user_meta_data->>'full_name'),''),'Estudiante'),
 coalesce(new.raw_user_meta_data->>'avatar_url',''),'student')
 on conflict(id) do nothing;
 return new;
end $$;
revoke all on function education_private.new_profile() from public,anon,authenticated;
drop trigger if exists education_profile on auth.users;
create trigger education_profile after insert on auth.users
for each row execute function education_private.new_profile();
insert into public.profiles(id,email,display_name,avatar_url,role)
select id,coalesce(email,''),
 coalesce(nullif(trim(raw_user_meta_data->>'display_name'),''),nullif(trim(raw_user_meta_data->>'full_name'),''),'Estudiante'),
 coalesce(raw_user_meta_data->>'avatar_url',''),'student'
from auth.users on conflict(id) do nothing;
commit;
