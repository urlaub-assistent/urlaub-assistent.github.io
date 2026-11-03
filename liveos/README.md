# LiveOS

Eigenständiger LiveOS-Web-App-Bereich.

Öffentliche Adresse: https://urlaub-assistent.github.io/liveos/

## Erste Funktionen
- Öffentliche Registrierung mit Supabase Auth
- Anmeldung und Passwort-Reset
- Private Chatverläufe je Benutzer mit Row Level Security
- Gesprächsbeispiele aus `liveos_response_examples`
- Internetrecherche über die öffentliche MediaWiki/Wikipedia-REST-API

## Grenzen
Die Antwortlogik ist beispiel- und regelbasiert. Die Formulierungsbeispiele sind kein trainiertes Sprachmodell und verändern keine Modellgewichte. Die aktuelle Websuche greift zunächst auf Wikipedia zu, nicht auf das gesamte offene Web.
