
create index if not exists liveos_os2_training_results_task_id_idx
  on liveos_os2_private.training_results(task_id);
create index if not exists liveos_os2_training_runs_model_key_idx
  on liveos_os2_private.training_runs(model_key);
create index if not exists liveos_os2_training_tasks_model_key_idx
  on liveos_os2_private.training_tasks(model_key);
