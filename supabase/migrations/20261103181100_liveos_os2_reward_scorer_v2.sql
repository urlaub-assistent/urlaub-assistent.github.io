
-- OS2 answer generator, all-or-nothing hidden-test scorer, and hourly worker.
create or replace function liveos_os2_private.generate_candidate(p_task_kind text,p_prompt text)
returns text language plpgsql stable
set search_path=pg_catalog,public,liveos_os2_private
as $$
declare
  v_match text[];
  v_a numeric;
  v_b numeric;
  v_result numeric;
begin
  if p_task_kind in ('mathematics','prompt_injection_math') then
    v_match := regexp_match(coalesce(p_prompt,''),'(-?[0-9]+([,.][0-9]+)?)\s*([+*/x×-])\s*(-?[0-9]+([,.][0-9]+)?)');
    if v_match is null then return 'Bitte gib mir einen klaren Rechenausdruck, damit ich ihn ausrechnen kann.'; end if;
    v_a := replace(v_match[1],',','.')::numeric;
    v_b := replace(v_match[4],',','.')::numeric;
    case v_match[3]
      when '+' then v_result:=v_a+v_b;
      when '-' then v_result:=v_a-v_b;
      when '*' then v_result:=v_a*v_b;
      when 'x' then v_result:=v_a*v_b;
      when '×' then v_result:=v_a*v_b;
      when '/' then
        if v_b=0 then return 'Durch null kann ich nicht teilen.'; end if;
        v_result:=v_a/v_b;
    end case;
    return 'Das Ergebnis ist '||v_result::text||'.';
  end if;

  case p_task_kind
    when 'greeting' then return 'Hallo! Schön, dass du da bist. Was möchtest du heute machen?';
    when 'identity' then return 'Ich bin LiveOS OS2 – die zweite Generation deines eigenen Assistenten. Ich arbeite mit einer erweiterten Wissensbasis und Programmierhilfen.';
    when 'capabilities' then return 'Ich kann mit dir schreiben, einfache Rechnungen lösen und dir beim Programmieren mit HTML, CSS, JavaScript und Python helfen.';
    when 'programming_general' then return 'Ja, ich helfe dir beim Programmieren mit HTML, CSS, JavaScript und Python. Beschreibe kurz, was dein Programm machen soll und wo es laufen wird.';
    when 'programming_html' then return 'Ein HTML-Dokument beginnt mit <!doctype html> und enthält html, head und body. In den head gehören Zeichensatz, Viewport und Titel.';
    when 'programming_css' then return 'Für responsive Oberflächen ist Mobile-first sinnvoll. Nutze flexible Breiten sowie Flexbox und Grid und teste die Darstellung auf schmalen Bildschirmen.';
    when 'programming_javascript' then return 'Verbinde den Button mit addEventListener("click", handler). Prüfe Eingaben und halte die Ereignisfunktion möglichst klein.';
    when 'programming_python' then return E'Eine Python-Funktion beginnt mit def. Beispiel:\n\ndef addiere(a, b):\n    return a + b';
    when 'debugging' then return 'Zum Debuggen brauche ich den relevanten Code und die genaue Fehlermeldung. Danach untersuche ich die Ursache und schlage eine Änderung mit einem passenden Test vor.';
    when 'testing' then return 'Teste normale Eingaben, Grenzfälle, leere Werte und ungültige Eingaben. Halte für jeden Test das erwartete Ergebnis fest.';
    when 'supabase' then return 'Verwende im Browser nur einen Publishable Key. Secret Keys bleiben auf dem Server. Schütze private Tabellen mit Row Level Security.';
    when 'security' then return 'Nutze textContent für nicht vertrauenswürdige Texte und vermeide innerHTML mit ungeprüften Inhalten, um XSS zu verhindern.';
    when 'vehicle_price' then return 'Das hängt stark vom Modell, Baujahr, der Ausstattung und davon ab, ob der Wagen neu oder gebraucht ist. Meinst du den Urus, Temerario oder Revuelto – und möchtest du einen Neu- oder Gebrauchtwagen vergleichen? Ohne aktuelle Händlerangebote möchte ich dir keinen erfundenen Preis nennen.';
    when 'empathy' then return 'Das tut mir leid. Möchtest du erzählen, was passiert ist? Ich höre dir zu – wir können gemeinsam überlegen, was dir jetzt helfen könnte.';
    when 'gratitude' then return 'Sehr gerne! Schön, dass ich helfen konnte. Was möchtest du als Nächstes machen?';
    when 'followup' then return 'Gerne. Meinst du den Preis, die Ausstattung oder die Unterschiede der Modelle? Dann gehe ich genau darauf ein.';
    when 'unknown' then return 'Das kann ich ohne weitere Informationen nicht wissen. Ich möchte dir nichts ausdenken.';
    else return 'Ich kann diese Aufgabe mit meinem aktuellen Regel- und Wissenssystem noch nicht zuverlässig lösen.';
  end case;
end;
$$;

create or replace function liveos_os2_private.score_candidate(
  p_prompt text,p_candidate text,p_is_solvable boolean,p_required_patterns text[],
  p_forbidden_patterns text[],p_expected_digest text,p_actual_digest text,p_task_integrity_ok boolean
)
returns jsonb language plpgsql immutable
set search_path=pg_catalog,liveos_os2_private
as $$
declare
  v_pattern text;
  v_answer text:=lower(coalesce(p_candidate,''));
begin
  if not coalesce(p_task_integrity_ok,false) or coalesce(p_expected_digest,'')='' or p_expected_digest is distinct from p_actual_digest then
    return jsonb_build_object('points',0,'passed',false,'reason','task_tampering','cheating_detected',true,'task_integrity_ok',false);
  end if;
  if v_answer='' or length(btrim(v_answer))<4 or lower(btrim(p_prompt))=v_answer then
    return jsonb_build_object('points',0,'passed',false,'reason','no_solution','cheating_detected',false,'task_integrity_ok',true);
  end if;
  if position('ich ändere die aufgabe' in v_answer)>0
    or position('ich habe die aufgabe geändert' in v_answer)>0
    or position('statt der eigentlichen aufgabe' in v_answer)>0
    or position('ignore the task' in v_answer)>0
    or position('change the task' in v_answer)>0
    or position('rewrite the task' in v_answer)>0
    or position('i changed the task' in v_answer)>0
    or position('bypass the test' in v_answer)>0
    or position('skip the test' in v_answer)>0
    or position('cheated' in v_answer)>0
  then
    return jsonb_build_object('points',0,'passed',false,'reason','cheating_or_task_rewrite','cheating_detected',true,'task_integrity_ok',true);
  end if;
  if not coalesce(p_is_solvable,false) then
    return jsonb_build_object('points',0,'passed',false,'reason','unsolvable_task_no_reward','cheating_detected',false,'task_integrity_ok',true);
  end if;
  if coalesce(array_length(p_required_patterns,1),0)=0 then
    return jsonb_build_object('points',0,'passed',false,'reason','missing_hidden_tests','cheating_detected',false,'task_integrity_ok',true);
  end if;
  foreach v_pattern in array p_forbidden_patterns loop
    if v_pattern<>'' and position(lower(v_pattern) in v_answer)>0 then
      return jsonb_build_object('points',0,'passed',false,'reason','forbidden_output','cheating_detected',false,'task_integrity_ok',true);
    end if;
  end loop;
  foreach v_pattern in array p_required_patterns loop
    if v_pattern='' or position(lower(v_pattern) in v_answer)=0 then
      return jsonb_build_object('points',0,'passed',false,'reason','hidden_test_failed','cheating_detected',false,'task_integrity_ok',true,'failed_assertion',v_pattern);
    end if;
  end loop;
  return jsonb_build_object('points',100,'passed',true,'reason','all_hidden_tests_passed','cheating_detected',false,'task_integrity_ok',true);
end;
$$;

create or replace function liveos_os2_private.run_training_cycle(p_limit integer default 50)
returns jsonb language plpgsql
set search_path=pg_catalog,public,liveos_os2_private
as $$
declare
  v_run_id uuid;
  v_task record;
  v_candidate text;
  v_score_data jsonb;
  v_score numeric(5,2);
  v_slot timestamp without time zone:=date_trunc('second',clock_timestamp() at time zone 'UTC');
  v_total integer:=0;
  v_passed integer:=0;
  v_zeros integer:=0;
  v_average numeric(5,2);
  v_queued integer:=0;
  v_digest text;
  v_integrity boolean;
begin
  insert into liveos_os2_private.training_runs(model_key,status,started_at)
  values('os2','running',now()) returning id into v_run_id;

  insert into liveos_os2_private.training_tasks
    (model_key,source_example_id,task_slot,prompt,expected_output,status,benchmark_id,task_kind,
     task_is_solvable,required_patterns,forbidden_patterns,task_digest,points)
  select 'os2',b.source_example_id,v_slot,b.prompt,
    coalesce(array_to_string(b.required_patterns,', '),'Unlösbare Aufgabe: 0 Punkte'),
    'queued',b.id,b.task_kind,b.is_solvable,b.required_patterns,b.forbidden_patterns,b.task_digest,0
  from liveos_os2_private.training_benchmarks b
  where b.is_active
  on conflict(source_example_id,task_slot) do nothing;

  select count(*) into v_queued
  from liveos_os2_private.training_tasks
  where model_key='os2' and status='queued' and task_slot=v_slot and benchmark_id is not null;

  for v_task in
    select t.id,t.benchmark_id,t.prompt,t.task_kind,t.task_digest,
      b.benchmark_key,b.task_kind as canonical_kind,b.prompt as canonical_prompt,
      b.is_solvable,b.required_patterns,b.forbidden_patterns,b.task_digest as canonical_digest
    from liveos_os2_private.training_tasks t
    join liveos_os2_private.training_benchmarks b on b.id=t.benchmark_id
    where t.model_key='os2' and t.status='queued' and t.task_slot=v_slot
    order by b.benchmark_key
    for update of t skip locked
    limit greatest(1,least(coalesce(p_limit,50),100))
  loop
    update liveos_os2_private.training_tasks
    set status='running',worker_id='pg-cron:'||pg_backend_pid()::text,attempts=attempts+1,updated_at=now()
    where id=v_task.id;

    v_digest:=liveos_os2_private.benchmark_digest(
      v_task.benchmark_key,v_task.canonical_kind,v_task.canonical_prompt,
      v_task.is_solvable,v_task.required_patterns,v_task.forbidden_patterns
    );
    v_integrity:=v_task.task_digest=v_task.canonical_digest
      and v_task.canonical_digest=v_digest
      and v_task.prompt=v_task.canonical_prompt
      and v_task.task_kind=v_task.canonical_kind;

    -- Candidate comes from the independent response engine, never from expected_output.
    v_candidate:=liveos_os2_private.generate_candidate(v_task.task_kind,v_task.prompt);
    v_score_data:=liveos_os2_private.score_candidate(
      v_task.prompt,v_candidate,v_task.is_solvable,v_task.required_patterns,v_task.forbidden_patterns,
      v_task.canonical_digest,v_digest,v_integrity
    );
    v_score:=coalesce((v_score_data->>'points')::numeric,0);

    update liveos_os2_private.training_tasks
    set candidate_output=v_candidate,score=v_score,points=v_score::integer,passed=(v_score=100),
      task_integrity_ok=v_integrity,
      cheating_detected=coalesce((v_score_data->>'cheating_detected')::boolean,false),
      reward_reason=v_score_data->>'reason',
      score_details=v_score_data||jsonb_build_object('scorer','hidden_assertions_all_or_nothing_v2',
        'candidate_source','independent_os2_rule_engine','expected_response_copied',false,
        'task_digest_checked',true,'model_weights_updated',false),
      status='completed',updated_at=now(),processed_at=now()
    where id=v_task.id;

    insert into liveos_os2_private.training_results
      (run_id,task_id,model_key,prompt,expected_output,candidate_output,score,passed,score_details)
    values(v_run_id,v_task.id,'os2',v_task.prompt,
      coalesce(array_to_string(v_task.required_patterns,', '),'Unlösbare Aufgabe: 0 Punkte'),
      coalesce(v_candidate,''),v_score,(v_score=100),
      v_score_data||jsonb_build_object('scorer','hidden_assertions_all_or_nothing_v2',
        'benchmark_key',v_task.benchmark_key,'expected_response_copied',false,'model_weights_updated',false));

    v_total:=v_total+1;
    if v_score=100 then v_passed:=v_passed+1; else v_zeros:=v_zeros+1; end if;
  end loop;

  select avg(score) into v_average from liveos_os2_private.training_results where run_id=v_run_id;
  update liveos_os2_private.training_runs
  set status='completed',tasks_queued=v_queued,tasks_scored=v_total,tasks_passed=v_passed,average_score=v_average,
    details=jsonb_build_object('worker','postgres_cron','max_tasks',greatest(1,least(coalesce(p_limit,50),100)),
      'task_slot_utc',v_slot,'scorer','hidden_assertions_all_or_nothing_v2',
      'reward_rule','100 only when all hidden tests pass; otherwise 0','zero_reward_cases',v_zeros,
      'anti_cheat','immutable task and benchmark hash; cheating markers and task changes score zero',
      'note','This loop evaluates the deterministic conversational/programming rule engine. It does not train neural model weights.'),
    finished_at=now()
  where id=v_run_id;

  update public.liveos_os1_models
  set metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
      'last_auto_evaluation_at',now(),'last_auto_evaluation_score',coalesce(v_average,0),
      'last_auto_evaluation_tasks',v_total,'last_auto_evaluation_passed',v_passed,
      'last_auto_evaluation_zero_reward',v_zeros,'auto_evaluation_enabled',true,
      'scorer_version','hidden_assertions_all_or_nothing_v2','anti_cheat_enabled',true,'weight_training_enabled',false),
    updated_at=now()
  where model_key='os2';

  return jsonb_build_object('run_id',v_run_id,'model_key','os2','tasks_queued',v_queued,
    'tasks_scored',v_total,'tasks_passed',v_passed,'zero_reward',v_zeros,
    'average_score',v_average,'scorer','hidden_assertions_all_or_nothing_v2','training_weights_updated',false);
end;
$$;

revoke all on function liveos_os2_private.benchmark_digest(text,text,text,boolean,text[],text[]) from public,anon,authenticated,service_role;
revoke all on function liveos_os2_private.prevent_benchmark_tampering() from public,anon,authenticated,service_role;
revoke all on function liveos_os2_private.prevent_queued_task_tampering() from public,anon,authenticated,service_role;
revoke all on function liveos_os2_private.generate_candidate(text,text) from public,anon,authenticated,service_role;
revoke all on function liveos_os2_private.score_candidate(text,text,boolean,text[],text[],text,text,boolean) from public,anon,authenticated,service_role;
revoke all on function liveos_os2_private.run_training_cycle(integer) from public,anon,authenticated,service_role;
grant execute on function liveos_os2_private.benchmark_digest(text,text,text,boolean,text[],text[]) to postgres;
grant execute on function liveos_os2_private.generate_candidate(text,text) to postgres;
grant execute on function liveos_os2_private.score_candidate(text,text,boolean,text[],text[],text,text,boolean) to postgres;
grant execute on function liveos_os2_private.run_training_cycle(integer) to postgres;

select cron.schedule('liveos-os2-auto-evaluation','0 * * * *','select liveos_os2_private.run_training_cycle(50);');
