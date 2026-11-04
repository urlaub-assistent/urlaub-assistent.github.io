-- LiveOS Training Engine v1: owner-scoped model state and run history.
-- Applied to Supabase project twcacjwmahameglodljl using the Supabase SQL connection.

create table if not exists public.liveos_training_engine_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  model_key text not null default 'os2-skillnet-v1',
  model_state jsonb not null default '{}'::jsonb,
  metrics jsonb not null default '{}'::jsonb,
  focus text not null default 'Allgemeine Fähigkeiten',
  updated_at timestamptz not null default now()
);

create table if not exists public.liveos_training_engine_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  model_key text not null default 'os2-skillnet-v1',
  focus text not null default 'Allgemeine Fähigkeiten',
  status text not null default 'running'
    check (status in ('running','paused','completed','failed','stopped')),
  metrics jsonb not null default '{}'::jsonb,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists liveos_training_engine_runs_user_started_idx
  on public.liveos_training_engine_runs(user_id, started_at desc);

alter table public.liveos_training_engine_states enable row level security;
alter table public.liveos_training_engine_runs enable row level security;

drop policy if exists "Users manage their own LiveOS training state" on public.liveos_training_engine_states;
create policy "Users manage their own LiveOS training state"
on public.liveos_training_engine_states
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users manage their own LiveOS training runs" on public.liveos_training_engine_runs;
create policy "Users manage their own LiveOS training runs"
on public.liveos_training_engine_runs
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.liveos_training_engine_states to authenticated;
grant select, insert, update, delete on public.liveos_training_engine_runs to authenticated;
revoke all on public.liveos_training_engine_states from anon;
revoke all on public.liveos_training_engine_runs from anon;
