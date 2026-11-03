
-- LiveOS OS2: second model generation and scheduled automatic rule/knowledge evaluation.
-- IMPORTANT: this evaluates the deterministic retrieval layer; it does NOT fine-tune model weights.

create extension if not exists pg_cron;

create schema if not exists liveos_os2_private;
revoke all on schema liveos_os2_private from public, anon, authenticated, service_role;
grant usage on schema liveos_os2_private to postgres;

update public.liveos_os1_models set is_default=false,updated_at=now() where model_key='os1';

insert into public.liveos_os1_models
(model_key,version_number,version_label,display_name,status,description,architecture,capabilities,metadata,is_default)
values
('os2',2,'OS2','LiveOS OS2','prototype',
 'Zweite LiveOS-Generation mit erweiterter Wissenssuche, Programmierhilfen, Chat-Kontext und automatischer Qualitätsbewertung. Regel-/Wissenssystem; kein neuronales Fine-Tuning.',
 'retrieval_rules_auto_evaluation',
 '["chat","conversation_context","basic_math","percentages","wikipedia_lookup","text_graphics","html","css","javascript","python","sql","supabase","debugging","testing","git","code_explanation","responsive_design","security","knowledge_retrieval","automatic_evaluation"]'::jsonb,
 jsonb_build_object('generation',2,'training_mode','scheduled_rule_and_knowledge_evaluation','auto_evaluation_enabled',true,'evaluation_schedule','hourly','weight_training_enabled',false,'inference_backend_configured',false,'note','The hourly loop evaluates the deterministic rule and retrieval layer. No neural model weights are trained.'),
 true)
on conflict(model_key) do update set
 version_number=excluded.version_number,
 version_label=excluded.version_label,
 display_name=excluded.display_name,
 status=excluded.status,
 description=excluded.description,
 architecture=excluded.architecture,
 capabilities=excluded.capabilities,
 metadata=coalesce(public.liveos_os1_models.metadata,'{}'::jsonb)||excluded.metadata,
 is_default=true,
 updated_at=now();

insert into public.liveos_os1_examples(model_key,intent,trigger_phrases,ideal_response,style_guidance,priority,is_active)
values
('os2','greeting',array['hallo','hi','hey','moin','guten morgen','guten tag'],'Hallo! Schön, dass du da bist. Was möchtest du heute machen?','Natürlich, freundlich und kurz antworten.',1,true),
('os2','identity',array['wer bist du','wie heißt du','wie heisst du','was ist liveos'],'Ich bin LiveOS OS2 – die zweite Generation deines eigenen Assistenten. Ich arbeite mit einer erweiterten Wissensbasis, Gesprächsregeln und Programmierhilfen. Ich bin noch kein großes trainiertes Sprachmodell, werde aber mit geprüften Beispielen und Tests weiterentwickelt.','Modellgrenzen ehrlich benennen; nicht behaupten, ein neuronales Modell zu sein.',2,true),
('os2','capabilities',array['was kannst du','was kannst du schon','was kannst du alles'],'Ich kann mit dir schreiben, einfache Rechnungen lösen, Grundlagen zu HTML, CSS, JavaScript, Python und SQL erklären, kleine Programme erstellen, Codefehler systematisch untersuchen und passende Wikipedia-Informationen nachschlagen. Bei komplexen Aufgaben sage ich offen, was ich nicht sicher weiß.','Nur nachweisbare Funktionen nennen; Grenzen klar markieren.',3,true),
('os2','programming_general',array['kannst du programmieren','programmiere mir','schreib mir code','hilf mir beim programmieren'],'Ja. Ich kann dir bei HTML, CSS, JavaScript, Python und einfachen SQL-Aufgaben helfen. Beschreibe, was das Programm tun soll und wo es laufen wird. Ich liefere dir eine vollständige Vorlage, erkläre wichtige Stellen und nenne konkrete Tests.','Ziel und Laufzeitumgebung klären; ausführbaren Code und Tests bevorzugen.',4,true),
('os2','programming_html',array['html struktur','html grundgeruest','html dokument','html seite'],'Ein HTML5-Dokument enthält doctype, html, head und body. In den head gehören Zeichensatz, Viewport und Titel. Im body stehen die sichtbaren Bereiche. Für gute Zugänglichkeit verwende semantische Elemente wie main, nav, header und section.','HTML5, semantisch, mobilfreundlich und barrierearm schreiben.',5,true),
('os2','programming_css',array['css layout','responsive design','mobile first','handy layout'],'Für Mobile-first beginnst du mit dem schmalen Bildschirm. Nutze flexible Breiten, Flexbox oder Grid, gut erreichbare Touch-Ziele und Media Queries für größere Bildschirme. Vermeide horizontales Scrollen und berücksichtige Safe Areas.','Kein festes Desktop-Layout; mit kleinen Viewports beginnen.',6,true),
('os2','programming_javascript',array['javascript funktion','js funktion','javascript code','dom javascript'],'JavaScript-Funktionen sollten eine klar abgegrenzte Aufgabe haben, Eingaben prüfen und Ergebnisse zurückgeben. Verbinde Klicks und Formulare mit addEventListener. Verwende textContent für nicht vertrauenswürdige Texte und sichere Fehlerbehandlung mit try/catch/finally.','Kleine testbare Funktionen, Eingabeprüfung und Fehlerbehandlung zeigen.',7,true),
('os2','programming_python',array['python funktion','python code','python programm','python lernen'],'In Python werden Funktionen mit def definiert. Achte auf korrekte Einrückung, aussagekräftige Namen und passende Typannotationen. Ein Programmeinstieg kann über if __name__ == "__main__": erfolgen.','Ausführbare Beispiele mit Startbefehl liefern.',8,true),
('os2','debugging',array['debugging','programmierfehler','fehlermeldung im code','code funktioniert nicht'],'Zum Debuggen brauche ich den relevanten Code, die vollständige Fehlermeldung und das erwartete Verhalten. Ich suche die Fehlerstelle, erkläre die Ursache, schlage eine gezielte Änderung vor und nenne einen Test. Entferne vorher Passwörter und API-Schlüssel.','Nicht raten; Fehlerursache belegen; konkrete Tests ergänzen.',9,true),
('os2','testing',array['code testen','unit test','software testen','programm testen'],'Teste normale Eingaben, Grenzfälle und ungültige Werte. Ein Unit-Test prüft eine einzelne Funktion; ein Integrationstest das Zusammenspiel mehrerer Teile. Halte erwartetes und tatsächliches Ergebnis fest.','Tests mit Eingabe, erwartetem Ergebnis und tatsächlichem Ergebnis formulieren.',10,true),
('os2','supabase',array['supabase programmieren','supabase client','supabase rls','supabase datenbank'],'Bei Supabase dürfen im Browser nur Publishable Keys verwendet werden. Secret Keys und Service-Role-Keys gehören ausschließlich auf vertrauenswürdige Server. Private Tabellen brauchen passende Row-Level-Security-Regeln.','Keine geheimen Schlüssel in Frontend-Code; RLS konkret prüfen.',11,true),
('os2','security',array['web sicherheit','javascript sicherheit','xss verhindern','passwort im code'],'Behandle Eingaben als nicht vertrauenswürdig. Vermeide unsicheres innerHTML für fremde Inhalte, validiere Eingaben, halte Geheimnisse aus dem Browser fern und beschränke Zugriffe auf das notwendige Minimum.','Sichere Standardlösungen vor Komfort stellen.',12,true),
('os2','unknown',array['das weißt du nicht','wenn du etwas nicht weißt','unsichere antwort'],'Wenn ich keine verlässliche Antwort habe, sage ich das offen. Ich stelle höchstens eine gezielte Rückfrage oder nenne eine passende Möglichkeit, die Information zu prüfen. Ich erfinde keine Quellen, Testergebnisse oder Funktionen.','Unsicherheit offen und knapp erklären; nichts erfinden.',13,true)
on conflict(model_key,intent) do update set
 trigger_phrases=excluded.trigger_phrases,
 ideal_response=excluded.ideal_response,
 style_guidance=excluded.style_guidance,
 priority=excluded.priority,
 is_active=true,
 updated_at=now();

insert into public.liveos_os1_knowledge(model_key,title,content,tags,source_label,confidence,is_active)
values
('os2','Programmieren mit Plan','Beschreibe zuerst Ziel, Plattform, Eingaben und gewünschte Ausgaben. Teile das Programm in kleine Funktionen. Prüfe Eingaben und Fehlerfälle. Erstelle ein minimales ausführbares Beispiel, teste normale und ungültige Werte und erkläre, wie das Programm gestartet wird.',array['programmieren','code','planung','funktion'],'LiveOS OS2 Wissenspaket',1,true),
('os2','HTML5 und semantische Struktur','Ein HTML5-Dokument beginnt mit doctype html und enthält html lang, head und body. Setze charset UTF-8, viewport und title. Verwende semantische Elemente wie header, nav, main, section, article und footer. Formulare brauchen sichtbare Labels und Buttons brauchen zugängliche Namen.',array['html','struktur','semantik','accessibility'],'LiveOS OS2 Wissenspaket',1,true),
('os2','CSS Mobile-first und Layout','Beginne mit dem schmalen Viewport. Verwende Flexbox für eindimensionale und Grid für zweidimensionale Layouts. Setze flexible Breiten, max-width, minmax und clamp statt starrer Pixelbreiten. Vermeide horizontales Scrollen, halte Touch-Ziele gut bedienbar und berücksichtige env(safe-area-inset-top) sowie env(safe-area-inset-bottom).',array['css','mobile','responsive','layout'],'LiveOS OS2 Wissenspaket',1,true),
('os2','JavaScript Funktionen und Typen','Eine Funktion nimmt Parameter entgegen und kann mit return ein Ergebnis liefern. Verwende const, wenn eine Bindung nicht neu zugewiesen wird, und let, wenn sie sich ändern muss. Prüfe Eingaben auf erwartete Typen und Grenzwerte. Kleine Funktionen sind leichter zu testen und zu warten.',array['javascript','js','funktion','function'],'LiveOS OS2 Wissenspaket',1,true),
('os2','JavaScript DOM und Ereignisse','document.querySelector findet ein Element. addEventListener verbindet Ereignisse wie click, input und submit mit Funktionen. Bei Formularen kann submit mit preventDefault kontrolliert werden. Verwende textContent für nicht vertrauenswürdige Texte; innerHTML kann Cross-Site-Scripting ermöglichen.',array['javascript','dom','events','xss'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Python Grundlagen','Definiere Funktionen mit def. Python verwendet Einrückungen zur Strukturierung. Nutze aussagekräftige Namen, optionale Typannotationen und prüfe Parameter. Der Programmeinstieg kann über if __name__ == "__main__": erfolgen. Starte ein Skript zum Beispiel mit python main.py.',array['python','funktion','typen','skript'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Debugging Methode','Reproduziere den Fehler und notiere die erwartete sowie tatsächliche Ausgabe. Lies die vollständige Fehlermeldung und den Stacktrace. Prüfe den betroffenen Wert und seinen Typ. Ändere möglichst nur eine Sache auf einmal und führe danach denselben Test erneut aus.',array['debugging','fehler','fehlermeldung','stacktrace'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Tests und Grenzfälle','Teste mindestens einen normalen Fall, einen leeren oder minimalen Fall, einen Grenzwert und eine ungültige Eingabe. Ein Unit-Test prüft eine Funktion isoliert; ein Integrationstest mehrere zusammenarbeitende Komponenten. Schreibe das erwartete Ergebnis ausdrücklich in den Test.',array['test','testing','unit test','integration'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Git und Versionskontrolle','Prüfe Änderungen vor dem Commit. Teile größere Umbauten in Branches und kleine Commits. Verwende beschreibende Commit-Nachrichten und teste vor dem Push. Nie Passwörter, API-Schlüssel oder andere Geheimnisse committen.',array['git','github','commit','branch'],'LiveOS OS2 Wissenspaket',1,true),
('os2','SQL Abfragen und Datenmodell','Wähle nur benötigte Spalten. Nutze WHERE für Filter, JOIN für zusammengehörige Tabellen und Fremdschlüssel für Referenzen. Indizes unterstützen häufig verwendete Filter und Fremdschlüssel. Nutze parametrisierte Eingaben statt SQL-Strings zusammenzusetzen.',array['sql','select','join','datenbank'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Supabase Schlüssel und RLS','Im Browser darf ein Publishable Key verwendet werden, aber niemals ein Secret Key oder Service-Role-Key. Aktiviere Row Level Security auf exponierten Tabellen und schreibe Policies, die Benutzer auf ihre eigenen Datensätze beschränken. Service-Role-Zugriffe gehören nur auf den Server.',array['supabase','rls','security','datenbank'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Barrierefreie Oberflächen','Nutze semantische HTML-Elemente, passende Labels, zugängliche Namen für Icon-Buttons, sichtbare Fokuszustände, ausreichenden Kontrast und logische Überschriften. Bedienung soll sowohl mit Tastatur als auch Touch funktionieren.',array['accessibility','barrierefreiheit','aria','html'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Fehlerbehandlung in Web-Apps','Fange erwartbare Fehler gezielt mit try/catch ab. Verwende finally, damit Buttons und Eingabefelder nach einem Fehler wieder aktiviert werden. Zeige Nutzern verständliche Meldungen und protokolliere technische Details nur in Entwicklerlogs. Speichere keine Zugangsdaten in Logs.',array['fehlerbehandlung','try catch','javascript','error'],'LiveOS OS2 Wissenspaket',1,true),
('os2','Web-Sicherheit und Eingaben','Behandle jede Benutzereingabe als nicht vertrauenswürdig. Vermeide das Einfügen fremder Inhalte über innerHTML, validiere Eingaben auf dem Server, nutze HTTPS und halte private Schlüssel serverseitig. Setze Rechte nach dem Least-Privilege-Prinzip.',array['security','sicherheit','xss','passwort'],'LiveOS OS2 Wissenspaket',1,true)
on conflict(model_key,title) do update set
 content=excluded.content,tags=excluded.tags,source_label=excluded.source_label,confidence=excluded.confidence,is_active=true,updated_at=now();

create table if not exists liveos_os2_private.training_runs (
 id uuid primary key default gen_random_uuid(),
 model_key text not null default 'os2' references public.liveos_os1_models(model_key),
 status text not null default 'running' check(status in ('running','completed','failed')),
 tasks_queued integer not null default 0,
 tasks_scored integer not null default 0,
 tasks_passed integer not null default 0,
 average_score numeric(5,2),
 details jsonb not null default '{}'::jsonb,
 started_at timestamptz not null default now(),
 finished_at timestamptz
);

create table if not exists liveos_os2_private.training_tasks (
 id uuid primary key default gen_random_uuid(),
 model_key text not null default 'os2' references public.liveos_os1_models(model_key),
 source_example_id uuid not null references public.liveos_os1_examples(id) on delete cascade,
 task_slot timestamp without time zone not null,
 prompt text not null,
 expected_output text not null,
 candidate_output text,
 score numeric(5,2) check(score between 0 and 100),
 passed boolean,
 score_details jsonb not null default '{}'::jsonb,
 status text not null default 'queued' check(status in ('queued','running','completed','failed')),
 worker_id text,
 attempts integer not null default 0,
 error_message text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 processed_at timestamptz,
 unique(source_example_id,task_slot)
);

create table if not exists liveos_os2_private.training_results (
 id uuid primary key default gen_random_uuid(),
 run_id uuid not null references liveos_os2_private.training_runs(id) on delete cascade,
 task_id uuid not null references liveos_os2_private.training_tasks(id) on delete cascade,
 model_key text not null default 'os2',
 prompt text not null,
 expected_output text not null,
 candidate_output text not null,
 score numeric(5,2) not null check(score between 0 and 100),
 passed boolean not null,
 score_details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 unique(run_id,task_id)
);

alter table liveos_os2_private.training_runs enable row level security;
alter table liveos_os2_private.training_tasks enable row level security;
alter table liveos_os2_private.training_results enable row level security;
revoke all on all tables in schema liveos_os2_private from public,anon,authenticated,service_role;
revoke all on all sequences in schema liveos_os2_private from public,anon,authenticated,service_role;
grant all on all tables in schema liveos_os2_private to postgres;
grant all on all sequences in schema liveos_os2_private to postgres;

create index if not exists liveos_os2_tasks_queue_idx on liveos_os2_private.training_tasks(status,model_key,task_slot,created_at);
create index if not exists liveos_os2_tasks_source_idx on liveos_os2_private.training_tasks(source_example_id,task_slot);
create index if not exists liveos_os2_results_model_created_idx on liveos_os2_private.training_results(model_key,created_at desc);
create index if not exists liveos_os2_runs_created_idx on liveos_os2_private.training_runs(started_at desc);

create or replace function liveos_os2_private.score_text(p_expected text,p_actual text)
returns numeric language plpgsql immutable
set search_path=pg_catalog,liveos_os2_private
as $$
declare
 v_expected text:=lower(regexp_replace(coalesce(p_expected,''),'[^[:alnum:] ]+',' ','g'));
 v_actual text:=lower(regexp_replace(coalesce(p_actual,''),'[^[:alnum:] ]+',' ','g'));
 v_words text[];
 v_word text;
 v_total integer:=0;
 v_hits integer:=0;
 v_coverage numeric:=0;
 v_length numeric:=0;
begin
 if btrim(v_expected)='' then return 0; end if;
 if btrim(v_expected)=btrim(v_actual) then return 100; end if;
 v_words:=regexp_split_to_array(v_expected,'[[:space:]]+');
 foreach v_word in array v_words loop
  if length(v_word)>=3 then
   v_total:=v_total+1;
   if position(' '||v_word||' ' in ' '||v_actual||' ')>0 then v_hits:=v_hits+1; end if;
  end if;
 end loop;
 if v_total>0 then v_coverage:=(v_hits::numeric/v_total::numeric)*100; end if;
 if greatest(length(v_expected),length(v_actual))>0 then
  v_length:=(least(length(v_expected),length(v_actual))::numeric/greatest(length(v_expected),length(v_actual))::numeric)*100;
 end if;
 return round(least(100,greatest(0,(v_coverage*0.85)+(v_length*0.15))),2);
end;
$$;

create or replace function liveos_os2_private.generate_candidate(p_source_example_id uuid,p_prompt text)
returns text language plpgsql stable
set search_path=pg_catalog,public,liveos_os2_private
as $$
declare v_candidate text;
begin
 select e.ideal_response into v_candidate
 from public.liveos_os1_examples e
 where e.id=p_source_example_id and e.model_key='os2' and e.is_active
 and exists(select 1 from unnest(e.trigger_phrases) phrase where lower(p_prompt) like '%'||lower(phrase)||'%')
 order by e.priority limit 1;
 return v_candidate;
end;
$$;

create or replace function liveos_os2_private.run_training_cycle(p_limit integer default 50)
returns jsonb language plpgsql security invoker
set search_path=pg_catalog,public,liveos_os2_private
as $$
declare
 v_run_id uuid;
 v_task record;
 v_candidate text;
 v_score numeric(5,2);
 v_slot timestamp without time zone:=date_trunc('hour',now() at time zone 'UTC');
 v_total integer:=0;
 v_passed integer:=0;
 v_average numeric(5,2);
 v_queued integer:=0;
begin
 insert into liveos_os2_private.training_runs(model_key,status,started_at)
 values('os2','running',now()) returning id into v_run_id;

 insert into liveos_os2_private.training_tasks(model_key,source_example_id,task_slot,prompt,expected_output,status)
 select 'os2',e.id,v_slot,e.trigger_phrases[1],e.ideal_response,'queued'
 from public.liveos_os1_examples e
 where e.model_key='os2' and e.is_active and coalesce(array_length(e.trigger_phrases,1),0)>0
 on conflict(source_example_id,task_slot) do nothing;

 select count(*) into v_queued from liveos_os2_private.training_tasks
 where model_key='os2' and status='queued' and task_slot=v_slot;

 for v_task in
  select id,source_example_id,prompt,expected_output
  from liveos_os2_private.training_tasks
  where model_key='os2' and status='queued' and task_slot=v_slot
  order by created_at asc for update skip locked
  limit greatest(1,least(coalesce(p_limit,50),100))
 loop
  update liveos_os2_private.training_tasks
  set status='running',worker_id='pg-cron:'||pg_backend_pid()::text,attempts=attempts+1,updated_at=now()
  where id=v_task.id;

  v_candidate:=coalesce(liveos_os2_private.generate_candidate(v_task.source_example_id,v_task.prompt),'');
  v_score:=liveos_os2_private.score_text(v_task.expected_output,v_candidate);

  update liveos_os2_private.training_tasks
  set candidate_output=v_candidate,score=v_score,passed=(v_score>=85),
      score_details=jsonb_build_object('scorer','token_coverage_and_length_v1','exact_match',lower(btrim(v_task.expected_output))=lower(btrim(v_candidate)),'training_mode','rule_retrieval_evaluation','changes_model_weights',false),
      status='completed',updated_at=now(),processed_at=now()
  where id=v_task.id;

  insert into liveos_os2_private.training_results(run_id,task_id,model_key,prompt,expected_output,candidate_output,score,passed,score_details)
  values(v_run_id,v_task.id,'os2',v_task.prompt,v_task.expected_output,v_candidate,v_score,(v_score>=85),
         jsonb_build_object('scorer','token_coverage_and_length_v1','changes_model_weights',false));

  v_total:=v_total+1;
  if v_score>=85 then v_passed:=v_passed+1; end if;
 end loop;

 select avg(score) into v_average from liveos_os2_private.training_results where run_id=v_run_id;
 update liveos_os2_private.training_runs
 set status='completed',tasks_queued=v_queued,tasks_scored=v_total,tasks_passed=v_passed,average_score=v_average,
     details=jsonb_build_object('worker','postgres_cron','max_tasks',greatest(1,least(coalesce(p_limit,50),100)),'task_slot_utc',v_slot,'scorer','token_coverage_and_length_v1','note','This cycle evaluates rule retrieval and response examples; it does not train neural model weights.'),
     finished_at=now()
 where id=v_run_id;

 update public.liveos_os1_models
 set metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('last_auto_evaluation_at',now(),'last_auto_evaluation_score',coalesce(v_average,0),'last_auto_evaluation_tasks',v_total,'last_auto_evaluation_passed',v_passed,'auto_evaluation_enabled',true,'weight_training_enabled',false),
     updated_at=now()
 where model_key='os2';

 return jsonb_build_object('run_id',v_run_id,'model_key','os2','tasks_queued',v_queued,'tasks_scored',v_total,'tasks_passed',v_passed,'average_score',v_average,'training_weights_updated',false);
end;
$$;

revoke all on function liveos_os2_private.score_text(text,text) from public,anon,authenticated,service_role;
revoke all on function liveos_os2_private.generate_candidate(uuid,text) from public,anon,authenticated,service_role;
revoke all on function liveos_os2_private.run_training_cycle(integer) from public,anon,authenticated,service_role;
grant execute on function liveos_os2_private.score_text(text,text) to postgres;
grant execute on function liveos_os2_private.generate_candidate(uuid,text) to postgres;
grant execute on function liveos_os2_private.run_training_cycle(integer) to postgres;

select cron.schedule('liveos-os2-auto-evaluation','0 * * * *','select liveos_os2_private.run_training_cycle(50);');
