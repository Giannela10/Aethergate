-- MANUAL bootstrap only. Email explicitly supplied by the project owner.
-- Runtime/Auth/profile checks already confirmed this account is admin.
-- No need to execute this again for the current incident.
-- Never identify the account by display_name. Do not execute from the game.
-- Check that exactly one intended profile is returned before running the UPDATE.
SELECT id,email,display_name,role FROM public.profiles WHERE email = 'nicolashernandezdelarosa@gmail.com';

UPDATE public.profiles
SET role = 'admin',
    updated_at = now()
WHERE email = 'nicolashernandezdelarosa@gmail.com';

SELECT
    id,
    email,
    display_name,
    role
FROM public.profiles
WHERE email = 'nicolashernandezdelarosa@gmail.com';
