create extension if not exists "uuid-ossp";

create table if not exists public.projects (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  event_type text not null default 'PHOTOSHOOT',
  created_at timestamptz not null default now()
);
create table if not exists public.script_blocks (
  id uuid primary key default uuid_generate_v4(), project_id uuid references public.projects(id) on delete cascade not null,
  type text not null check (type in ('action','dialog','expression','shot')), content text not null default '', meta text,
  position integer not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.moodboard_items (
  id uuid primary key default uuid_generate_v4(), project_id uuid references public.projects(id) on delete cascade not null,
  category text not null check (category in ('environment','talent','pov','light')), storage_path text not null, image_paths jsonb not null default '[]'::jsonb, description text not null default '', created_at timestamptz not null default now(),
  unique(project_id,category)
);
alter table public.moodboard_items add column if not exists description text not null default '';
alter table public.moodboard_items add column if not exists image_paths jsonb not null default '[]'::jsonb;
update public.moodboard_items
set image_paths=jsonb_build_array(storage_path)
where (image_paths is null or jsonb_array_length(image_paths)=0) and storage_path is not null;

create table if not exists public.walkthrough_videos (
  id uuid primary key default uuid_generate_v4(), project_id uuid references public.projects(id) on delete cascade not null,
  storage_path text not null, created_at timestamptz not null default now()
);

alter table public.projects enable row level security;
alter table public.script_blocks enable row level security;
alter table public.moodboard_items enable row level security;
alter table public.walkthrough_videos enable row level security;

drop policy if exists "users manage own projects" on public.projects;
create policy "users manage own projects" on public.projects for all to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
drop policy if exists "users manage own script blocks" on public.script_blocks;
create policy "users manage own script blocks" on public.script_blocks for all to authenticated using (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid())) with check (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid()));
drop policy if exists "users manage own moodboards" on public.moodboard_items;
create policy "users manage own moodboards" on public.moodboard_items for all to authenticated using (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid())) with check (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid()));
drop policy if exists "users manage own walkthroughs" on public.walkthrough_videos;
create policy "users manage own walkthroughs" on public.walkthrough_videos for all to authenticated using (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid())) with check (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid()));

insert into storage.buckets (id,name,public) values ('edtv-assets','edtv-assets',false) on conflict (id) do nothing;
drop policy if exists "authenticated users can upload edtv assets" on storage.objects;
create policy "authenticated users can upload edtv assets" on storage.objects for insert to authenticated with check (bucket_id='edtv-assets' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "authenticated users can read own edtv assets" on storage.objects;
create policy "authenticated users can read own edtv assets" on storage.objects for select to authenticated using (bucket_id='edtv-assets' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "authenticated users can update own edtv assets" on storage.objects;
create policy "authenticated users can update own edtv assets" on storage.objects for update to authenticated using (bucket_id='edtv-assets' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "authenticated users can delete own edtv assets" on storage.objects;
create policy "authenticated users can delete own edtv assets" on storage.objects for delete to authenticated using (bucket_id='edtv-assets' and (storage.foldername(name))[1]=auth.uid()::text);

-- Scene-based moodboard + walkthrough migration
create table if not exists public.moodboard_scenes (
  id uuid primary key default uuid_generate_v4(),
  project_id uuid references public.projects(id) on delete cascade not null,
  name text not null default 'Scene 1',
  description text not null default '',
  position integer not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.moodboard_scene_items (
  id uuid primary key default uuid_generate_v4(),
  scene_id uuid references public.moodboard_scenes(id) on delete cascade not null,
  category text not null check (category in ('environment','talent','pov','light')),
  storage_path text not null,
  image_paths jsonb not null default '[]'::jsonb,
  description text not null default '',
  created_at timestamptz not null default now(),
  unique(scene_id,category)
);
create table if not exists public.moodboard_scene_videos (
  id uuid primary key default uuid_generate_v4(),
  scene_id uuid references public.moodboard_scenes(id) on delete cascade not null,
  storage_path text not null,
  created_at timestamptz not null default now()
);
alter table public.moodboard_scenes enable row level security;
alter table public.moodboard_scene_items enable row level security;
alter table public.moodboard_scene_videos enable row level security;
drop policy if exists "users manage own moodboard scenes" on public.moodboard_scenes;
create policy "users manage own moodboard scenes" on public.moodboard_scenes for all to authenticated using (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid())) with check (exists(select 1 from public.projects p where p.id=project_id and p.user_id=auth.uid()));
drop policy if exists "users manage own scene moodboard items" on public.moodboard_scene_items;
create policy "users manage own scene moodboard items" on public.moodboard_scene_items for all to authenticated using (exists(select 1 from public.moodboard_scenes s join public.projects p on p.id=s.project_id where s.id=scene_id and p.user_id=auth.uid())) with check (exists(select 1 from public.moodboard_scenes s join public.projects p on p.id=s.project_id where s.id=scene_id and p.user_id=auth.uid()));
drop policy if exists "users manage own scene walkthroughs" on public.moodboard_scene_videos;
create policy "users manage own scene walkthroughs" on public.moodboard_scene_videos for all to authenticated using (exists(select 1 from public.moodboard_scenes s join public.projects p on p.id=s.project_id where s.id=scene_id and p.user_id=auth.uid())) with check (exists(select 1 from public.moodboard_scenes s join public.projects p on p.id=s.project_id where s.id=scene_id and p.user_id=auth.uid()));

-- Migrate legacy moodboard content into Scene 1 for projects that do not have scenes yet.
insert into public.moodboard_scenes(project_id,name,description,position)
select p.id,'Scene 1','Scene utama',0
from public.projects p
where not exists(select 1 from public.moodboard_scenes s where s.project_id=p.id)
  and exists(select 1 from public.moodboard_items m where m.project_id=p.id)
  and not exists(select 1 from public.moodboard_scenes s2 where s2.project_id=p.id);
insert into public.moodboard_scene_items(scene_id,category,storage_path,image_paths,description)
select s.id,m.category,m.storage_path,m.image_paths,m.description
from public.moodboard_items m join public.moodboard_scenes s on s.project_id=m.project_id and s.position=0
where not exists(select 1 from public.moodboard_scene_items x where x.scene_id=s.id and x.category=m.category)
on conflict (scene_id,category) do nothing;

notify pgrst, 'reload schema';
