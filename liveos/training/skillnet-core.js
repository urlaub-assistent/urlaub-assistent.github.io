(function (root) {
  "use strict";

  const FEATURE_COUNT = 512;
  const HIDDEN_COUNT = 64;
  const MODEL_KEY = "liveos-os3-skillnet-v3";
  const LEGACY_MODEL_KEYS = ["os2-skillnet-v2"];
  const STORAGE_KEY = "liveos_os3_skillnet_v3";
  const LEGACY_STORAGE_KEYS = ["liveos_os2_skillnet_v2"];

  const BANK = {
    greeting: [
      "hallo","hi","hey","guten morgen","guten tag","guten abend","moin","servus",
      "schön dich zu sehen","ich bin wieder da","na wie gehts","hallo liveos","hey liveos"
    ],
    identity: [
      "wer bist du","wie heißt du","wie ist dein name","bist du liveos","was bist du",
      "stell dich kurz vor","wer hat dich entwickelt","wie alt bist du","was bedeutet liveos"
    ],
    capabilities: [
      "was kannst du","wobei kannst du helfen","welche funktionen hast du","was kannst du alles",
      "kannst du mir helfen","was beherrschst du","was kannst du schon","was kann ich dich fragen"
    ],
    empathy: [
      "mir geht es nicht gut","ich bin traurig","ich bin gestresst","ich habe angst",
      "ich bin enttäuscht","ich fühle mich allein","heute war ein schlechter tag",
      "ich weiß nicht weiter","ich bin gerade frustriert","ich mache mir sorgen"
    ],
    gratitude: [
      "danke","vielen dank","danke dir","das war hilfreich","super danke",
      "du hast mir geholfen","vielen lieben dank","perfekt danke"
    ],
    followup: [
      "erzähl mir mehr","erklär das genauer","kannst du das vertiefen","mehr dazu",
      "was meinst du damit","gib mir ein beispiel","mach weiter","geh genauer darauf ein"
    ],
    programming_general: [
      "kannst du programmieren","hilf mir beim programmieren","ich möchte eine app entwickeln",
      "ich will eine website bauen","schreib mir code","wie fange ich mit coding an",
      "ich brauche hilfe mit code","entwickle eine kleine anwendung","programmiere etwas für mich"
    ],
    programming_html: [
      "erkläre mir html","wie ist html aufgebaut","erstelle eine html seite","ich brauche eine html datei",
      "was gehört in den body","wie baue ich ein formular in html","html grundstruktur",
      "wie füge ich einen button ein"
    ],
    programming_css: [
      "erkläre mir css","wie mache ich ein layout responsive","css grid erklären",
      "wie funktioniert flexbox","ändere die farben mit css","mein layout passt nicht aufs handy",
      "wie zentriere ich ein element","css abstände und größen"
    ],
    programming_javascript: [
      "erkläre mir javascript","wie verbinde ich einen button mit javascript",
      "schreibe eine javascript funktion","wie funktioniert add event listener",
      "wie speichere ich daten im browser","ich brauche javascript code",
      "wie prüfe ich eine eingabe in js","javascript click event"
    ],
    programming_python: [
      "erkläre mir python","schreibe eine python funktion","wie erstelle ich eine liste in python",
      "was bedeutet def in python","wie funktioniert eine schleife in python",
      "ich möchte python lernen","python code beispiel","wie lese ich eine datei mit python"
    ],
    debugging: [
      "mein code funktioniert nicht","hilf mir beim debuggen","ich habe einen bug",
      "ich bekomme eine fehlermeldung","warum stürzt mein programm ab","finde den fehler im code",
      "mein javascript wirft einen fehler","wie behebe ich diesen programmierfehler"
    ],
    testing: [
      "wie teste ich meinen code","schreibe tests für meine funktion","was sind grenzfälle",
      "wie prüfe ich ungültige eingaben","erkläre unit tests","wie teste ich eine website",
      "wie kann ich einen bug zuverlässig reproduzieren"
    ],
    security: [
      "wie verhindere ich xss","wie sichere ich eine website","was ist sql injection",
      "wie speichere ich passwörter sicher","wie schütze ich api schlüssel","erkläre row level security",
      "wie erkenne ich unsicheren code"
    ],
    supabase: [
      "wie verbinde ich supabase","hilf mir mit einer supabase datenbank","wie funktioniert supabase auth",
      "wie erstelle ich eine tabelle in supabase","wie sichere ich supabase mit rls",
      "wie nutze ich supabase im javascript","wie speichere ich daten in supabase"
    ],
    vehicle_price: [
      "was kostet ein lamborghini","wie teuer ist ein ferrari","was kostet ein porsche neu",
      "wie viel kostet ein bugatti","ich möchte einen sportwagen preis vergleichen",
      "was kostet ein urus","wie teuer ist ein gebrauchter lamborghini"
    ],
    unknown: [
      "welche münze halte ich gerade in der hand","was liegt gerade vor mir",
      "welche farbe hat mein zimmer","wie viele finger zeige ich gerade",
      "was denke ich gerade","wie ist das wetter direkt vor meinem haus ohne standort",
      "was steht auf einem zettel den du nicht sehen kannst","kannst du meine gedanken lesen"
    ],
    mathematics: [
      "rechne 17 mal 23","was ist 144 geteilt durch 12","wie viel ist 25 plus 37",
      "berechne 15 prozent von 80","löse eine einfache gleichung","erkläre mir bruchrechnung",
      "wie rechne ich einen prozentsatz aus","was ist 12 mal 14"
    ],
    reasoning: [
      "löse dieses logikrätsel","hilf mir bei einem schwierigen problem",
      "denke die aufgabe schritt für schritt durch","vergleiche zwei lösungswege",
      "was ist die sinnvollste lösung","erkenne einen widerspruch in diesem argument",
      "teile das problem in kleine schritte","erkläre deinen lösungsweg"
    ]
  };

  const FOCUS = {
    all: Object.keys(BANK),
    programming: ["programming_general","programming_html","programming_css","programming_javascript","programming_python","debugging","testing","security","supabase"],
    conversation: ["greeting","identity","capabilities","empathy","gratitude","followup"],
    mathematics: ["mathematics","reasoning"],
    reasoning: ["reasoning","debugging","testing","mathematics"],
    knowledge: ["vehicle_price","capabilities","identity","unknown","supabase"],
    safety: ["unknown","security","supabase"]
  };

  function normalize(value) {
    return String(value || "").toLowerCase().trim()
      .replace(/ä/g,"ae").replace(/ö/g,"oe").replace(/ü/g,"ue").replace(/ß/g,"ss")
      .normalize("NFD").replace(/[\u0300-\u036f]/g,"")
      .replace(/[^a-z0-9äöüß]+/g," ").replace(/\s+/g," ").trim();
  }

  function hash32(value) {
    let h = 2166136261;
    for (let i=0;i<value.length;i++) {
      h ^= value.charCodeAt(i);
      h = Math.imul(h,16777619);
    }
    return h >>> 0;
  }

  function vectorize(text) {
    const vector = new Float32Array(FEATURE_COUNT);
    const words = normalize(text).split(" ").filter(Boolean);
    const add = function (feature, weight) {
      const hash = hash32(feature);
      const index = hash % FEATURE_COUNT;
      const sign = (hash & 0x80000000) ? -1 : 1;
      vector[index] += sign * weight;
    };
    for (let i=0;i<words.length;i++) {
      add("w:"+words[i],1);
      if (i+1<words.length) add("b:"+words[i]+"_"+words[i+1],0.8);
      if (i+2<words.length) add("t:"+words[i]+"_"+words[i+1]+"_"+words[i+2],0.55);
      const token = "^"+words[i]+"$";
      for (let j=0;j<token.length-2;j++) add("c:"+token.slice(j,j+3),0.22);
    }
    let norm = 0;
    for (let i=0;i<vector.length;i++) norm += vector[i]*vector[i];
    norm = Math.sqrt(norm) || 1;
    for (let i=0;i<vector.length;i++) vector[i] /= norm;
    return vector;
  }

  function seededRandom(seed) {
    let state = (seed >>> 0) || 1;
    return function () {
      state = (Math.imul(state,1664525)+1013904223) >>> 0;
      return state / 4294967296;
    };
  }

  function createModel(existing) {
    const labels = Object.keys(BANK);
    const oldFeatureCount = existing && existing.b1 && existing.b1.length === HIDDEN_COUNT &&
      existing.w1 && existing.w1.length % HIDDEN_COUNT === 0
      ? existing.w1.length / HIDDEN_COUNT : 0;
    const compatible = existing &&
      (existing.modelKey === MODEL_KEY || LEGACY_MODEL_KEYS.includes(existing.modelKey)) &&
      JSON.stringify(existing.labels) === JSON.stringify(labels) &&
      oldFeatureCount > 0 && oldFeatureCount <= FEATURE_COUNT &&
      Array.isArray(existing.w2) && existing.w2.length === HIDDEN_COUNT * labels.length &&
      Array.isArray(existing.b1) && existing.b1.length === HIDDEN_COUNT &&
      Array.isArray(existing.b2) && existing.b2.length === labels.length;
    if (compatible) {
      const zeros = function (length) { return new Float32Array(length); };
      const migratedRows = function (values, oldWidth, newWidth, rows) {
        const output = zeros(newWidth * rows);
        if (!Array.isArray(values) || values.length !== oldWidth * rows) return output;
        for (let row = 0; row < rows; row++) {
          output.set(values.slice(row * oldWidth, (row + 1) * oldWidth), row * newWidth);
        }
        return output;
      };
      const arrayOrZeros = function (value, length) {
        return Array.isArray(value) && value.length === length ? Float32Array.from(value) : zeros(length);
      };
      return {
        modelKey: MODEL_KEY, labels,
        w1: migratedRows(existing.w1, oldFeatureCount, FEATURE_COUNT, HIDDEN_COUNT),
        b1: Float32Array.from(existing.b1),
        w2: Float32Array.from(existing.w2), b2: Float32Array.from(existing.b2),
        momentumW1: migratedRows(existing.momentumW1, oldFeatureCount, FEATURE_COUNT, HIDDEN_COUNT),
        momentumB1: arrayOrZeros(existing.momentumB1, HIDDEN_COUNT),
        momentumW2: arrayOrZeros(existing.momentumW2, HIDDEN_COUNT * labels.length),
        momentumB2: arrayOrZeros(existing.momentumB2, labels.length),
        steps: Number(existing.steps) || 0,
        examplesSeen: Number(existing.examplesSeen) || 0,
        bestAccuracy: Number(existing.bestAccuracy) || 0,
        version: 2
      };
    }
    const rand = seededRandom(20261104);
    const w1 = new Float32Array(FEATURE_COUNT * HIDDEN_COUNT);
    const w2 = new Float32Array(HIDDEN_COUNT * labels.length);
    for (let i = 0; i < w1.length; i++) w1[i] = (rand() - 0.5) * 0.06;
    for (let i = 0; i < w2.length; i++) w2[i] = (rand() - 0.5) * 0.08;
    return {
      modelKey: MODEL_KEY, labels, w1, b1: new Float32Array(HIDDEN_COUNT),
      w2, b2: new Float32Array(labels.length),
      momentumW1: new Float32Array(w1.length),
      momentumB1: new Float32Array(HIDDEN_COUNT),
      momentumW2: new Float32Array(w2.length),
      momentumB2: new Float32Array(labels.length),
      steps: 0, examplesSeen: 0, bestAccuracy: 0, version: 2
    };
  }

  function softmax(logits) {
    let max=-Infinity;
    for (let i=0;i<logits.length;i++) if (logits[i]>max) max=logits[i];
    let sum=0;
    const out=new Float32Array(logits.length);
    for(let i=0;i<logits.length;i++){out[i]=Math.exp(Math.max(-40,logits[i]-max));sum+=out[i];}
    if(!sum)sum=1;
    for(let i=0;i<out.length;i++)out[i]/=sum;
    return out;
  }

  function forward(model,vector) {
    const hidden=new Float32Array(HIDDEN_COUNT);
    for(let h=0;h<HIDDEN_COUNT;h++){
      let value=model.b1[h];
      const offset=h*FEATURE_COUNT;
      for(let i=0;i<FEATURE_COUNT;i++) value+=model.w1[offset+i]*vector[i];
      hidden[h]=value>0?value:0;
    }
    const logits=new Float32Array(model.labels.length);
    for(let c=0;c<model.labels.length;c++){
      let value=model.b2[c];
      for(let h=0;h<HIDDEN_COUNT;h++) value+=model.w2[h*model.labels.length+c]*hidden[h];
      logits[c]=value;
    }
    return {hidden,probs:softmax(logits)};
  }

  function predict(model,text) {
    if(!model)return null;
    const result=forward(model,vectorize(text));
    let best=0,second=0;
    for(let i=0;i<result.probs.length;i++){
      if(result.probs[i]>result.probs[best]){second=best;best=i;}
      else if(i!==best&&result.probs[i]>result.probs[second])second=i;
    }
    return {
      label:model.labels[best],
      confidence:Number(result.probs[best].toFixed(4)),
      secondLabel:model.labels[second],
      secondConfidence:Number(result.probs[second].toFixed(4))
    };
  }

  function variants(phrase) {
    const clean=String(phrase||"").trim().replace(/[?.!]+$/,"");
    if(!clean)return [];
    const v=[
      clean+"?",
      "bitte "+clean+"?",
      "kannst du mir sagen: "+clean+"?",
      "ich brauche hilfe: "+clean,
      "ich moechte wissen: "+clean+"?",
      "kannst du bitte "+clean+"?",
      "hilf mir bitte: "+clean,
      "erklaere mir bitte "+clean+" mit einem beispiel",
      "ich komme bei folgendem thema nicht weiter: "+clean,
      "wie gehe ich dabei am besten vor: "+clean,
      "fuehre mich schritt fuer schritt durch: "+clean,
      "ich moechte das besser verstehen: "+clean
    ];
    return Array.from(new Set(v.map(x=>x.replace(/\s+/g," ").trim())));
  }

  // Turn the user's plain-language training goal into a small, deterministic
  // curriculum. These are intent-learning examples, not factual knowledge.
  function focusedExamples(focusText) {
    const raw=String(focusText||"").trim();
    const t=normalize(raw);
    const rows=[];
    const add=(label,phrases)=>phrases.forEach(text=>rows.push({intent:label,trigger_phrases:[text]}));
    if(!t||/allgemein|allround|alle bereiche|alles/.test(t))return rows;
    const subject=raw.replace(/[?.!]+$/,"").slice(0,70);
    if(/python/.test(t)){
      add("programming_python",[
        "Schreibe eine Python-Funktion zum Thema "+subject,
        "Erkläre "+subject+" in Python mit einem kleinen Beispiel",
        "Debugge diesen Python-Code zu "+subject,
        "Wie teste ich eine Python-Lösung für "+subject,
        "Welche Python-Datenstruktur passt zu "+subject
      ]);
    }else if(/javascript|typescript|react|node|webentwicklung|frontend/.test(t)){
      add("programming_javascript",[
        "Erkläre "+subject+" in JavaScript mit Beispiel",
        "Schreibe eine JavaScript-Funktion für "+subject,
        "Debugge einen Fehler bei "+subject,
        "Wie teste ich JavaScript-Code zu "+subject,
        "Wie baue ich eine wiederverwendbare Komponente für "+subject
      ]);
    }else if(/html|css|website|webseite|design|layout/.test(t)){
      add(/css|layout|design/.test(t)?"programming_css":"programming_html",[
        "Erstelle eine responsive Seite zum Thema "+subject,
        "Erkläre die HTML-Struktur für "+subject,
        "Wie gestalte ich "+subject+" mobilfreundlich",
        "Finde den Layoutfehler bei "+subject,
        "Wie baue ich ein barrierearmes Formular für "+subject
      ]);
    }else if(/sql|supabase|datenbank|postgres/.test(t)){
      add("supabase",[
        "Entwirf ein sicheres Datenbankschema für "+subject,
        "Wie speichere ich "+subject+" in Supabase",
        "Erkläre Row Level Security für "+subject,
        "Schreibe eine SQL-Abfrage zu "+subject,
        "Wie teste ich Datenbankzugriffe für "+subject
      ]);
    }else if(/mathe|mathematik|rechnen|algebra|geometrie|prozent/.test(t)){
      add("mathematics",[
        "Erkläre "+subject+" Schritt für Schritt",
        "Gib mir eine Übungsaufgabe zu "+subject,
        "Prüfe meinen Rechenweg zu "+subject,
        "Welche Formel brauche ich für "+subject,
        "Zeige mir ein einfaches Beispiel zu "+subject
      ]);
    }else if(/logik|reasoning|problemlos|analyse|schlussfolger|kritisch denken/.test(t)){
      add("reasoning",[
        "Analysiere dieses Problem zu "+subject,
        "Teile "+subject+" in überprüfbare Teilschritte",
        "Vergleiche zwei Lösungswege für "+subject,
        "Finde mögliche Widersprüche bei "+subject,
        "Prüfe, welche Annahmen für "+subject+" fehlen"
      ]);
    }else if(/gespraech|kommunikation|deutsch|schreiben|sprache|empath/.test(t)){
      add("conversation",[
        "Führe ein natürliches Gespräch über "+subject,
        "Erkläre "+subject+" in einfachem, freundlichem Deutsch",
        "Formuliere eine klare Nachricht zu "+subject,
        "Reagiere einfühlsam auf eine Frage zu "+subject,
        "Fasse "+subject+" verständlich zusammen"
      ]);
    }else if(/sicherheit|security|datenschutz|privacy|schutz/.test(t)){
      add("security",[
        "Prüfe "+subject+" auf Sicherheitsrisiken",
        "Wie schütze ich Nutzerdaten bei "+subject,
        "Welche typischen Angriffe gibt es bei "+subject,
        "Erstelle eine Sicherheitscheckliste für "+subject,
        "Wie teste ich "+subject+" auf Schwachstellen"
      ]);
    }else{
      const resolved=resolveFocus(raw);
      const targetLabel=resolved.key==="knowledge"?"capabilities":"reasoning";
      add(targetLabel,[
        "Erkläre die Grundlagen von "+subject,
        "Welche Teilfragen muss ich zu "+subject+" zuerst klären",
        "Erstelle einen Lernplan für "+subject,
        "Prüfe eine Lösung zu "+subject+" auf Fehler",
        "Fasse die wichtigsten Punkte zu "+subject+" zusammen"
      ]);
    }
    return rows;
  }

  function buildDataset(focusText,curatedExamples) {
    const focusKey=resolveFocus(focusText).key;
    const mergedBank={};
    Object.keys(BANK).forEach(function(label){mergedBank[label]=BANK[label].slice();});
    focusedExamples(focusText).forEach(function(example){
      const label=String(example.intent||"");
      if(mergedBank[label])mergedBank[label].push.apply(mergedBank[label],example.trigger_phrases||[]);
    });
    (Array.isArray(curatedExamples)?curatedExamples:[]).forEach(function(example){
      const label=String(example.intent||"");
      if(!mergedBank[label])return;
      (Array.isArray(example.trigger_phrases)?example.trigger_phrases:[]).forEach(function(phrase){
        const clean=String(phrase||"").trim();
        if(clean&&clean.length>=3)mergedBank[label].push(clean);
      });
    });
    const train=[],validation=[];
    Object.keys(mergedBank).forEach(function(label){
      const phrases=Array.from(new Set(mergedBank[label]));
      phrases.forEach(function(phrase,index){
        const target=(index%5===0)?validation:train;
        variants(phrase).forEach(function(text){
          target.push({text,label});
        });
      });
    });
    const seen=new Set();
    const dedupe=function(rows){
      return rows.filter(function(row){
        const key=normalize(row.text)+"::"+row.label;
        if(seen.has(key))return false;
        seen.add(key);return true;
      });
    };
    const cleanTrain=dedupe(train);
    const cleanValidation=dedupe(validation);
    return {
      train:cleanTrain,
      validation:cleanValidation,
      focusKey,
      focusLabels:FOCUS[focusKey]||FOCUS.all
    };
  }

  function resolveFocus(value) {
    const t=normalize(value);
    if(!t||/allround|allgemein|alles|gesamt|alle bereiche/.test(t))return {key:"all",name:"Allgemeine Fähigkeiten"};
    if(/programm|coding|code|html|css|javascript|typescript|python|react|node|rust|java|c\+\+|website|webseite|app entwickeln|webentwicklung|frontend/.test(t))return {key:"programming",name:"Programmierung"};
    if(/mathe|mathematik|rechnen|zahlen|formel|algebra|geometrie|prozent/.test(t))return {key:"mathematics",name:"Mathematik"};
    if(/logik|reasoning|problemlos|problemloes|analysier|denken|schlussfolger/.test(t))return {key:"reasoning",name:"Logik und Problemlösung"};
    if(/gespraech|kommunikation|deutsch|smalltalk|empath|konversation|schreiben/.test(t))return {key:"conversation",name:"Gespräche und Sprache"};
    if(/wissen|fakten|allgemeinwissen|recherche|erkl[aä]r|biologie|geschichte|physik|chemie/.test(t))return {key:"knowledge",name:"Wissen und Erklärungen"};
    if(/sicherheit|security|datenschutz|schutz|privacy/.test(t))return {key:"safety",name:"Sicherheit und Zuverlässigkeit"};
    return {key:"all",name:"Allgemeine Fähigkeiten",custom:String(value||"").trim()};
  }

  function sampleOne(list,random) {
    return list[Math.floor(random()*list.length)];
  }

  function trainBatch(model, batch, learningRate) {
    const n = model.labels.length;
    const gradW1 = new Float32Array(model.w1.length);
    const gradB1 = new Float32Array(model.b1.length);
    const gradW2 = new Float32Array(model.w2.length);
    const gradB2 = new Float32Array(model.b2.length);
    const labelSmoothing = 0.02;
    let loss = 0, correct = 0, reward = 0, used = 0;
    for (let s = 0; s < batch.length; s++) {
      const item = batch[s], target = model.labels.indexOf(item.label);
      if (target < 0) continue;
      used++;
      const x = vectorize(item.text), f = forward(model, x);
      const probs = f.probs, hidden = f.hidden;
      let predicted = 0;
      for (let c = 1; c < n; c++) if (probs[c] > probs[predicted]) predicted = c;
      const right = predicted === target;
      if (right) { correct++; reward += 100; }
      const otherTarget = labelSmoothing / Math.max(1, n - 1);
      const delta2 = new Float32Array(n);
      for (let c = 0; c < n; c++) {
        const desired = c === target ? 1 - labelSmoothing : otherTarget;
        loss -= desired * Math.log(Math.max(1e-8, probs[c]));
        delta2[c] = probs[c] - desired;
        gradB2[c] += delta2[c];
      }
      for (let h = 0; h < HIDDEN_COUNT; h++) {
        const base = h * n;
        for (let c = 0; c < n; c++) gradW2[base + c] += hidden[h] * delta2[c];
      }
      for (let h = 0; h < HIDDEN_COUNT; h++) {
        let delta = 0;
        for (let c = 0; c < n; c++) delta += model.w2[h * n + c] * delta2[c];
        if (hidden[h] <= 0) delta = 0;
        gradB1[h] += delta;
        const base = h * FEATURE_COUNT;
        for (let i = 0; i < FEATURE_COUNT; i++) gradW1[base + i] += delta * x[i];
      }
    }
    const scale = 1 / Math.max(1, used);
    const grads = [gradW1, gradB1, gradW2, gradB2];
    let normSquared = 0;
    for (const grad of grads) for (let i = 0; i < grad.length; i++) {
      grad[i] *= scale;
      normSquared += grad[i] * grad[i];
    }
    const norm = Math.sqrt(normSquared) || 1;
    const clip = norm > 3 ? 3 / norm : 1;
    const momentum = 0.88, weightDecay = 0.000025;
    for (let i = 0; i < model.w1.length; i++) {
      model.momentumW1[i] = momentum * model.momentumW1[i] + gradW1[i] * clip;
      model.w1[i] -= learningRate * (model.momentumW1[i] + weightDecay * model.w1[i]);
    }
    for (let i = 0; i < model.b1.length; i++) {
      model.momentumB1[i] = momentum * model.momentumB1[i] + gradB1[i] * clip;
      model.b1[i] -= learningRate * model.momentumB1[i];
    }
    for (let i = 0; i < model.w2.length; i++) {
      model.momentumW2[i] = momentum * model.momentumW2[i] + gradW2[i] * clip;
      model.w2[i] -= learningRate * (model.momentumW2[i] + weightDecay * model.w2[i]);
    }
    for (let i = 0; i < model.b2.length; i++) {
      model.momentumB2[i] = momentum * model.momentumB2[i] + gradB2[i] * clip;
      model.b2[i] -= learningRate * model.momentumB2[i];
    }
    model.steps++; model.examplesSeen += used;
    return { loss: loss / Math.max(1, used), accuracy: correct / Math.max(1, used), reward: reward / Math.max(1, used), used };
  }

  function evaluate(model, rows) {
    let correct = 0, loss = 0, scored = 0;
    const perClass = {};
    rows.forEach(function (item) {
      const idx = model.labels.indexOf(item.label);
      if (idx < 0) return;
      const prediction = predict(model, item.text);
      const probabilities = forward(model, vectorize(item.text)).probs;
      const desired = 0.98, other = 0.02 / Math.max(1, model.labels.length - 1);
      for (let c = 0; c < probabilities.length; c++) {
        loss -= (c === idx ? desired : other) * Math.log(Math.max(1e-8, probabilities[c]));
      }
      const isCorrect = prediction && prediction.label === item.label;
      if (isCorrect) correct++;
      if (!perClass[item.label]) perClass[item.label] = { total: 0, correct: 0, accuracy: 0 };
      perClass[item.label].total++;
      if (isCorrect) perClass[item.label].correct++;
      scored++;
    });
    let classScore = 0, classCount = 0;
    Object.keys(perClass).forEach(function (label) {
      const item = perClass[label];
      item.accuracy = item.correct / Math.max(1, item.total);
      classScore += item.accuracy;
      classCount++;
    });
    return {
      accuracy: correct / Math.max(1, scored),
      balancedAccuracy: classScore / Math.max(1, classCount),
      loss: loss / Math.max(1, scored),
      count: scored, classes: classCount, perClass
    };
  }

  function serialize(model) {
    return {
      modelKey: MODEL_KEY, labels: model.labels,
      w1: Array.from(model.w1), b1: Array.from(model.b1),
      w2: Array.from(model.w2), b2: Array.from(model.b2),
      momentumW1: Array.from(model.momentumW1 || []),
      momentumB1: Array.from(model.momentumB1 || []),
      momentumW2: Array.from(model.momentumW2 || []),
      momentumB2: Array.from(model.momentumB2 || []),
      steps: model.steps, examplesSeen: model.examplesSeen,
      bestAccuracy: model.bestAccuracy, version: 2, savedAt: new Date().toISOString()
    };
  }

  function getStoredModel() {
    try {
      const storage = root.localStorage;
      if (!storage) return null;
      let raw = storage.getItem(STORAGE_KEY);
      if (!raw) {
        for (let i = 0; i < LEGACY_STORAGE_KEYS.length && !raw; i++) raw = storage.getItem(LEGACY_STORAGE_KEYS[i]);
      }
      if (!raw) return null;
      const model = createModel(JSON.parse(raw));
      if (model.modelKey === MODEL_KEY) storage.setItem(STORAGE_KEY, JSON.stringify(serialize(model)));
      return model;
    } catch (_) { return null; }
  }

  root.LiveOSSkillNet = {
    FEATURE_COUNT,HIDDEN_COUNT,MODEL_KEY,LEGACY_MODEL_KEYS,LEGACY_STORAGE_KEYS,STORAGE_KEY,BANK,FOCUS,
    normalize,vectorize,createModel,predict,buildDataset,resolveFocus,
    trainBatch,evaluate,serialize,getStoredModel
  };
})(typeof window!=="undefined"?window:self);
