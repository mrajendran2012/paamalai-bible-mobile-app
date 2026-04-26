-- Migration 0001 — initial schema for Paamalai.
-- Implements the canonical schema in specs/0000-master-v1.md §"Canonical Supabase schema"
-- plus the additional `bible_verses` and `devotion_regenerations` tables required
-- by specs/0003-daily-devotion/design.md.

-- ============================================================================
-- profiles
-- ============================================================================
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  preferred_language text not null default 'en'
    check (preferred_language in ('en','ta')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy profiles_self on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- Auto-create a profile row when a new auth user appears (handles anonymous sign-in too).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- interests
-- ============================================================================
create table public.interests (
  user_id uuid not null references public.profiles on delete cascade,
  tag text not null,
  primary key (user_id, tag)
);

alter table public.interests enable row level security;

create policy interests_self on public.interests
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- reading_plans
-- ============================================================================
create table public.reading_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  kind text not null check (kind in ('yearly_canonical')),
  started_on date not null,
  created_at timestamptz not null default now()
);

create index reading_plans_user_idx on public.reading_plans(user_id);

alter table public.reading_plans enable row level security;

create policy reading_plans_self on public.reading_plans
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- reading_progress
-- ============================================================================
create table public.reading_progress (
  plan_id uuid not null references public.reading_plans on delete cascade,
  day_index int not null check (day_index between 1 and 365),
  completed_at timestamptz not null default now(),
  primary key (plan_id, day_index)
);

alter table public.reading_progress enable row level security;

create policy reading_progress_self on public.reading_progress
  for all using (
    exists (
      select 1 from public.reading_plans p
      where p.id = plan_id and p.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.reading_plans p
      where p.id = plan_id and p.user_id = auth.uid()
    )
  );

-- ============================================================================
-- devotions_cache  (one row per (user_id, for_date, language))
-- ============================================================================
create table public.devotions_cache (
  user_id uuid not null references public.profiles on delete cascade,
  for_date date not null,
  language text not null check (language in ('en','ta')),
  passage_ref text not null,
  body_md text not null,
  model text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, for_date, language)
);

alter table public.devotions_cache enable row level security;

create policy devotions_cache_self on public.devotions_cache
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- devotion_regenerations  (audit log used to enforce the 3/day re-roll cap;
-- see specs/0003-daily-devotion/spec.md FR-DD-03)
-- ============================================================================
create table public.devotion_regenerations (
  user_id uuid not null references public.profiles on delete cascade,
  for_date date not null,
  at timestamptz not null default now()
);

create index devotion_regenerations_lookup_idx
  on public.devotion_regenerations(user_id, for_date);

alter table public.devotion_regenerations enable row level security;

create policy devotion_regenerations_self on public.devotion_regenerations
  for select using (auth.uid() = user_id);
-- Inserts happen only via the edge function (service role); no insert policy needed.

-- ============================================================================
-- bible_verses  (server-side mirror of bundled SQLite, used by generate-devotion
-- to resolve any plan-day passage; see specs/0003-daily-devotion/design.md)
-- ============================================================================
create table public.bible_verses (
  translation text not null check (translation in ('WEB','TAUV')),
  book_code text not null,        -- 'GEN', 'EXO', ... 'REV'
  chapter int not null,
  verse int not null,
  text text not null,
  primary key (translation, book_code, chapter, verse)
);

create index bible_verses_chapter_idx
  on public.bible_verses(translation, book_code, chapter);

-- Bible text is public scripture; readable to all authenticated users.
alter table public.bible_verses enable row level security;
create policy bible_verses_read on public.bible_verses
  for select using (auth.role() = 'authenticated');
