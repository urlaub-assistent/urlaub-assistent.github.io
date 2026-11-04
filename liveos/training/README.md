# LiveOS OS3 Training Engine

Die Training Engine trainiert den gemeinsamen OS3-SkillNet-Intent-Router lokal im Browser. Der Chat und die Trainingsseite verwenden denselben Supabase-Checkpoint.

## Was das Training wirklich lernt

- Ein neuronaler Intent-Klassifikator mit 512 Eingabefeatures → 64 Hidden-Neuronen → 19 Klassen.
- Er ordnet Formulierungen vorhandenen LiveOS-Fähigkeitsbereichen zu, etwa Programmierung, Mathematik, Gespräch, Debugging und Sicherheit.
- Das Training erzeugt zusätzliche Formulierungen aus dem gewählten Lernfokus und ergänzt freigegebene Beispielphrasen.
- Es trainiert **kein** generatives Sprachmodell und schreibt dadurch nicht automatisch bessere freie Antworten oder Fakten in das Modell. Web-Recherche und Antwortregeln sind davon getrennte Funktionen.

## Verbesserte Lernpipeline

1. **Ausgewogene Auswahl:** Trainingsbeispiele werden stärker nach Kompetenzklasse ausgeglichen. Dadurch dominieren große Klassen nicht den ganzen Lauf.
2. **Stabileres Optimieren:** Mini-Batches, Backpropagation, Momentum, Label-Smoothing, Gradient Clipping und Weight Decay.
3. **Getrennte Prüfung:** Nach Trainingsabschnitten wird die Validierungsmenge ausgewertet. Die ausgewogene Validierungsquote berücksichtigt jede Klasse gleich.
4. **Beste Version sichern:** Ein Checkpoint wird nur übernommen, wenn die Validierung besser wird. Wenn fünf Prüfungen hintereinander keinen Fortschritt zeigen, stellt die Engine den besten Stand wieder her und senkt die Lernrate.
5. **Alte Stände übernehmen:** Die bisherigen OS2-Checkpoints werden in die OS3-Struktur migriert. Die ursprünglichen 512 Feature-Buckets bleiben erhalten; Momentum-Zustände starten bei alten Checkpoints zunächst bei null.

## Gemeinsamer Stand in LiveOS

- Jeder angemeldete LiveOS-Nutzer hat **einen** persönlichen Checkpoint in `public.liveos_training_engine_states`.
- Jeder neue Trainingslauf dieses Kontos startet mit dem vorhandenen Checkpoint und setzt das Training fort.
- Training und Chat lesen/schreiben denselben Checkpoint.
- Supabase Realtime meldet dem bereits geöffneten Chat neu gespeicherte Checkpoints desselben Kontos. Andere Benutzer können den Stand wegen Row Level Security nicht lesen.
- Alle Geräte mit demselben LiveOS-Login erhalten so denselben Modellstand. Gastmodus bleibt lokal und wird nicht mit der Cloud geteilt.
- Zwei Geräte sollten nicht gleichzeitig trainieren: Der gemeinsame Checkpoint wird als Ganzes gespeichert; parallele Läufe könnten sich gegenseitig überschreiben. Nacheinander gestartete Läufe bauen zuverlässig auf dem zuletzt synchronisierten Stand auf.

## Bewertung und Grenzen

Der Reward ist weiterhin eine einfache Klassifikationsbelohnung: 100 Punkte für eine richtige Intent-Zuordnung, 0 für eine falsche. Balanced Accuracy, Validierungsverlust und die Werte je Klasse sind aussagekräftiger als die Zahl der Trainingsschritte allein.

Es gibt kein PPO/GRPO und keinen generativen Agenten, der seine eigenen freien Antworten semantisch bewertet. Mehr Trainingsschritte oder eine höhere Intent-Quote machen LiveOS deshalb nicht automatisch zu einem allgemein intelligenteren Sprachmodell.

## Betrieb und Kosten

- Lokales CPU-Training in einem Web Worker, ohne bezahlte API und ohne GPU-Anbieter.
- Budget: 0 € zusätzliche Trainingskosten.
- Der Browser-Tab muss aktiv bleiben. Safari/iPadOS kann Hintergrund-Tabs oder gesperrte Geräte pausieren. In diesem Fall wird ein Checkpoint gespeichert und der Lauf kann nach dem Öffnen fortgesetzt werden.
- Private Chatverläufe werden nicht automatisch als Trainingsdaten verwendet.
