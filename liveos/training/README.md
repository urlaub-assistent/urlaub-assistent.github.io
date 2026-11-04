# LiveOS OS2 Training Engine

LiveOS Training Engine: https://urlaub-assistent.github.io/liveos/training/

## Was sie tatsächlich trainiert

Die Engine trainiert einen kleinen, eigenen neuronalen **Intent-/Skill-Klassifikator** (128 Eingabefeatures → 32 Hidden-Neuronen → 19 Intent-Klassen) direkt im Browser-Web-Worker. Es handelt sich ausdrücklich **nicht** um ein generatives Sprachmodell und nicht um ein Fine-Tuning von Qwen/ChatGPT. Der trainierte SkillNet kann Nutzeranfragen robuster vorhandenen, kuratierten OS2-Fähigkeiten und geprüften Antwortbeispielen zuordnen. Die Chat-App lädt denselben Checkpoint aus Supabase und nutzt ihn als zusätzlichen Intent-Router, wenn die Vorhersage sicher genug ist.

## Bedienung

1. Mit demselben LiveOS-Konto wie im Chat anmelden (die Session wird auf derselben Domain geteilt). Gastmodus ist optional und speichert nur lokal.
2. Ein Thema in normaler Sprache in **Worauf soll OS2 trainieren?** eingeben, zum Beispiel „Python und JavaScript programmieren“, „Mathematik und Rechnen“, „Biologie und Naturwissenschaften“ oder ein eigenes Thema.
3. Trainingsdauer auswählen: 15 Minuten, 1, 3, 6 oder 12 Stunden oder bis zum manuellen Pausieren.
4. **Training starten** drücken. Es werden keine externen Prompt-Sammlungen benötigt.

## Aufgaben- und Lernpipeline

- Integrierter deutscher Aufgabenpool mit 19 Kompetenzklassen.
- Der Generator erzeugt aus jeder Aufgabe automatisch mehrere natürliche Formulierungen, darunter Bitten, Fragen, Schritt-für-Schritt-Anfragen und Hilfegesuche.
- Der freie Trainingsfokus erzeugt zusätzliche auf das Thema zugeschnittene Lern-/Analyseprompts und gewichtet passende Kompetenzbereiche stärker.
- Freigegebene OS2-Beispiele aus `public.liveos_os1_examples` werden ergänzt, sofern sie über die angemeldete Session lesbar sind.
- Training und Validierung werden auf getrennte Basisformulierungen verteilt; das Training bewertet nicht nur die Trainingsbeispiele.
- Der Worker verwendet Mini-Batches, Backpropagation, Gradient Clipping und eine abfallende Lernrate.
- Checkpoints werden lokal im Browser gespeichert; Supabase synchronisiert den Nutzer-Checkpoint und Laufhistorie.
- Der Chat verwendet den gleichen Checkpoint-Key `liveos_os2_skillnet_v1` und synchronisiert den neuesten Cloud-Stand beim Öffnen.
- Die Engine verarbeitet keine privaten Chatverläufe als Trainingsdaten.

## Belohnung und Bewertung

Der Reward ist aktuell eine nachvollziehbare Klassifikationsbelohnung: 100 Punkte bei richtiger Intent-Zuordnung, 0 Punkte bei falscher Zuordnung. Die getrennte Validierungsquote und der Validierungsverlust sind die Qualitätsmetriken. Es gibt derzeit kein PPO/GRPO, kein autonomes Reinforcement Learning mit einem generativen Modell und keine semantische Bewertung komplexer Antworten. Ein „Cheating“-Detektor für einen generativen Agenten ist daher nicht Teil dieses SkillNet-Kerns.

## Gerätebetrieb und Grenzen

- Das Training läuft lokal im Browser auf CPU in einem separaten JavaScript-Web-Worker; es benötigt weder Kaggle noch einen GPU-Anbieter oder eine kostenpflichtige API.
- Es kann mehrere Stunden laufen, solange der Browser-Tab aktiv bleibt und das Betriebssystem die Seite nicht anhält.
- Wenn Safari/iPadOS die Seite in den Hintergrund legt oder pausiert, stoppt die Engine sicher, speichert den letzten Checkpoint und kann nach erneutem Öffnen mit **Start** fortgesetzt werden. Wake Lock wird angefragt, sofern der Browser es unterstützt; das ist keine Garantie für einen ununterbrochenen Betrieb.
- Cloud-Checkpoint und Verlauf werden nutzerbezogen mit Supabase RLS geschützt.
- Das Budget bleibt bei 0 €; es werden keine bezahlten Endpoints oder APIs aufgerufen.

## Qualitätsziel

Die Engine soll den Intent-Router über wiederholte Läufe robuster machen und die Zuordnung von Nutzeranfragen zu den vorhandenen OS2-Fähigkeiten verbessern. Mehr Trainingsschritte oder eine höhere Validierungsquote bedeuten nicht automatisch, dass LiveOS ein besseres allgemeines Sprachmodell geworden ist. Für generative Sprachkompetenz wäre später ein separates Modell mit einem echten Inference- und Fine-Tuning-Backend erforderlich.
