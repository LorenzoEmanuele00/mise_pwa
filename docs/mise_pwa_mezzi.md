# Vehicle Management App — Documento di Progetto

> **Stato documento:** 🟢 In sviluppo attivo
> **Ultima modifica:** 2026-06-16
> **Versione:** 0.6.0
> **Package Flutter:** `mise_pwa` (progetto già scaffoldato)

---

## 1. Panoramica del Progetto

### Descrizione

App per la gestione del parco mezzi di un'associazione di volontariato. L'associazione possiede vari tipi di veicoli: ambulanze, mezzi attrezzati per il trasporto in carrozzina e autovetture.

### Obiettivo

Fornire uno strumento installabile su qualsiasi dispositivo (smartphone, tablet, desktop) che permetta a chiunque nell'associazione di tracciare lo stato dei mezzi e le manutenzioni effettuate.

### Decisioni Architetturali Chiave

| Decisione | Scelta | Motivazione |
|---|---|---|
| **Distribuzione** | Flutter PWA su **Firebase Hosting** | Un solo deploy, funziona su tutti i dispositivi, aggiornamenti automatici |
| **Autenticazione** | Supabase Auth con account condiviso | Un unico login per tutta l'associazione — nessuna gestione utenti, solo protezione accesso |
| **Pagina web** | L'URL è l'app stessa | Non esiste una landing separata — chi apre l'URL accede direttamente all'app |
| **Installazione** | Banner PWA nativo del browser | Il browser propone automaticamente "Aggiungi alla schermata home" / "Installa" |

> ℹ️ **Nota sull'host (cambiato da Vercel a Firebase Hosting in v0.4.0).** Vedi §11 per il
> confronto. In breve: nessun host statico compila Flutter da solo, ma Firebase Hosting offre il
> miglior rapporto con Flutter web (rewrite SPA in una riga, free tier ampio, dominio gratuito) e
> **non** ha la clausola "solo uso non commerciale" del piano Hobby di Vercel.

---

## 2. Come Funziona la Distribuzione

Quando un volontario va su `https://<progetto>.web.app` (o sul futuro dominio custom):

1. Vede direttamente la schermata di login dell'app
2. Inserisce le credenziali condivise dell'associazione
3. Accede all'app
4. Il browser (su Chrome/Edge/Safari mobile) mostra automaticamente il banner per installarla come PWA

**Non esiste una pagina di download separata.** L'URL è l'app. L'installazione PWA è opzionale — l'app funziona ugualmente nel browser senza installarla.

### Compatibilità Installazione PWA

| Piattaforma | Installazione | Note |
|---|---|---|
| **Android (Chrome)** | ✅ Banner automatico | Funziona perfettamente |
| **iOS (Safari)** | ✅ Condividi → "Aggiungi a schermata Home" | Vedi limiti noti §12 |
| **Windows (Chrome/Edge)** | ✅ Icona nella barra URL | Si apre in finestra dedicata |
| **macOS (Chrome)** | ✅ Icona nella barra URL | Come Windows |
| **macOS (Safari)** | ⚠️ Non installabile | Usabile solo da browser, senza installazione |

---

## 3. Stack Tecnologico

| Layer | Tecnologia | Note |
|---|---|---|
| **Frontend / App** | Flutter (Dart) — package `mise_pwa` | Build web con target PWA |
| **Autenticazione** | Supabase Auth | Un solo account condiviso per l'associazione |
| **Database** | Supabase (PostgreSQL) | RLS attiva, accessibile solo da utenti autenticati |
| **Hosting** | **Firebase Hosting** | Serve i file statici `build/web` (CDN + SSL) |
| **CI/CD** | GitHub Actions | Build `flutter build web` + deploy a Firebase su push a `main` |
| **State management** | Riverpod | |
| **Routing** | go_router | `usePathUrlStrategy()` per URL puliti |

> ⚠️ **Vincolo di build:** nessun host statico (Firebase, Cloudflare, Vercel, GitHub Pages) ha il
> Flutter SDK nella propria immagine di build. Flutter va **sempre** compilato in CI o in locale, e
> si carica l'output della cartella `build/web`. Firebase Hosting riceve quindi file già pronti.

---

## 4. Autenticazione

### Strategia

Un **unico account condiviso** per tutta l'associazione:

- Email: es. `mezzi@associazione.it`
- Password: condivisa tra i volontari autorizzati
- Nessuna registrazione, nessun profilo utente, nessuna gestione ruoli
- Supabase Auth protegge il database: senza login non si accede a nessun dato

### Come è davvero protetto il database (correzione v0.4.0)

> ❗ **La `anon key` di Supabase è sempre pubblica, per design.** In qualsiasi app client (Flutter,
> React, ecc.) la anon key finisce nel bundle scaricato dal browser e non può essere nascosta
> compilando il codice. Non è quindi un segreto.

La sicurezza dei dati **non** dipende dal nascondere la anon key, ma da **tre** misure combinate:

1. **Row Level Security (RLS) attiva** su tutte le tabelle (vedi §7) → senza un JWT valido nessuna riga è leggibile/scrivibile.
2. **Obbligo di login**: solo chi possiede le credenziali condivise ottiene un JWT `authenticated`.
3. **Registrazione pubblica disabilitata** nelle impostazioni Auth → nessuno può crearsi un utente da solo (vedi §9, Setup Supabase). Questa misura è essenziale: senza, chiunque potrebbe registrarsi, diventare `authenticated` e leggere tutto.

### Row Level Security (RLS)

Policy corrette con `TO authenticated`, `USING (true)` **e** `WITH CHECK (true)` (la sola
`USING` non basta: senza `WITH CHECK` gli `INSERT`/`UPDATE` verrebbero rifiutati). Vedi lo schema
completo in §7.

---

## 5. Funzionalità Dettagliate

### 5.1 Dashboard Mezzi

- Lista di tutti i mezzi presenti nel database
- Card per ogni mezzo con: targa, alias, tipologia, ultima manutenzione
- Indicatore visivo dello stato (es. revisione scaduta = rosso)
- FAB per aggiungere un nuovo mezzo

### 5.2 Gestione Mezzi

#### Tipologie di Mezzo (predefinite, estendibili)

| Tipo | Codice |
|---|---|
| Ambulanza | `ambulance` |
| Mezzo attrezzato (carrozzina) | `equipped_vehicle` |
| Autovettura | `car` |
| Personalizzato | `custom` |

Nuove tipologie aggiungibili da Impostazioni.

#### Dati del Mezzo

- **Targa** — identificatore univoco, obbligatorio
- **Nome / Alias** — es. "Fiat Doblò BLU", opzionale
- **Tipologia** — da lista sopra
- **Anno di immatricolazione** — opzionale
- **Note generali** — testo libero, opzionale
- **Foto** — opzionale, via Supabase Storage → **rimandata post-MVP** (vedi §10). La colonna
  `photo_url` resta nello schema, ma l'upload non è incluso nell'MVP.

### 5.3 Schede di Manutenzione

Ogni mezzo mantiene una cronologia di schede. È possibile:

- **Creare** una nuova scheda
- **Modificare** una scheda esistente
- **Visualizzare** lo storico in ordine cronologico inverso

#### Campi della Scheda — struttura

I campi di stato sono **interamente a database** (tabella `maintenance_fields`): si possono aggiungere, disabilitare o riassegnare per tipo di mezzo senza toccare il codice. I valori vengono salvati nel JSONB `maintenance_records.custom_fields`.

Campi strutturali fissi (sempre presenti):

| Campo | Tipo |
|---|---|
| `data` | Date picker (obbligatorio) |
| `km` | Numero intero |
| `note` | Testo libero multiriga |

Campi di stato predefiniti a database (tutti dropdown + opzione **"Altro…"** → testo libero):

| field_key | Label | Valori | Tipo mezzo |
|---|---|---|---|
| `tagliando` | Tagliando | Effettuato · Da fare · Non applicabile | tutti |
| `revisione` | Revisione | Effettuata · In scadenza · Scaduta · Non applicabile | tutti |
| `assicurazione` | Assicurazione | In regola · In scadenza (30 gg) · Scaduta | tutti |
| `luci` | Luci | OK · Da verificare · Sostituire | tutti |
| `lampeggianti` | Lampeggianti | OK · Da verificare · Sostituire · Non applicabile | tutti |
| `sirene` | Sirene | OK · Da verificare · Sostituire · Non applicabile | tutti |
| `spazzole` | Spazzole | OK · Da sostituire | tutti |
| `ruote` | Ruote | OK · Usura normale · Da cambiare | tutti |
| `distribuzione` | Distribuzione | OK · In scadenza · Da sostituire · Non applicabile | tutti |
| `inverter` | Inverter | OK · Da verificare · Guasto · Non applicabile | tutti |
| `batteria_servizi` | Batteria servizi | OK · Carica bassa · Da sostituire · Non applicabile | tutti |

#### Data di scadenza (`tracks_expiry`)

I campi con `tracks_expiry = TRUE` (attualmente: `revisione`, `assicurazione`, `distribuzione`) mostrano nel form un date-picker aggiuntivo **"Da effettuare entro"**. La data viene salvata in `custom_fields` con chiave `{field_key}_scadenza`. Nello storico del mezzo la data appare accanto al valore nel chip di stato.

#### Gestione campi (Fase 5 — in attesa)

Fino all'implementazione della UI Impostazioni, i campi si gestiscono dalla **dashboard Supabase SQL Editor** (vedi `docs/SETUP_MANUALE.md §A.2c`):
- Aggiungere campi: `INSERT INTO maintenance_fields ...`
- Disabilitare senza perdere dati: `active = FALSE`
- Limitare a un tipo di mezzo: `type_id = <uuid>`
- Attivare/disattivare data scadenza: `tracks_expiry = TRUE/FALSE`

---

## 6. UI/UX — Linee Guida

### Specifiche di Design (fonte: `docs/demo/`)

> 📐 **Le specifiche di design di riferimento risiedono in `docs/demo/`**: file/mockup derivati da
> Claude design che definiscono layout, componenti, colori, tipografia e flussi delle schermate.
> In fase di implementazione UI, **`docs/demo/` è la fonte autorevole**; le linee guida qui sotto
> (Material 3, breakpoint, stati) sono i principi generali entro cui calare quei mockup.

Indicazioni d'uso:
- Tradurre i mockup di `docs/demo/` in widget Flutter Material 3, mantenendo nomi/struttura coerenti
  con la struttura feature-first (§7).
- Estrarre da `docs/demo/` i **design token** (palette, spaziature, raggi, tipografia) e centralizzarli
  nel tema (`lib/app/theme/`), evitando valori hard-coded nei singoli widget.
- In caso di divergenza tra questo documento e `docs/demo/`, **prevale `docs/demo/`** per gli aspetti
  visivi; questo documento resta autorevole per dati, backend e architettura.

### Design System

- **Framework UI:** Material Design 3 (Flutter Material You)
- **Dark mode:** Supportata via `ThemeMode.system`

### Layout Adattivo

| Breakpoint | Layout |
|---|---|
| **Mobile (< 600px)** | Bottom Navigation Bar, form a pieno schermo |
| **Tablet (600–1200px)** | NavigationRail, due pannelli lista/dettaglio |
| **Desktop (> 1200px)** | Sidebar fissa, tre zone: nav / lista / dettaglio |

### Stati UI

- **Stato vuoto:** illustrazione + CTA "Aggiungi il primo mezzo"
- **Loading:** skeleton shimmer durante fetch da Supabase
- **Errore rete:** banner con pulsante "Riprova"
- **Salvataggio:** Snackbar di conferma
- **Eliminazione:** Dialog di conferma obbligatorio

---

## 7. Architettura Tecnica

### Struttura Cartelle Flutter

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme/
├── features/
│   ├── auth/
│   ├── vehicles/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── maintenance/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
├── shared/
│   ├── widgets/
│   └── providers/
└── services/
    └── supabase_service.dart
```

### Modello Dati (Supabase / PostgreSQL) — schema corrente

> Lo schema completo con seed e SQL di migrazione è in `docs/SETUP_MANUALE.md §A.2`.

**Quattro tabelle:**

| Tabella | Scopo |
|---|---|
| `vehicle_types` | Tipologie mezzo (codice, label, abbreviazione badge) |
| `vehicles` | Anagrafica mezzi (targa, alias, tipo FK, anno, note, photo_url) |
| `maintenance_records` | Schede manutenzione (date, km, notes, custom_fields JSONB) |
| `maintenance_fields` | Definizione campi di stato (data-driven) |

**`maintenance_fields` — colonne chiave:**

| Colonna | Tipo | Descrizione |
|---|---|---|
| `field_key` | TEXT UNIQUE | Chiave nel JSONB `custom_fields` |
| `label` | TEXT | Etichetta mostrata nel form |
| `field_type` | TEXT | `dropdown` / `text` / `number` |
| `options` | JSONB | Array di stringhe (per dropdown) |
| `type_id` | UUID FK | NULL = globale; valorizzato = solo per quel tipo |
| `sort_order` | INTEGER | Ordine nel form |
| `active` | BOOLEAN | FALSE = nascosto senza perdere dati |
| `tracks_expiry` | BOOLEAN | TRUE = mostra date-picker "scadenza" aggiuntivo |

**Storage dei valori nel JSONB:**
- Valore campo: `custom_fields[field_key]` (stringa)
- Data scadenza: `custom_fields[field_key + '_scadenza']` (stringa ISO `YYYY-MM-DD`)

**RLS:** policy `authenticated_all` (`TO authenticated USING (true) WITH CHECK (true)`) su tutte le tabelle. Registrazione pubblica disabilitata — solo chi ha le credenziali condivise può autenticarsi.

### Configurazione PWA (`web/manifest.json`)

```json
{
  "name": "Gestione Mezzi",
  "short_name": "Mezzi",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#1565C0",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

### Integrazione Supabase in Flutter

- Dipendenze: `flutter pub add supabase_flutter flutter_riverpod go_router freezed_annotation json_annotation` e (dev) `flutter pub add --dev build_runner freezed json_serializable riverpod_generator`.
- In `main.dart`, leggere URL e anon key **da variabili di compilazione** (non hard-coded):

```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
```

- Abilitare URL puliti: `usePathUrlStrategy()` (da `package:flutter_web_plugins/url_strategy.dart`) prima di `runApp` — richiede il rewrite SPA su Firebase (vedi §10).
- go_router: `redirect` guard → se `Supabase.instance.client.auth.currentSession == null` reindirizza a `/login`.

---

## 8. Roadmap di Sviluppo

### Fase 1 — Setup Progetto ✅
- [x] Progetto Flutter già creato (`mise_pwa`) — **non** rieseguire `flutter create`
- [x] `flutter pub add` delle dipendenze (Supabase, Riverpod, go_router, freezed…)
- [x] Configurazione Supabase (progetto, tabelle SQL, RLS, trigger) — vedi §9
- [x] Creazione account condiviso + disabilitazione signup pubblico
- [x] Inizializzazione `supabase_flutter` con `--dart-define`
- [x] Struttura cartelle feature-first
- [x] Tema Material 3 base (light + dark)
- [x] Navigazione base con go_router + `usePathUrlStrategy()`

### Fase 2 — Autenticazione ✅
- [x] Schermata di login (email + password)
- [x] Persistenza sessione (auto-login alla riapertura — vedi limiti iOS §12)
- [ ] Logout — `AuthRepository.signOut()` implementato; pulsante UI rinviato a Fase 5 (Settings)
- [x] Redirect guard go_router

### Fase 3 — Gestione Mezzi ✅
- [x] Repository Supabase per `vehicles` e `vehicle_types`
- [x] Provider Riverpod per lista mezzi
- [x] Schermata lista mezzi (con skeleton loader)
- [x] Schermata dettaglio mezzo
- [x] Form creazione/modifica mezzo
- [x] Eliminazione mezzo con conferma

### Fase 4 — Schede Manutenzione ✅
- [x] Repository Supabase per `maintenance_records` (`MaintenanceRepository`)
- [x] Repository per definizioni campi (`MaintenanceFieldRepository`)
- [x] Schede visibili nello storico del dettaglio mezzo (chip colorati per valori critici)
- [x] Form manutenzione data-driven: dropdown + "Altro…" + date-picker scadenza
- [x] Creazione / modifica / eliminazione scheda
- [x] Campi a DB (`maintenance_fields`): scoped per tipo mezzo, attivabili/disabilitabili, con data scadenza opzionale (`tracks_expiry`)

### Fase 5 — Impostazioni e Campi Custom
- [ ] Schermata impostazioni
- [ ] CRUD `maintenance_fields` in-app (oggi gestiti da dashboard Supabase — vedi `SETUP_MANUALE.md §A.2c`)
- [ ] Gestione tipologie mezzo custom

### Fase 6 — PWA e Layout Adattivo (parziale)
- [x] Estrarre design token dai mockup in `docs/demo/` → tema in `lib/app/theme/`
- [ ] Implementare le schermate seguendo i mockup di `docs/demo/` (fonte autorevole UI — §6) — parziale: screens Fase 1–3 completate; Fase 4–5 pending
- [ ] Layout responsive: mobile / tablet / desktop
- [x] Configurazione manifest PWA
- [x] Icone PWA (192px, 512px, maskable)

### Fase 7 — Deploy in Produzione (Firebase Hosting)
- [ ] `firebase init hosting` (public = `build/web`, SPA rewrite)
- [ ] `firebase.json` con cache headers corretti
- [ ] `flutter build web --release --dart-define=...`
- [ ] `firebase deploy --only hosting`
- [ ] GitHub Actions per deploy automatico su push a `main`
- [ ] (più avanti) dominio custom

### Fase 8 — Ottimizzazioni (Post-MVP)
- [ ] **Foto mezzi** via Supabase Storage (bucket + policy — vedi §11)
- [ ] Cache offline avanzata con service worker --> won't do
- [ ] Export PDF scheda manutenzione
- [ ] Indicatori visivi scadenze (colori stato)

---

## 9. Setup Supabase — passo per passo

> Tempo stimato: ~15 minuti. Tutto dalla dashboard `app.supabase.com`.

### 9.1 Creare il progetto
1. `app.supabase.com` → **New project**.
2. Nome: es. `mise-pwa`. **Region: EU (Frankfurt)** (latenza/GDPR per l'Italia).
3. Imposta una **Database password** robusta e salvala (serve per accessi diretti al DB).
4. Attendi il provisioning (~2 min).

### 9.2 Creare schema, RLS e trigger
1. Menu laterale → **SQL Editor** → **New query**.
2. Incolla **tutto** lo script SQL della §7 ed esegui (**Run**).
3. Verifica in **Table Editor** che esistano le 4 tabelle e che `vehicle_types` contenga le 3 righe di seed.
4. In **Authentication → Policies** verifica che ogni tabella abbia la policy `authenticated_all` e l'icona RLS attiva.

### 9.3 Creare l'account condiviso e bloccare le registrazioni
1. **Authentication → Providers → Email**: assicurati che *Email* sia abilitato; **disattiva "Confirm email"** se vuoi evitare il giro di conferma (è un account interno).
2. **Authentication → Sign In / Providers (settings)** → **disabilita "Allow new users to sign up"** (registrazione pubblica OFF). ⚠️ Passo di sicurezza essenziale.
3. **Authentication → Users → Add user → Create new user**:
   - Email: `mezzi@associazione.it` (o quella scelta)
   - Password: la password condivisa
   - **Auto Confirm User: ON**
4. (Consigliato) Annota dove sono custodite le credenziali condivise e come ruotarle se trapelano.

### 9.4 Recuperare le chiavi per l'app
1. **Project Settings → API**.
2. Copia **Project URL** → sarà `SUPABASE_URL`.
3. Copia **anon public** key → sarà `SUPABASE_ANON_KEY`.
   (È pubblica per design — vedi §4 — ma la passiamo via `--dart-define`/secret per pulizia.)

### 9.5 Verifica RLS (facoltativa ma consigliata)
- Con l'app loggata: una `select` su `vehicles` funziona.
- Da terminale **senza** JWT, una chiamata REST anonima deve essere **negata**:
  ```
  curl "https://<PROGETTO>.supabase.co/rest/v1/vehicles" -H "apikey: <ANON_KEY>"
  ```
  Deve restituire un array vuoto/permesso negato, **non** i dati. ✅

---

## 10. Setup Firebase Hosting — passo per passo

> Si usa **solo** il prodotto *Hosting*. Nessun Firebase Auth/Firestore: il backend resta Supabase.
> Firebase Hosting e Supabase sono indipendenti (vedi §11).

### 10.1 Prerequisiti
- Node.js installato → `npm install -g firebase-tools`
- `firebase login` (login Google nel browser)

### 10.2 Creare il progetto Firebase
1. `console.firebase.google.com` → **Add project** → nome es. `mise-pwa` (Analytics: non necessario).
2. (Nessun bisogno di aggiungere app Web nella console: ci pensa la CLI.)

### 10.3 Inizializzare Hosting nel repo
Dalla cartella del progetto:
```
firebase init hosting
```
Rispondi:
- **Use an existing project** → seleziona `mise-pwa`
- **public directory:** `build/web`
- **Configure as a single-page app (rewrite all urls to /index.html):** **Yes** ← fondamentale per go_router
- **Set up automatic builds with GitHub:** *No* (lo configuriamo a mano, §10.6)
- **File build/web/index.html already exists. Overwrite?** **No**

### 10.4 `firebase.json` — rewrite SPA + cache headers
Verifica/integra così (gli header evitano che gli utenti restino su versioni vecchie della PWA):
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }],
    "headers": [
      {
        "source": "/index.html",
        "headers": [{ "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }]
      },
      {
        "source": "/flutter_service_worker.js",
        "headers": [{ "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }]
      },
      {
        "source": "/version.json",
        "headers": [{ "key": "Cache-Control", "value": "no-cache, no-store, must-revalidate" }]
      },
      {
        "source": "**/*.@(js|wasm|png|jpg|jpeg|svg|woff2)",
        "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
      }
    ]
  }
}
```

### 10.5 Build e primo deploy manuale
```
flutter build web --release \
  --dart-define=SUPABASE_URL=https://<PROGETTO>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>

firebase deploy --only hosting
```
Al termine la CLI stampa l'URL `https://<progetto>.web.app`. Aprilo, fai login, e **ricarica la
pagina su una rotta profonda** (es. dettaglio mezzo): non deve dare 404 (rewrite SPA OK).

### 10.6 Deploy automatico con GitHub Actions
1. Genera il token CI per il service account:
   ```
   firebase init hosting:github
   ```
   (collega il repo `mise_pwa`, crea il secret `FIREBASE_SERVICE_ACCOUNT_...` e un workflow base).
2. Nel repo GitHub → **Settings → Secrets and variables → Actions** aggiungi:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   (il secret del service account Firebase lo crea già il comando sopra).
3. Workflow `.github/workflows/deploy.yml` (esempio):
   ```yaml
   name: Deploy to Firebase Hosting
   on:
     push:
       branches: [main]
   jobs:
     build_and_deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: subosito/flutter-action@v2
           with: { channel: stable }
         - run: flutter pub get
         - run: |
             flutter build web --release \
               --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
               --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
         - uses: FirebaseExtended/action-hosting-deploy@v0
           with:
             repoToken: ${{ secrets.GITHUB_TOKEN }}
             firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_MISE_PWA }}
             channelId: live
             projectId: mise-pwa
   ```

### 10.7 Dominio custom (più avanti)
Firebase Hosting → **Add custom domain** → segui le istruzioni DNS (record A/TXT). SSL automatico e
gratuito. Per ora si resta su `*.web.app`.

---

## 11. Host: confronto e scelta

Tutti gli host statici richiedono build di Flutter in CI/locale; tutti supportano il routing SPA.
A parità di questo è stato scelto **Firebase Hosting**.

| Host | Routing SPA | Dominio custom | Free tier | Ergonomia Flutter | Vincoli d'uso |
|---|---|---|---|---|---|
| **Firebase Hosting** ✅ | rewrite in 1 riga | gratis + SSL | ampio (Spark) | CLI ufficiale, action GH pronta | nessuno |
| Cloudflare Pages | `_redirects` | gratis + SSL | banda illimitata | deploy prebuilt via action | nessuno |
| GitHub Pages | hack `404.html` | sì | gratis | sottopercorso `/repo`, routing fragile | nessuno |
| Vercel | `vercel.json` rewrite | gratis + SSL | buono | solo `--prebuilt` | Hobby = solo non commerciale |

**Firebase Hosting e Supabase non si "danno fastidio":** Firebase Hosting è solo un CDN che consegna
i file statici dell'app; Supabase resta il backend (DB/Auth/API) raggiunto dal browser via HTTPS.
Note: il CORS di Supabase è aperto di default (nessuna configurazione); una eventuale CSP restrittiva
dovrà includere `https://<PROGETTO>.supabase.co` tra le sorgenti consentite.

---

## 12. Limiti Noti

- **iOS / Safari (PWA):** nessuna notifica push; inoltre Safari può **evictare lo storage** della
  PWA dopo periodi di inattività → l'**auto-login non è garantito** su iOS (l'utente potrebbe dover
  rifare il login). Comportamento della piattaforma, non aggirabile lato app.
- **macOS Safari:** PWA non installabile (solo uso da browser).
- **Account condiviso:** nessun audit di "chi ha fatto cosa"; se la password trapela va ruotata per
  tutti. Accettato come trade-off voluto (zero gestione utenti).

---

## 13. Setup Foto Mezzi (Post-MVP, opzionale)

Quando si vorranno abilitare le foto:
1. Supabase → **Storage → New bucket**: nome `vehicle-photos`, **Public** (lettura pubblica delle
   immagini) oppure privato con URL firmati.
2. Policy su `storage.objects` per consentire upload/update/delete **solo** agli autenticati:
   ```sql
   CREATE POLICY "auth_write_photos" ON storage.objects
     FOR ALL TO authenticated
     USING (bucket_id = 'vehicle-photos')
     WITH CHECK (bucket_id = 'vehicle-photos');
   ```
3. In Flutter: upload via `supabase.storage.from('vehicle-photos').upload(...)`, salvare l'URL
   pubblico (o il path per URL firmato) in `vehicles.photo_url`.

---

## 14. Pacchetti Flutter

> Usare `flutter pub add <pkg>` per ottenere automaticamente le versioni più recenti compatibili con
> Flutter 3.44 / Dart 3.12 (evita di fissare versioni che invecchiano). Set previsto:

```
# runtime
supabase_flutter
flutter_riverpod
riverpod_annotation
go_router
freezed_annotation
json_annotation

# dev
build_runner
freezed
json_serializable
riverpod_generator
```

---

## 15. Note di Sessione

### 2026-06-15 — Sessione 1 (v0.1.0)
- Documento iniziale creato sulla base del briefing

### 2026-06-15 — Sessione 2 (v0.2.0)
- Rimossa autenticazione multi-utente; chiarita strategia PWA e compatibilità dispositivi

### 2026-06-15 — Sessione 3 (v0.3.0)
- Autenticazione ripristinata come account condiviso unico; RLS per utenti autenticati;
  modello di distribuzione (l'URL è l'app); aggiunta Fase 2 (auth)

### 2026-06-16 — Sessione 6 (v0.6.0) — Fase 4 completata + data scadenza

- **Fase 4 completata**: `MaintenanceRepository`, `MaintenanceFieldRepository`, `MaintenanceFormScreen` (new + edit + delete), storico nel dettaglio mezzo con chip colorati data-driven
- **Campi manutenzione interamente a DB** (`maintenance_fields`): dropdown + "Altro…", scopati per tipo mezzo, attivabili/disabilitabili senza toccare il codice
- **Data di scadenza** (`tracks_expiry`): i campi con flag mostrano date-picker "Da effettuare entro"; data salvata in `custom_fields[field_key + '_scadenza']`; attivo di default per revisione, assicurazione, distribuzione
- **Fix datepicker**: rimosso `locale: const Locale('it')` da `showDatePicker` (richiederebbe `flutter_localizations`); la locale del browser viene usata automaticamente
- Aggiornati `CLAUDE.md`, `SETUP_MANUALE.md` (§A.2, §A.2b, §A.2c), questo documento

### 2026-06-16 — Sessione 5 (v0.5.0) — Avanzamento implementazione
- Aggiornata roadmap §8 con stato effettivo del codice (Fasi 1–3 completate)
- **Fase 1** completata: dipendenze, Supabase (credenziali in `docs/SETUP_MANUALE.md`),
  struttura feature-first, tema Material 3, go_router con `usePathUrlStrategy()`
- **Fase 2** completata (meno logout UI): login screen, persistenza sessione, redirect guard;
  `signOut()` implementato in `AuthRepository` ma pulsante UI sarà in Fase 5 (Settings)
- **Fase 3** completata: `VehicleRepository`, `VehiclesNotifier`, `VehicleListScreen` (skeleton,
  ricerca, filtri per tipo), `VehicleDetailScreen`, `VehicleFormScreen` (crea + modifica + elimina)
- **Fase 6 parziale**: design token estratti in `AppColors`/`AppTheme`, PWA manifest e icone
  presenti; layout responsive e screens Fase 4–5 ancora pending
- Aggiunto `CLAUDE.md` alla radice del progetto per orientamento futuro di Claude Code

### 2026-06-15 — Sessione 4 (v0.4.0) — Revisione tecnica
- **Host cambiato da Vercel a Firebase Hosting** (Flutter non si builda nativo su nessun host;
  Vercel Hobby ha clausola "solo non commerciale"). Aggiunto confronto host (§11)
- **Corretta la motivazione sulla anon key**: è sempre pubblica; protezione = RLS + login +
  signup disabilitato (§4)
- **RLS completata**: `ENABLE ROW LEVEL SECURITY` + `TO authenticated` + `USING` **e** `WITH CHECK`
- **Aggiunto trigger `updated_at`**, **FK `type_id ON DELETE RESTRICT`**, indice su manutenzioni
- **Routing SPA** (`usePathUrlStrategy()` + rewrite) e **cache headers PWA** in `firebase.json`
- **Foto mezzi spostate a post-MVP** (§13); **Storage** documentato come opzionale
- Allineato il package a quello reale **`mise_pwa`** (niente `flutter create`)
- Aggiunte sezioni dettagliate **Setup Supabase** (§9) e **Setup Firebase Hosting** (§10),
  con GitHub Actions e limiti noti (§12)
- **`docs/demo/` indicato come fonte autorevole delle specifiche di design** (mockup derivati da
  Claude design): aggiornata §6 (UI/UX) e Fase 6 della roadmap
```
