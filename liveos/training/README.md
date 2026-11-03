# LiveOS OS2 – kostenloses GPU-Training

## Was eingerichtet wurde
- Supabase hält den freigegebenen OS2-Trainingsdatensatz und die geheimen Benchmarks.
- Ein abgesicherter Worker-RPC ermöglicht ausschließlich `service_role` Zugriff.
- Das Notebook trainiert Qwen2.5-0.5B-Instruct mit LoRA auf einer Kaggle-GPU.
- LoRA-Adapter werden privat in deinem Hugging-Face-Konto gespeichert und beim nächsten Lauf als Startpunkt geladen.
- Supabase bewertet Antworten gegen versteckte Tests. Das Notebook erhält nur Punktzahl/Status, niemals Sollmuster oder Prüfkriterien.

## 0-Euro-Sicherheitsgrenze
Es werden keine bezahlten GPU-Anbieter, Inference-APIs oder kostenpflichtigen Endpoints verwendet. Kaggle-GPU-Zeit ist kostenlos, aber kontingentiert und nicht dauerhaft verfügbar. Das Notebook kann daher nicht garantiert ununterbrochen tagelang laufen. Nach dem Stop kann es mit dem zuletzt gespeicherten Adapter fortgesetzt werden.

## Einmalige Kaggle-Secrets
In Kaggle im Notebook unter **Add-ons → Secrets** zwei Secrets anlegen:
- `SUPABASE_SERVICE_ROLE_KEY`: den Legacy `service_role`-Schlüssel aus Supabase Project Settings → API Keys. Niemals öffentlich teilen.
- `HF_TOKEN`: Hugging Face User Access Token mit Schreibrecht für Model-Repositories. Niemals öffentlich teilen.

Die Supabase-Projekt-URL ist im Notebook bereits gesetzt: `https://twcacjwmahameglodljl.supabase.co`.

## Start
1. Die Datei `liveos/training/os2_kaggle_training.ipynb` herunterladen.
2. In Kaggle ein Notebook erstellen und die Notebook-Datei importieren.
3. Settings → Accelerator → GPU einstellen und Internet aktivieren.
4. Die beiden Secrets anlegen.
5. Zellen der Reihe nach ausführen.

Beim ersten Lauf wird ein privates HF-Repository `<dein-benutzername>/liveos-os2-lora` angelegt. Weitere Läufe laden den letzten Adapter und verbessern dessen Gewichte weiter.

## Aktueller Datensatz
Zum Zeitpunkt der Einrichtung liefert Supabase 17 aktive freigegebene Trainingsbeispiele und 19 aktive versteckte Benchmarks. Das ist ein erster technischer Trainingssatz, aber noch zu klein für ein leistungsstarkes Allzweckmodell. Weitere kuratierte Daten müssen folgen.

## Wichtige Grenze
Das Notebook erzeugt echte LoRA-Adaptergewichte. Das vorhandene LiveOS-Webfrontend hat jedoch noch kein Inference-Backend für diesen Adapter. Der erfolgreiche Trainingslauf allein macht OS2 also noch nicht automatisch im Live-Chat verfügbar. Dafür braucht es anschließend eine kostenlose Ausführungsstrategie, z. B. lokale Browser-Ausführung oder eine jeweils manuell gestartete kostenlose GPU-Session.
