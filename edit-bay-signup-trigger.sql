-- Run this once in Supabase SQL Editor. This makes sure the name and fire
-- station typed during sign-up gets saved automatically, even before the
-- student clicks the email confirmation link.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, fire_station)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'fire_station'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
