-- Run this once in Supabase SQL Editor.

-- Marks Gab's account (and any future admins) as an admin
alter table profiles add column is_admin boolean not null default false;

-- One row per module: the YouTube (Unlisted) link + description the admin sets
create table course_content (
  module_number int primary key,
  youtube_url text default '',
  description text default '',
  updated_at timestamptz default now()
);

-- One row per attached file (PDF, notes, etc.) per module
create table course_files (
  id bigint generated always as identity primary key,
  module_number int not null,
  file_name text not null,
  file_path text not null,
  uploaded_at timestamptz default now()
);

alter table course_content enable row level security;
alter table course_files enable row level security;

-- Any logged-in student can read course content and file lists
create policy "read course content" on course_content
  for select using (auth.role() = 'authenticated');

create policy "read course files" on course_files
  for select using (auth.role() = 'authenticated');

-- Only admins (is_admin = true) can add/edit/delete course content and files
create policy "admin write course content" on course_content
  for all using (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  ) with check (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

create policy "admin write course files" on course_files
  for all using (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  ) with check (
    exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

-- Empty starting rows for the 10 modules, so the admin page has something to edit
insert into course_content (module_number, youtube_url, description) values
  (1,'',''), (2,'',''), (3,'',''), (4,'',''), (5,'',''),
  (6,'',''), (7,'',''), (8,'',''), (9,'',''), (10,'','');

-- ── Storage policies ──
-- Before running the lines below: go to Storage in the Supabase sidebar,
-- click "New bucket", name it exactly  course-files , and leave it PRIVATE
-- (do not toggle "Public bucket"). Then run this:

create policy "authenticated read course files"
on storage.objects for select
using ( bucket_id = 'course-files' and auth.role() = 'authenticated' );

create policy "admin upload course files"
on storage.objects for insert
with check (
  bucket_id = 'course-files'
  and exists (select 1 from profiles where id = auth.uid() and is_admin = true)
);

create policy "admin delete course files"
on storage.objects for delete
using (
  bucket_id = 'course-files'
  and exists (select 1 from profiles where id = auth.uid() and is_admin = true)
);
