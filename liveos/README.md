# LiveOS

Eigenständiger LiveOS-Bereich innerhalb der GitHub-Pages-Seite.

**Live:** https://urlaub-assistent.github.io/liveos/

## LiveOS OS1

OS1 ist die erste Modellgeneration der LiveOS-Familie. Spätere Modellgenerationen werden fortlaufend als OS2, OS3 usw. geführt.

### Erste Funktionen
- Weiße Oberfläche mit dunkelblauer LiveOS-Identität
- Chat ohne Anmeldung; Gesprächsverlauf lokal im Browser
- Einstellungen für Anzeigename, Antwortstil und lokalen Chatverlauf
- Erste Gesprächslogik mit Antwortbeispielen aus `liveos_os1_examples`
- Einfache Rechenaufgaben
- Wikipedia-Nachschlagen bei passenden Fragen
- Textgrafiken als PNG direkt im Browser erstellen

### Modellgrenzen
OS1 ist ein früher regel- und beispielbasierter Prototyp. Es ist **kein großes trainiertes Sprachmodell**, trainiert sich nicht automatisch anhand privater Chats und nutzt keine externe Chat-KI-API. Die Textgrafik-Funktion setzt Schrift und einfache Gestaltung im Browser zusammen; sie generiert noch keine fotorealistischen Motive.

## Datenbank

Die neue, von den alten Urlaub- und LiveOS-Strukturen getrennte OS1-Gruppe besteht aus:

- `liveos_os1_models` – Modellkatalog und Versionsnummern
- `liveos_os1_examples` – aktive Gesprächsbeispiele
- `liveos_os1_knowledge` – kuratierte Wissenseinträge
- `liveos_os1_conversations` und `liveos_os1_messages` – Grundlage für private Cloud-Chats
- `liveos_os1_user_settings` – Grundlage für Konto-Einstellungen
- `liveos_os1_datasets` und `liveos_os1_training_examples` – Trainingsdatensätze
- `liveos_os1_training_runs` und `liveos_os1_evaluations` – Trainings- und Testläufe
- `liveos_os1_releases` – Modellfreigaben

Alle Tabellen haben RLS. Der öffentliche Client kann nur den Modellkatalog und aktive Beispiele bzw. Wissenseinträge lesen. Private Trainingsbereiche sind auf den LiveOS-Owner beschränkt. Die Urlaubsassistent-Tabellen und alten Daten wurden nicht entfernt.

Die App wird zunächst ohne Anmeldung betrieben; deshalb verbleiben Chats und persönliche Einstellungen aktuell lokal auf dem Gerät. Die neuen Cloud-Tabellen sind die saubere Grundlage für die spätere optionale Kontosynchronisierung.


## OS1 Programming Pack

OS1 lädt zusätzlich einen kuratierten Programmier-Wissenssatz aus Supabase:

- HTML5-Dokumentstruktur und semantisches Markup
- Mobile-first CSS, Flexbox/Grid und Safe Areas
- JavaScript-Funktionen, DOM-Ereignisse und Eingabeprüfung
- Python-Funktionen und Programmeinstieg
- Debugging, Fehlerbehandlung und Tests
- Git-Arbeitsablauf
- SQL-Grundlagen und Supabase-RLS
- Websicherheit und Barrierefreiheit

Die Inhalte liegen in `liveos_os1_examples` und `liveos_os1_knowledge` und werden beim App-Start geladen. OS1 kann damit bereits einfache HTML-Webseiten, JavaScript-Funktionen, Python-Beispiele und einen einfachen HTML-Taschenrechner als Code ausgeben. Code wird im Chat als kopierbarer Codeblock dargestellt.

**Technische Grenze:** Das ist ein kuratierter Wissens-/Regel- und Vorlagenlayer, keine Anpassung neuronaler Modellgewichte. Für echtes Fine-Tuning oder ein großes eigenständiges Sprachmodell braucht es ein passendes Modell, Trainingsdaten und ausreichend GPU-Rechenleistung. Supabase speichert in dieser Architektur die Daten und Tests, führt aber nicht selbst das Modelltraining aus.


## LiveOS OS2

OS2 is registered as model generation 2 and is the default model in the chat. It loads its own curated examples and knowledge from the existing model registry/knowledge tables.

### Automated evaluation loop
- Supabase Cron schedules `liveos_os2_private.run_training_cycle(50)` once per hour.
- The loop queues an evaluation task for every active OS2 response example.
- Tasks are claimed with `FOR UPDATE SKIP LOCKED`, tagged with a worker ID, scored and stored in a private schema.
- The scorer combines expected-token coverage and response-length coverage. A result of 85 or higher passes.
- Run history, individual task scores and model evaluation metadata are stored in the database.
- The first manual cycle completed 13/13 rule-routing checks with a 100/100 average.

**Important model limit:** This automatic loop tests the OS2 example/retrieval rules. The SQL candidate generator currently routes prompts to curated OS2 examples; it does not generate free-form neural responses and does not update neural model weights. Real self-training or fine-tuning needs an actual open-weight model, an inference/training worker with compute (normally a GPU), and a model-artifact store. Supabase Cron currently automates the evaluation pipeline, not weight training.


## OS2 conversation and reward evaluation update

OS2 now handles whole-word intent matches. Short greetings such as `hi` must occur at the start of a message; they are not matched inside words such as `Lamborghini`. The conversation layer includes clarification for vehicle-price questions, empathetic replies, gratitude, follow-up questions, and explicit uncertainty for information it cannot observe.

### Reward scorer v2
The previous scorer copied the ideal response into the candidate and then compared the two. That circular comparison has been replaced.

- The 19-case benchmark set is stored in the private `liveos_os2_private.training_benchmarks` schema.
- Each benchmark has an immutable task specification and a digest. Task edits and digest mismatches receive **0 points**.
- Candidate responses are generated by a separate deterministic OS2 rule engine; the expected response/rubric is never copied into the candidate.
- Hidden required and forbidden assertions are evaluated independently.
- A solvable task earns 100 only when all assertions pass. Failure, task tampering, detected task-rewrite/cheating output, or an unsolvable task earns 0.
- The first v2 training cycle scored 19 tasks: 18 passed, one unanswerable task received 0, average 94.74/100.
- Explicit scorer tests confirmed correct arithmetic = 100, wrong arithmetic = 0, task rewrite = 0, altered digest = 0, unanswerable task = 0.
- Supabase Cron remains scheduled hourly.

**Important limitation:** This is automated improvement and evaluation of OS2's deterministic conversation/rule layer and curated examples. It still does not train neural model weights or turn the system into a general-purpose neural language model. That requires an actual model backend and separate training compute.

## LiveOS OS3 (current default)

OS3 is the current default model catalogue entry. It reuses the reviewed OS2 conversation/rule layer and the OS2 SkillNet v2 classifier, and adds a public-web research path:

- General public-web search via DuckDuckGo HTML results (no paid search API key).
- Read-only extraction of public HTML/text pages supplied by search or by URL.
- YouTube search for public watch/short links; public captions are included only when a caption track is exposed on the public page.
- Source URLs are printed in the answer and rendered as clickable links in chat.
- Public page text is treated as untrusted data, not as instructions to LiveOS.
- The reader rejects non-HTTP(S), localhost and common private-network URL ranges, follows only a small number of redirects, limits response sizes and applies a best-effort per-IP request limit.
- Only public content is in scope. The function does not sign into websites, bypass paywalls, access private accounts, download video/audio, or execute page scripts.

The Edge Function source is in `liveos/supabase/functions/liveos-web-research/index.ts` and is deployed to the existing Supabase project as `liveos-web-research` with JWT gateway verification disabled to allow the app's local guest mode. The function is read-only and uses a CORS origin allowlist for the current GitHub Pages and Netlify hosts plus the planned LiveOS GitHub Pages host. CORS is not an authentication boundary; the endpoint returns only public web content and applies a basic in-memory rate limit.

**Important OS3 limit:** the search/page reader does not create a generative language model. The answer composer currently selects and joins relevant page sentences (extractive summaries) and reuses deterministic OS2 rules and examples. OS2 SkillNet v2 remains a small intent classifier; it is not a general-purpose neural text generator and its classifier weights are not changed by web searches. Search-engine markup and public caption availability can change, and some sites may block automated reading, so results are best-effort rather than guaranteed complete.
