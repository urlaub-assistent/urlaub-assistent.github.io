
create unique index if not exists liveos_os1_knowledge_model_title_uq
  on public.liveos_os1_knowledge(model_key,title);

update public.liveos_os1_models
set
  capabilities='["chat","basic_math","wikipedia_lookup","text_graphics","local_chat_history","programming_basics","html_css","javascript","python","debugging","code_examples","basic_testing"]'::jsonb,
  metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
    'skill_pack_version','programming-pack-1',
    'programming_languages',jsonb_build_array('HTML','CSS','JavaScript','Python','SQL'),
    'skill_topics',jsonb_build_array('responsive design','DOM','functions','debugging','testing','Git','Supabase security','accessibility'),
    'training_note','Curated examples and knowledge retrieval; no neural-weight fine-tuning performed.'
  ),
  updated_at=now()
where model_key='os1';

insert into public.liveos_os1_examples
  (model_key,intent,trigger_phrases,ideal_response,style_guidance,priority,is_active)
values
  ('os1','programming_general',array['kannst du programmieren','programmiere mir','schreib mir code','programmiere eine app','hilf mir beim programmieren'],'Ja. Ich kann dir bei HTML, CSS, JavaScript, Python und einfachen SQL-Aufgaben helfen. Beschreibe, was das Programm tun soll und wo es laufen wird. Ich liefere dir Code, erkläre die wichtigen Stellen und nenne Tests.','Erst Ziel und Plattform erfassen; vollständige, sichere und testbare Beispiele bevorzugen.',12,true),
  ('os1','programming_html',array['html struktur','html grundgeruest','html dokument','html seite'],'Ein HTML-Dokument braucht normalerweise doctype, html, head und body. In den head gehören Zeichensatz, Viewport und Titel. Der body enthält die sichtbaren Elemente.','Erkläre Struktur und Semantik; nutze moderne HTML5-Elemente.',13,true),
  ('os1','programming_css',array['css layout','responsive design','mobile first','handy layout'],'Für mobile Layouts ist Mobile-first sinnvoll: mit schmalen Bildschirmen beginnen, flexible Breiten wie min() oder max-width verwenden, Flexbox oder Grid einsetzen und bei Bedarf Media Queries ergänzen.','Keine festen Desktop-Breiten; Lesbarkeit, Touch-Flächen und Safe Areas beachten.',14,true),
  ('os1','programming_javascript',array['javascript funktion','js funktion','javascript code','dom javascript'],'JavaScript-Funktionen sollten klare Aufgaben haben, Eingaben prüfen und Ergebnisse zurückgeben. Für die Bedienoberfläche können Ereignisse wie click oder submit mit addEventListener verbunden werden.','Kleine Funktionen schreiben; keine Inline-Handler; Beispiele ausführbar halten.',15,true),
  ('os1','programming_python',array['python funktion','python code','python programm','python lernen'],'In Python werden Funktionen mit def definiert. Aussagekräftige Namen, Einrückung, Eingabeprüfung und kleine Tests helfen, Fehler früh zu entdecken.','Typannotationen bei verständlichen Beispielen zeigen; einfache Startbefehle ergänzen.',16,true),
  ('os1','programming_debugging',array['debugging','programmierfehler','fehlermeldung im code','code funktioniert nicht'],'Zum Debuggen brauche ich den relevanten Code, die genaue Fehlermeldung und eine kurze Beschreibung, was passieren sollte. Danach kann ich Ursache, Korrektur und einen Test nennen.','Keine Fehlerursache erfinden; nötige Informationen erfragen; Geheimnisse entfernen lassen.',17,true),
  ('os1','programming_testing',array['code testen','unit test','software testen','programm testen'],'Ein guter Test prüft normale Eingaben, Grenzfälle und ungültige Werte. Kleine Funktionen lassen sich einzeln testen; ein Test sollte erwartetes und tatsächliches Ergebnis vergleichen.','Tests mit konkreten Eingaben und erwarteten Resultaten zeigen.',18,true),
  ('os1','programming_git',array['git commit','github branch','git versionierung','git push'],'Ein sicherer Git-Ablauf ist: Änderungen prüfen, kleine thematische Commits erstellen, lokal testen und erst danach pushen. Vor einem größeren Umbau einen Branch anlegen.','Keine Zugangstokens in Quellcode committen; kleine Commits bevorzugen.',19,true),
  ('os1','programming_sql',array['sql abfrage','sql select','sql join','datenbank tabelle'],'SQL-Abfragen sollten nur benötigte Spalten auswählen, Fremdschlüssel sauber modellieren und bei privaten Daten Zugriffsrechte sowie Row Level Security berücksichtigen.','Keine SELECT * Beispiele für produktive Abfragen; Parameter statt SQL-Strings zusammenbauen.',20,true),
  ('os1','programming_supabase',array['supabase programmieren','supabase client','supabase rls','supabase datenbank code'],'Bei Supabase dürfen öffentliche Clients nur den Publishable Key verwenden. Der Secret Key gehört ausschließlich auf einen vertrauenswürdigen Server. Tabellen mit privaten Daten brauchen passende RLS-Policies.','Niemals Secret Keys oder Service-Role-Keys im Browser verwenden.',21,true),
  ('os1','programming_accessibility',array['barrierefreies html','accessibility','aria label','web barrierefreiheit'],'Verwende echte Buttons und Formulare, sichtbare Fokuszustände, passende Labels, ausreichenden Kontrast und sinnvolle Überschriften. Interaktive Elemente müssen auch mit Tastatur bedienbar sein.','Semantisches HTML vor ARIA bevorzugen; ARIA nur ergänzend nutzen.',22,true),
  ('os1','programming_security',array['javascript sicherheit','web sicherheit','xss verhindern','passwort im code'],'Behandle Nutzereingaben als nicht vertrauenswürdig. Setze fremde Inhalte nicht ungeprüft mit innerHTML ein, speichere keine Passwörter in JavaScript und halte geheime Schlüssel vom Browser fern.','Sichere Defaults und konkrete Risiken erklären.',23,true),
  ('os1','programming_error_handling',array['try catch javascript','fehlerbehandlung','error handling'],'Fehler sollten gezielt abgefangen und verständlich angezeigt werden. Im Log dürfen technische Details stehen, aber keine privaten Schlüssel. Nach einem Fehler muss die Oberfläche wieder bedienbar sein.','Nutzer verständlich informieren und Buttons im finally-Block zurücksetzen.',24,true),
  ('os1','programming_functions',array['was ist eine funktion programmieren','funktion erklären','function erklaeren'],'Eine Funktion bündelt einen wiederverwendbaren Arbeitsschritt. Sie erhält Eingaben als Parameter, verarbeitet sie und kann mit return ein Ergebnis zurückgeben.','Mit kleinem Beispiel und Ein-/Ausgabe erklären.',25,true)
on conflict (model_key,intent) do update set
  trigger_phrases=excluded.trigger_phrases,
  ideal_response=excluded.ideal_response,
  style_guidance=excluded.style_guidance,
  priority=excluded.priority,
  is_active=true,
  updated_at=now();

insert into public.liveos_os1_knowledge
  (model_key,title,content,tags,source_label,confidence,is_active)
values
  ('os1','Programmiergrundlagen','Gute Programme lösen eine klar beschriebene Aufgabe in kleinen, verständlichen Schritten. Benenne Variablen und Funktionen eindeutig, prüfe Eingaben, behandle Fehler und teste sowohl normale Fälle als auch Grenzfälle. Erkläre Annahmen und nenne, wie der Code ausgeführt wird.',array['programmieren','code','funktion','debugging'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','HTML-Grundstruktur','Ein HTML5-Dokument beginnt mit doctype html und enthält html lang=de, head und body. In den head gehören mindestens charset UTF-8, viewport und title. Verwende semantische Elemente wie main, header, nav, section und footer passend zu ihrer Bedeutung.',array['html','struktur','semantik'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','CSS Mobile-first','Beginne mit dem schmalen Bildschirm. Verwende flexible Layouts mit Flexbox oder Grid, max-width statt unnötig fester Breiten, ausreichend große Touch-Ziele und Media Queries für größere Bildschirme. Berücksichtige env(safe-area-inset-top) und env(safe-area-inset-bottom) bei randlosen Handy-Layouts.',array['css','mobile','responsive','layout'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','JavaScript-Funktionen','Eine JavaScript-Funktion bündelt einen Arbeitsschritt. Parameter sind Eingaben, return liefert ein Ergebnis. Prüfe Typen und Grenzwerte. Nutze addEventListener für Klick- und Formularereignisse. Verwende const standardmäßig und let nur, wenn eine Variable neu zugewiesen werden muss.',array['javascript','js','funktion','function'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','JavaScript-DOM','Mit document.querySelector findest du Elemente im DOM. addEventListener verbindet Ereignisse mit Funktionen. Für nicht vertrauenswürdige Texte ist textContent sicherer als innerHTML. Bei Formularen sollte submit mit preventDefault kontrolliert werden.',array['javascript','dom','events','html'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Python-Grundlagen','Python-Funktionen werden mit def definiert. Einrückung gehört zur Syntax. Verwende sprechende Namen, kleine Funktionen, optionale Typannotationen und einen Programmeinstieg über if __name__ == "__main__":. Teste Funktionen mit normalen und ungewöhnlichen Eingaben.',array['python','funktion','schleife','daten'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Debugging-Ablauf','Reproduziere den Fehler. Lies die komplette Fehlermeldung und notiere die betroffene Zeile. Prüfe Werte und Typen in der Nähe der Fehlerstelle. Ändere möglichst nur eine Sache auf einmal und teste anschließend den ursprünglichen Fehlerfall erneut.',array['debugging','fehler','fehlermeldung','test'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Tests und Qualität','Teste normale Eingaben, leere Werte, Grenzwerte und ungültige Eingaben. Ein Unit-Test prüft eine kleine Funktion isoliert. Ein Integrationstest prüft das Zusammenspiel mehrerer Teile. Ein Test sollte das erwartete Ergebnis ausdrücklich vergleichen.',array['test','testing','unit test','qualität'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Git-Arbeitsablauf','Prüfe Änderungen vor dem Commit. Verwende kurze, beschreibende Commit-Nachrichten. Trenne größere Arbeiten in Branches und kleine Commits. Teste vor dem Push. Committe niemals Passwörter, API-Schlüssel oder andere Geheimnisse.',array['git','github','commit','branch'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','SQL-Grundlagen','Nutze SELECT mit den benötigten Spalten, WHERE für Filter und JOIN für zusammengehörige Tabellen. Modellierte Fremdschlüssel sollten passende Indizes erhalten. Verwende parametrisierte Abfragen und beschränke den Datenzugriff nach dem Prinzip der geringsten Rechte.',array['sql','select','join','datenbank'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Supabase-Sicherheit','Der Publishable Key darf im Browser verwendet werden, wenn die Tabellen durch Row Level Security geschützt sind. Secret- und Service-Role-Keys gehören niemals in Frontend-Code. Policies müssen Lese- und Schreibrechte für jede Tabelle gezielt festlegen.',array['supabase','rls','security','datenbank'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Websicherheit','Vertraue niemals ungeprüften Nutzereingaben. Vermeide unsicheres innerHTML für fremde Inhalte, validiere Eingaben serverseitig, nutze HTTPS und speichere keine geheimen Schlüssel im Browser. Begrenze Berechtigungen auf das notwendige Minimum.',array['security','sicherheit','xss','passwort'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Barrierefreie Oberflächen','Verwende semantisches HTML, Labels für Formulare, zugängliche Namen für Icon-Buttons, sichtbare Tastaturfokusse, ausreichende Kontraste und logische Überschriften. Interaktive Bedienelemente sollten mindestens mit Tastatur und Touch funktionieren.',array['accessibility','barrierefreiheit','aria','html'],'LiveOS Programmier-Wissenspaket',1,true),
  ('os1','Fehlerbehandlung','Nutze try/catch für erwartbare Fehler und finally, um UI-Zustände wie deaktivierte Buttons sicher zurückzusetzen. Zeige Nutzern verständliche Meldungen. Schreibe technische Details nur in Entwicklerlogs und niemals Zugangsdaten.',array['error','fehler','try catch','javascript'],'LiveOS Programmier-Wissenspaket',1,true)
on conflict (model_key,title) do update set
  content=excluded.content,tags=excluded.tags,source_label=excluded.source_label,
  confidence=excluded.confidence,is_active=true,updated_at=now();
