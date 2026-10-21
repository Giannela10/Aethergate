-- Only needed if 001 was already applied before display_name metadata support.
-- Apply through SQL Editor or an existing trusted administrative connection.
begin;
create or replace function education_private.new_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,email,display_name,avatar_url,role)
 values(new.id,coalesce(new.email,''),
 coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'),''),nullif(trim(new.raw_user_meta_data->>'full_name'),''),'Estudiante'),
 coalesce(new.raw_user_meta_data->>'avatar_url',''),'student');
 return new;
end $$;
revoke all on function education_private.new_profile() from public,anon,authenticated;
commit;
