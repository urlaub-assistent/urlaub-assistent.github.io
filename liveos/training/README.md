# LiveOS Training Engine

Die eigene LiveOS Training Engine läuft als lokale Webanwendung unter:

`https://urlaub-assistent.github.io/liveos/training/`

## Was sie macht
- Erzeugt deutschsprachige Übungsaufgaben automatisch aus dem internen Aufgabenpool.
- Ergänzt diesen Pool mit den aktiven, kuratierten OS2-Antwortbeispielen aus Supabase.
- Trainiert ein kleines neuronales MLP (128 Eingabefeatures → 32 Hidden-Neuronen → Intent-Klassen) mit Backpropagation und SGD direkt in einem JavaScript-Web-Worker auf dem Gerät.
- Prüft den Lernfortschritt auf getrennten, zurückgehaltenen Variationen.
- Vergibt 100 Reward-Punkte für korrekt klassifizierte Aufgaben und 0 für Fehlklassifikationen.
- Speichert die Gewichte lokal und synchronisiert Modellzustand und Laufhistorie nutzerbezogen in Supabase.
- Die Chat-App lädt denselben lokalen SkillNet-Checkpoint und verwendet ihn bei hoher Konfidenz als zusätzlichen Intent-Router zu vorhandenen, geprüften Antwortbeispielen.

## Trainingsziele
Das Freitextziel wird automatisch einem Themenbereich zugeordnet:
- Programmierung
- Mathematik
- Logik und Problemlösung
- Gespräche und Sprache
- Wissen und Erklärungen
- Sicherheit und Zuverlässigkeit
- Allgemeine Fähigkeiten

Der gewählte Bereich erhält die stärkere Trainingsgewichtung; andere Grundfähigkeiten werden weiter mittrainiert.

## Wichtige Grenzen
- Das ist ein echtes trainierbares neuronales Skill-/Intent-Modell, aber **kein vollständiges Sprachmodell**. Es lernt, Nutzeranfragen besser zu klassifizieren und vorhandene Antwortfähigkeiten gezielter aufzurufen. Es schreibt nicht eigenständig neue, beliebig lange Antworten wie ein großes LLM.
- Das Training läuft auf dem Gerät in einem Browser-Worker. Supabase speichert nur Zustand und Laufhistorie; es trainiert keine Modellgewichte auf dem Server.
- iPadOS kann Browser-Tabs im Hintergrund anhalten. Darum pausiert die Engine automatisch, wenn die Seite in den Hintergrund wechselt. Lass die Seite im Vordergrund, solange trainiert werden soll.
- Die Engine braucht für diese kleine MLP-Architektur keine GPU und verwendet keinen kostenpflichtigen API- oder GPU-Dienst.
- Die Validierung prüft die Skill-Klassifikation auf zurückgehaltenen Aufgabenvarianten. Das ist kein Beweis, dass die generative Sprachqualität insgesamt besser geworden ist.

## Daten & Datenschutz
- Es werden synthetische deutschsprachige Aufgaben und aktive, kuratierte OS2-Antwortbeispiele verwendet.
- Private Chatverläufe werden nicht als Trainingsdaten eingelesen.
- Modellzustand und Trainingsläufe werden mit Row Level Security an die jeweilige angemeldete User-ID gebunden.
- Keine Service-Role-Schlüssel im Browser.

## Start
1. Im LiveOS-Chat im Verlauf-Menü **Training Engine** wählen oder die Trainingsseite direkt öffnen.
2. Mit demselben LiveOS-Konto anmelden.
3. Ein Ziel eintippen oder einen Themen-Chip auswählen.
4. Dauer auswählen und **Training starten** drücken.
5. Während der Laufzeit diese Seite im Vordergrund geöffnet lassen.
6. Pause/Fortsetzen und Beenden verwenden; Checkpoints werden automatisch gespeichert.

## Datenbankschema
Das angewendete Schema ist in `sql/liveos_training_engine_schema.sql` dokumentiert.
