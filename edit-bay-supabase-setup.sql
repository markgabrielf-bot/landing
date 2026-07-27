-- Run this once in Supabase: SQL Editor > New Query > paste all > Run

-- Table: one profile row per student, storing name + fire station
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  fire_station text not null,
  created_at timestamptz default now()
);

-- Table: one row per completed module per student
create table progress (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users on delete cascade not null,
  module_number int not null,
  completed_at timestamptz default now(),
  unique (user_id, module_number)
);

-- Lock both tables down so students can only see/edit their OWN data
alter table profiles enable row level security;
alter table progress enable row level security;

create policy "read own profile" on profiles
  for select using (auth.uid() = id);

create policy "insert own profile" on profiles
  for insert with check (auth.uid() = id);

create policy "read own progress" on progress
  for select using (auth.uid() = user_id);

create policy "insert own progress" on progress
  for insert with check (auth.uid() = user_id);

create policy "delete own progress" on progress
  for delete using (auth.uid() = user_id);
