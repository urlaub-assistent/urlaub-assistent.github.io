-- Cover the foreign keys of the dedicated OS1 tables.
create index if not exists liveos_os1_conversations_model_idx on public.liveos_os1_conversations(model_key);
create index if not exists liveos_os1_messages_conversation_owner_idx on public.liveos_os1_messages(conversation_id,user_id);
create index if not exists liveos_os1_messages_user_idx on public.liveos_os1_messages(user_id);
create index if not exists liveos_os1_messages_model_idx on public.liveos_os1_messages(model_key);
create index if not exists liveos_os1_datasets_user_idx on public.liveos_os1_datasets(user_id);
create index if not exists liveos_os1_training_examples_dataset_owner_idx on public.liveos_os1_training_examples(dataset_id,user_id);
create index if not exists liveos_os1_training_examples_user_idx on public.liveos_os1_training_examples(user_id);
create index if not exists liveos_os1_training_examples_model_idx on public.liveos_os1_training_examples(model_key);
create index if not exists liveos_os1_training_runs_model_idx on public.liveos_os1_training_runs(model_key);
create index if not exists liveos_os1_evaluations_run_owner_idx on public.liveos_os1_evaluations(run_id,user_id);
create index if not exists liveos_os1_evaluations_user_idx on public.liveos_os1_evaluations(user_id);
create index if not exists liveos_os1_releases_user_idx on public.liveos_os1_releases(user_id);
create index if not exists liveos_os1_releases_model_idx on public.liveos_os1_releases(model_key);
