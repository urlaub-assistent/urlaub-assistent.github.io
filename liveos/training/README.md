# LiveOS OS2 — kostenloses GPU-Training

## Was eingerichtet wurde
- Supabase enthält freigegebene OS2-Trainingsbeispiele und private Benchmark-Aufgaben.
- Ein abgesicherter Worker-RPC stellt dem Kaggle-Notebook Trainingsbeispiele bereit.
- Versteckte Sollmuster und Scorer-Regeln verlassen Supabase nicht.
- Das Kaggle-Notebook trainiert echte LoRA-Adaptergewichte auf Qwen2.5-0.5B-Instruct.
- Ein privates Hugging-Face-Repository speichert den jeweils letzten Adapter.
- Adapter-Gewichte werden nach jeder abgeschlossenen Epoche auf Hugging Face synchronisiert und beim Folgelauf als Startpunkt geladen.

## Trainingsdaten im Notebook

1. **Beko2210/German-Instruct-Dataset** — CC-BY-4.0. Das Notebook filtert ausschließlich `language=de`, `pii_status=clean` und `quality_score >= 0.90`. Die Dataset-Seite nennt 8.013 Trainingszeilen im Train-Split; die tatsächlich übernommenen Beispiele hängen vom Filter ab.
2. **OpenAssistant/OASST-DE** — Apache-2.0. Enthält 3.721 deutschsprachige Konversationen; das Notebook extrahiert bis zu 3.500 Nutzer-/Assistenten-Turns.
3. **LiveOS OS2** — freigegebene, eigene Trainingsbeispiele aus Supabase.

Die Daten werden dedupliziert, gemischt und in Trainings- und Validierungsdaten geteilt. Obergrenze: 9.000 Paare pro Lauf, maximale Sequenzlänge 512 Token. Es werden keine privaten Chatverläufe aus deinem Urlaub Assistenten importiert.

Quellen:
- https://huggingface.co/datasets/Beko2210/German-Instruct-Dataset
- https://huggingface.co/datasets/OpenAssistant/OASST-DE
- https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct

## Belohnungs- und Scorer-Regeln
- Volle Aufgabenpunkte gibt es nur, wenn alle versteckten Assertions erfüllt sind.
- Bei einer tatsächlich unlösbaren Aufgabe erhält ein ehrlicher, klar formulierter sicherer Stopp ebenfalls volle Punkte.
- Ein manipuliertes Testsystem, veränderte Aufgaben, ausgelesene Lösungsschlüssel oder gefälschte Erfolge erhalten null Aufgabenpunkte und werden als Cheating markiert.
- Die versteckten Kriterien werden dem trainierenden Notebook nicht mitgegeben.
- Das ist derzeit SFT/LoRA-Fine-Tuning plus separate Bewertung, kein vollständiges Reinforcement-Learning mit GRPO/PPO.

## 0-Euro-Sicherheitsgrenze
Es werden keine bezahlten GPU-Anbieter, Inference-APIs oder kostenpflichtigen Endpoints verwendet. Kaggle-GPU-Zeit ist kostenlos, aber kontingentiert und nicht dauerhaft verfügbar. Eine laufende Kaggle-Session kann beendet werden; der letzte Adapter-Checkpoint kann danach erneut geladen werden. Ein durchgehender Lauf über Nacht ist nicht garantiert.

## Einmalige Kaggle-Secrets
In Kaggle im Notebook unter **Add-ons → Secrets** zwei Secrets anlegen:
- `SUPABASE_SERVICE_ROLE_KEY`: den Legacy `service_role`-Schlüssel aus Supabase Project Settings → API Keys. Niemals öffentlich teilen.
- `HF_TOKEN`: Hugging Face User Access Token mit Schreibrecht für Model-Repositories. Niemals öffentlich teilen.

Die Supabase-Projekt-URL ist im Notebook bereits gesetzt: `https://twcacjwmahameglodljl.supabase.co`.

## Start auf dem iPad
1. Notebook-Datei vom GitHub-Raw-Link herunterladen:
   https://raw.githubusercontent.com/urlaub-assistent/urlaub-assistent.github.io/main/liveos/training/os2_kaggle_training.ipynb
2. In Kaggle **File → Import Notebook** öffnen und die heruntergeladene `.ipynb`-Datei auswählen.
3. Settings → Accelerator → GPU einstellen und Internet aktivieren.
4. Die beiden Secrets anlegen.
5. Zellen der Reihe nach über **Run All** ausführen.

Beim ersten Lauf wird ein privates HF-Repository `<dein-benutzername>/liveos-os2-lora` angelegt. Weitere Läufe laden den letzten Adapter und trainieren dessen Gewichte weiter.

## Was ein erster Lauf leisten kann
Der Ausgangsdatensatz wächst damit von wenigen Dutzend eigenen Beispielen auf mehrere Tausend allgemeine deutschsprachige Instruktions- und Gesprächsbeispiele. Das verbessert die Trainingsbasis deutlich, garantiert aber keine starke Allzweck-KI über Nacht. Qwen2.5-0.5B-Instruct hat nur rund 0,5 Milliarden Parameter; LoRA passt einen kleinen Adapter an, trainiert nicht das gesamte Grundmodell neu.

## Wichtige Grenze
Das Notebook erzeugt echte LoRA-Adaptergewichte. Das vorhandene LiveOS-Webfrontend hat noch kein Inference-Backend für diesen Adapter. Der erfolgreiche Trainingslauf allein macht OS2 also noch nicht automatisch im Live-Chat verfügbar.
