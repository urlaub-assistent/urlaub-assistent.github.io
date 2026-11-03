-- Applied to Supabase project twcacjwmahameglodljl.
-- Worker bridge: only service_role can access these SECURITY DEFINER RPCs.
create table if not exists liveos_os2_private.model_evaluations (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references liveos_os2_private.training_runs(id) on delete cascade,
  benchmark_id uuid not null references liveos_os2_private.training_benchmarks(id),
  candidate_output text not null default '',
  score numeric(5,2) not null default 0,
  passed boolean not null default false,
  task_integrity_ok boolean not null default false,
  cheating_detected boolean not null default false,
  score_details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(run_id, benchmark_id)
);
create index if not exists model_evaluations_benchmark_id_idx
  on liveos_os2_private.model_evaluations(benchmark_id);
alter table liveos_os2_private.model_evaluations enable row level security;
revoke all on liveos_os2_private.model_evaluations from public, anon, authenticated, service_role;

create or replace function public.liveos_os2_worker_get_dataset()
returns jsonb language sql stable security definer
set search_path = pg_catalog, public, liveos_os2_private
as $$
  select jsonb_build_object(
    'examples', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',e.id,'intent',e.intent,'trigger_phrases',e.trigger_phrases,
        'ideal_response',e.ideal_response,'style_guidance',e.style_guidance,'priority',e.priority
      ) order by e.priority desc, e.created_at)
      from public.liveos_os1_examples e
      where e.model_key='os2' and e.is_active
    ), '[]'::jsonb),
    'benchmarks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',b.id,'benchmark_key',b.benchmark_key,'task_kind',b.task_kind,'prompt',b.prompt
      ) order by b.benchmark_key)
      from liveos_os2_private.training_benchmarks b
      where b.is_active
    ), '[]'::jsonb)
  );
$$;

create or replace function public.liveos_os2_worker_start_run(
  p_base_model text default 'Qwen/Qwen2.5-0.5B-Instruct',
  p_training_config jsonb default '{}'::jsonb
)
returns uuid language plpgsql security definer
set search_path = pg_catalog, public, liveos_os2_private
as $$
declare v_run_id uuid;
begin
  insert into liveos_os2_private.training_runs(model_key,status,details)
  values(
    'os2','running',
    coalesce(p_training_config,'{}'::jsonb) ||
    jsonb_build_object(
      'source','kaggle_free_gpu','budget_eur',0,
      'base_model',left(coalesce(p_base_model,'Qwen/Qwen2.5-0.5B-Instruct'),160),
      'real_neural_training',true,'weights_updated',false,
      'scorer','hidden_assertions_all_or_nothing_v2'
    )
  ) returning id into v_run_id;
  return v_run_id;
end;
$$;

create or replace function public.liveos_os2_worker_score_candidate(
  p_run_id uuid,p_benchmark_id uuid,p_candidate text
)
returns jsonb language plpgsql security definer
set search_path = pg_catalog, public, liveos_os2_private
as $$
declare
  v_benchmark liveos_os2_private.training_benchmarks%rowtype;
  v_actual_digest text;
  v_integrity boolean;
  v_score_data jsonb;
  v_points numeric(5,2);
  v_passed boolean;
  v_cheating boolean;
begin
  if not exists (
    select 1 from liveos_os2_private.training_runs r
    where r.id=p_run_id and r.model_key='os2' and r.status='running'
  ) then raise exception 'Unknown or inactive OS2 training run.'; end if;

  select * into v_benchmark from liveos_os2_private.training_benchmarks
  where id=p_benchmark_id and is_active;
  if not found then raise exception 'Unknown or inactive OS2 benchmark.'; end if;

  v_actual_digest := liveos_os2_private.benchmark_digest(
    v_benchmark.benchmark_key,v_benchmark.task_kind,v_benchmark.prompt,
    v_benchmark.is_solvable,v_benchmark.required_patterns,v_benchmark.forbidden_patterns
  );
  v_integrity := v_benchmark.task_digest is not null
    and v_benchmark.task_digest=v_actual_digest;

  v_score_data := liveos_os2_private.score_candidate(
    v_benchmark.prompt,coalesce(p_candidate,''),v_benchmark.is_solvable,
    v_benchmark.required_patterns,v_benchmark.forbidden_patterns,
    v_benchmark.task_digest,v_actual_digest,v_integrity
  );
  v_points := coalesce((v_score_data->>'points')::numeric,0);
  v_passed := coalesce((v_score_data->>'passed')::boolean,false);
  v_cheating := coalesce((v_score_data->>'cheating_detected')::boolean,false);

  insert into liveos_os2_private.model_evaluations(
    run_id,benchmark_id,candidate_output,score,passed,task_integrity_ok,cheating_detected,score_details
  ) values (
    p_run_id,p_benchmark_id,coalesce(p_candidate,''),v_points,v_passed,v_integrity,v_cheating,
    v_score_data || jsonb_build_object('scorer','hidden_assertions_all_or_nothing_v2')
  )
  on conflict(run_id,benchmark_id) do update set
    candidate_output=excluded.candidate_output,score=excluded.score,passed=excluded.passed,
    task_integrity_ok=excluded.task_integrity_ok,cheating_detected=excluded.cheating_detected,
    score_details=excluded.score_details,created_at=now();

  -- Hidden expected patterns and failed assertions never leave the database.
  return jsonb_build_object(
    'points',v_points,'passed',v_passed,'reason',v_score_data->>'reason',
    'task_integrity_ok',v_integrity,'cheating_detected',v_cheating
  );
end;
$$;

create or replace function public.liveos_os2_worker_finish_run(
  p_run_id uuid,p_training_loss numeric default null,p_model_repo text default null,
  p_epochs integer default 1,p_training_examples integer default 0
)
returns jsonb language plpgsql security definer
set search_path = pg_catalog, public, liveos_os2_private
as $$
declare
  v_total integer; v_passed integer; v_average numeric(5,2); v_cheating integer;
begin
  select count(*),count(*) filter(where passed),avg(score),count(*) filter(where cheating_detected)
  into v_total,v_passed,v_average,v_cheating
  from liveos_os2_private.model_evaluations where run_id=p_run_id;

  update liveos_os2_private.training_runs
  set status='completed',tasks_scored=v_total,tasks_passed=v_passed,average_score=v_average,
      details=details || jsonb_build_object(
        'real_neural_training',true,'weights_updated',true,'training_loss',p_training_loss,
        'model_repo',p_model_repo,'epochs',greatest(1,least(coalesce(p_epochs,1),20)),
        'training_examples',greatest(0,coalesce(p_training_examples,0)),
        'hidden_benchmarks_scored',v_total,'hidden_benchmarks_passed',v_passed,
        'cheating_detected',v_cheating,'completed_by','kaggle_worker'
      ),
      finished_at=now()
  where id=p_run_id and model_key='os2' and status='running';
  if not found then raise exception 'Unknown or already completed OS2 training run.'; end if;

  update public.liveos_os1_models
  set metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
        'last_neural_training_at',now(),'last_neural_training_run_id',p_run_id,
        'latest_adapter_repo',p_model_repo,'latest_training_loss',p_training_loss,
        'weight_training_enabled',true,'inference_backend_configured',false
      ),updated_at=now()
  where model_key='os2';

  return jsonb_build_object(
    'run_id',p_run_id,'model_key','os2','weights_updated',true,
    'training_loss',p_training_loss,'evaluation_tasks',v_total,
    'evaluation_passed',v_passed,'average_score',v_average,
    'cheating_detected',v_cheating,'model_repo',p_model_repo
  );
end;
$$;

revoke all on function public.liveos_os2_worker_get_dataset() from public,anon,authenticated;
revoke all on function public.liveos_os2_worker_start_run(text,jsonb) from public,anon,authenticated;
revoke all on function public.liveos_os2_worker_score_candidate(uuid,uuid,text) from public,anon,authenticated;
revoke all on function public.liveos_os2_worker_finish_run(uuid,numeric,text,integer,integer) from public,anon,authenticated;
grant execute on function public.liveos_os2_worker_get_dataset() to service_role;
grant execute on function public.liveos_os2_worker_start_run(text,jsonb) to service_role;
grant execute on function public.liveos_os2_worker_score_candidate(uuid,uuid,text) to service_role;
grant execute on function public.liveos_os2_worker_finish_run(uuid,numeric,text,integer,integer) to service_role;
