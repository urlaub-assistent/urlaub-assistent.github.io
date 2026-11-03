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
