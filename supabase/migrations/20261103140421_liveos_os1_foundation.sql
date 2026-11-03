-- LiveOS OS1 foundation
-- Applied to the existing LiveOS Supabase project on 2026-11-03.
-- Vacation-assistant tables are intentionally untouched.

create table if not exists public.liveos_os1_models (
  model_key text primary key check (model_key ~ '^os[0-9]+$'),
  version_number integer not null unique check (version_number > 0),
  version_label text not null unique,
  display_name text not null,
  status text not null default 'prototype' check (status in ('prototype','stable','deprecated')),
  description text not null default '',
  architecture text not null default 'rules_examples',
  capabilities jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  is_default boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.liveos_os1_examples (
  id uuid primary key default gen_random_uuid(),
  model_key text not null references public.liveos_os1_models(model_key) on delete cascade,
  intent text not null,
  trigger_phrases text[] not null default '{}',
  ideal_response text not null,
  style_guidance text not null default '',
  priority integer not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (model_key, intent)
);

create table if not exists public.liveos_os1_knowledge (
  id uuid primary key default gen_random_uuid(),
  model_key text not null references public.liveos_os1_models(model_key) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  content text not null check (char_length(btrim(content)) between 1 and 20000),
  tags text[] not null default '{}',
  source_label text not null default 'Internes Wissen',
  source_url text,
  confidence numeric(5,4) not null default 1.0 check (confidence between 0 and 1),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.liveos_os1_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  model_key text not null default 'os1' references public.liveos_os1_models(model_key),
  title text not null default 'Neuer Chat' check (char_length(btrim(title)) between 1 and 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

create table if not exists public.liveos_os1_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  model_key text not null default 'os1' references public.liveos_os1_models(model_key),
  role text not null check (role in ('user','assistant','system')),
  content text not null check (char_length(btrim(content)) between 1 and 16000),
  attachment jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint liveos_os1_messages_owner_conversation_fk foreign key (conversation_id,user_id)
    references public.liveos_os1_conversations(id,user_id) on delete cascade
);

create table if not exists public.liveos_os1_user_settings (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  display_name text not null default 'LiveOS Nutzer' check (char_length(btrim(display_name)) between 1 and 50),
  response_style text not null default 'friendly' check (response_style in ('friendly','concise','detailed')),
  language_code text not null default 'de-DE',
  save_chat_history boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.liveos_os1_datasets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  description text not null default '',
  data_format text not null default 'prompt_response' check (data_format in ('prompt_response','instruction')),
  status text not null default 'draft' check (status in ('draft','ready','archived')),
  example_count integer not null default 0 check (example_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id,user_id)
);

create table if not exists public.liveos_os1_training_examples (
  id uuid primary key default gen_random_uuid(),
  dataset_id uuid not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  model_key text not null default 'os1' references public.liveos_os1_models(model_key),
  intent text not null default 'general',
  user_prompt text not null check (char_length(btrim(user_prompt)) between 1 and 12000),
  expected_response text not null check (char_length(btrim(expected_response)) between 1 and 16000),
  tags text[] not null default '{}',
  review_status text not null default 'draft' check (review_status in ('draft','approved','rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint liveos_os1_training_examples_owner_dataset_fk foreign key (dataset_id,user_id)
    references public.liveos_os1_datasets(id,user_id) on delete cascade
);

create table if not exists public.liveos_os1_training_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  model_key text not null default 'os1' references public.liveos_os1_models(model_key),
  run_type text not null default 'evaluation' check (run_type in ('evaluation','fine_tune','rule_update')),
  status text not null default 'queued' check (status in ('queued','running','completed','failed','cancelled')),
  progress integer not null default 0 check (progress between 0 and 100),
  total_examples integer not null default 0 check (total_examples >= 0),
  processed_examples integer not null default 0 check (processed_examples between 0 and total_examples),
  score numeric(5,2) check (score between 0 and 100),
  config jsonb not null default '{}'::jsonb,
  logs jsonb not null default '[]'::jsonb,
  summary text not null default '',
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (id,user_id)
);

create table if not exists public.liveos_os1_evaluations (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  test_key text not null,
  prompt text not null,
  expected_output text not null default '',
  actual_output text not null default '',
  score numeric(5,2) not null default 0 check (score between 0 and 100),
  passed boolean not null default false,
  notes text not null default '',
  created_at timestamptz not null default now(),
  constraint liveos_os1_evaluations_owner_run_fk foreign key (run_id,user_id)
    references public.liveos_os1_training_runs(id,user_id) on delete cascade
);

create table if not exists public.liveos_os1_releases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  model_key text not null references public.liveos_os1_models(model_key),
  version_label text not null,
  release_status text not null default 'draft' check (release_status in ('draft','tested','published','archived','failed')),
  release_notes text not null default '',
  metrics jsonb not null default '{}'::jsonb,
  artifact_uri text,
  created_at timestamptz not null default now(),
  published_at timestamptz,
  unique (model_key,version_label)
);

alter table public.liveos_os1_models enable row level security;
alter table public.liveos_os1_examples enable row level security;
alter table public.liveos_os1_knowledge enable row level security;
alter table public.liveos_os1_conversations enable row level security;
alter table public.liveos_os1_messages enable row level security;
alter table public.liveos_os1_user_settings enable row level security;
alter table public.liveos_os1_datasets enable row level security;
alter table public.liveos_os1_training_examples enable row level security;
alter table public.liveos_os1_training_runs enable row level security;
alter table public.liveos_os1_evaluations enable row level security;
alter table public.liveos_os1_releases enable row level security;

drop policy if exists liveos_os1_models_public_read on public.liveos_os1_models;
create policy liveos_os1_models_public_read on public.liveos_os1_models for select to anon,authenticated using (true);
drop policy if exists liveos_os1_examples_public_read on public.liveos_os1_examples;
create policy liveos_os1_examples_public_read on public.liveos_os1_examples for select to anon,authenticated using (is_active = true);
drop policy if exists liveos_os1_knowledge_public_read on public.liveos_os1_knowledge;
create policy liveos_os1_knowledge_public_read on public.liveos_os1_knowledge for select to anon,authenticated using (is_active = true);

drop policy if exists liveos_os1_conversations_owner_all on public.liveos_os1_conversations;
create policy liveos_os1_conversations_owner_all on public.liveos_os1_conversations for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists liveos_os1_messages_owner_all on public.liveos_os1_messages;
create policy liveos_os1_messages_owner_all on public.liveos_os1_messages for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists liveos_os1_settings_owner_all on public.liveos_os1_user_settings;
create policy liveos_os1_settings_owner_all on public.liveos_os1_user_settings for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists liveos_os1_datasets_owner_all on public.liveos_os1_datasets;
create policy liveos_os1_datasets_owner_all on public.liveos_os1_datasets for all to authenticated
  using (is_liveos_owner() and user_id = (select auth.uid()))
  with check (is_liveos_owner() and user_id = (select auth.uid()));
drop policy if exists liveos_os1_training_examples_owner_all on public.liveos_os1_training_examples;
create policy liveos_os1_training_examples_owner_all on public.liveos_os1_training_examples for all to authenticated
  using (is_liveos_owner() and user_id = (select auth.uid()))
  with check (is_liveos_owner() and user_id = (select auth.uid()) and exists (
    select 1 from public.liveos_os1_datasets d where d.id = dataset_id and d.user_id = (select auth.uid())
  ));
drop policy if exists liveos_os1_training_runs_owner_all on public.liveos_os1_training_runs;
create policy liveos_os1_training_runs_owner_all on public.liveos_os1_training_runs for all to authenticated
  using (is_liveos_owner() and user_id = (select auth.uid()))
  with check (is_liveos_owner() and user_id = (select auth.uid()));
drop policy if exists liveos_os1_evaluations_owner_all on public.liveos_os1_evaluations;
create policy liveos_os1_evaluations_owner_all on public.liveos_os1_evaluations for all to authenticated
  using (is_liveos_owner() and user_id = (select auth.uid()))
  with check (is_liveos_owner() and user_id = (select auth.uid()) and exists (
    select 1 from public.liveos_os1_training_runs r where r.id = run_id and r.user_id = (select auth.uid())
  ));
drop policy if exists liveos_os1_releases_owner_all on public.liveos_os1_releases;
create policy liveos_os1_releases_owner_all on public.liveos_os1_releases for all to authenticated
  using (is_liveos_owner() and user_id = (select auth.uid()))
  with check (is_liveos_owner() and user_id = (select auth.uid()));

revoke all on public.liveos_os1_models,public.liveos_os1_examples,public.liveos_os1_knowledge,
  public.liveos_os1_conversations,public.liveos_os1_messages,public.liveos_os1_user_settings,
  public.liveos_os1_datasets,public.liveos_os1_training_examples,public.liveos_os1_training_runs,
  public.liveos_os1_evaluations,public.liveos_os1_releases from anon;
grant select on public.liveos_os1_models,public.liveos_os1_examples,public.liveos_os1_knowledge to anon;
revoke all on public.liveos_os1_models,public.liveos_os1_examples,public.liveos_os1_knowledge,
  public.liveos_os1_conversations,public.liveos_os1_messages,public.liveos_os1_user_settings,
  public.liveos_os1_datasets,public.liveos_os1_training_examples,public.liveos_os1_training_runs,
  public.liveos_os1_evaluations,public.liveos_os1_releases from authenticated;
grant select on public.liveos_os1_models,public.liveos_os1_examples,public.liveos_os1_knowledge to authenticated;
grant select,insert,update,delete on public.liveos_os1_conversations,public.liveos_os1_messages,public.liveos_os1_user_settings to authenticated;
grant select,insert,update,delete on public.liveos_os1_datasets,public.liveos_os1_training_examples,public.liveos_os1_training_runs,public.liveos_os1_evaluations,public.liveos_os1_releases to authenticated;
grant all on public.liveos_os1_models,public.liveos_os1_examples,public.liveos_os1_knowledge,
  public.liveos_os1_conversations,public.liveos_os1_messages,public.liveos_os1_user_settings,
  public.liveos_os1_datasets,public.liveos_os1_training_examples,public.liveos_os1_training_runs,
  public.liveos_os1_evaluations,public.liveos_os1_releases to service_role;

insert into public.liveos_os1_models
(model_key,version_number,version_label,display_name,status,description,architecture,capabilities,is_default)
values ('os1',1,'OS1','LiveOS OS1','prototype',
'Erste eigenständige LiveOS-Version: regel- und beispielbasierte Gesprächslogik mit einfachen Berechnungen, Wikipedia-Nachschlagen und Textgrafiken. Noch kein großes trainiertes Sprachmodell.',
'rules_examples','["chat","basic_math","wikipedia_lookup","text_graphics","local_chat_history"]'::jsonb,true)
on conflict (model_key) do update set
  version_number=excluded.version_number,version_label=excluded.version_label,display_name=excluded.display_name,
  description=excluded.description,architecture=excluded.architecture,capabilities=excluded.capabilities,
  is_default=true,updated_at=now();

insert into public.liveos_os1_examples (model_key,intent,trigger_phrases,ideal_response,style_guidance,priority,is_active)
values
('os1','greeting',array['hallo','hi','hey','moin','guten morgen','guten tag'],'Hallo! Schön, dass du da bist. Was möchtest du heute machen?','Natürlich und freundlich; keine steife Begrüßung.',1,true),
('os1','identity',array['wer bist du','wie heißt du','wie heisst du','dein name'],'Ich bin LiveOS OS1 – die erste Version deines eigenen Assistenten. Ich kann mit dir schreiben, einfache Rechnungen lösen, passende Wikipedia-Informationen nachschlagen und einfache Textbilder gestalten.','Kurz erklären, dass OS1 die erste Regel-/Beispielversion ist.',2,true),
('os1','capabilities',array['was kannst du','was kannst du schon','welche funktionen hast du'],'Ich kann mit dir chatten, einfache Rechenaufgaben lösen, bei passenden Fragen Wikipedia nachschlagen und Textbilder mit Schrift gestalten. Ich lerne nicht automatisch aus jedem Chat und bin noch kein großes trainiertes Sprachmodell.','Nur vorhandene Funktionen nennen; Grenzen ehrlich erklären.',3,true),
('os1','thanks',array['danke','vielen dank','dankeschön','dankeschoen'],'Sehr gerne! Was möchtest du als Nächstes wissen?','Kurz und freundlich.',4,true),
('os1','wellbeing',array['wie geht es dir','wie gehts dir'],'Danke der Nachfrage! Ich bin bereit für unser Gespräch. Und wie geht es dir?','Locker und freundlich.',5,true),
('os1','goodbye',array['tschüss','tschuss','bis dann','auf wiedersehen','gute nacht'],'Bis bald! Ich freue mich auf unser nächstes Gespräch.','Natürlich, nicht übertrieben.',6,true),
('os1','joke',array['erzähl einen witz','sag einen witz','witz'],'Warum können Geister so schlecht lügen? Weil man durch sie hindurchsieht!','Ein kurzer, harmloser Witz.',7,true)
on conflict (model_key,intent) do update set
  trigger_phrases=excluded.trigger_phrases,ideal_response=excluded.ideal_response,style_guidance=excluded.style_guidance,
  priority=excluded.priority,is_active=excluded.is_active,updated_at=now();
