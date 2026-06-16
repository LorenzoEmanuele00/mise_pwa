# Setup Manuale — Gestione Mezzi (mise_pwa)

> **Documento operativo:** contiene tutte le istruzioni che devi eseguire **tu** dalla
> dashboard o dal terminale. Il codice Flutter è generato dall'assistente; questo file
> copre solo le parti che richiedono la tua interazione.

---

## Quando eseguire cosa

| ID | Operazione | Dove | Momento |
|----|-----------|------|---------|
| **A** | Supabase: progetto + SQL + account condiviso + signup OFF + chiavi | Dashboard + SQL Editor | **Dopo lo Step 1 del codice**, prima del primo `flutter run` |
| **B** | Firebase: installa CLI + crea progetto nella console | Terminale + console Google | Quando vuoi, entro Step 7 |
| **C** | `firebase init hosting` (interattivo) | Terminale, cartella progetto | **Step 7**, dopo prima `flutter build web` |
| **D** | Primo deploy manuale | Terminale | **Step 7**, subito dopo C |
| **E** | `firebase init hosting:github` + secret GitHub | Terminale + GitHub repo | **Step 7**, dopo che D funziona |

---

## § A — Supabase (eseguire dopo Step 1)

### A.1 — Crea il progetto

1. Vai su **[app.supabase.com](https://app.supabase.com)** e accedi/registrati.
2. **New project**:
   - **Name:** `mise-pwa` (o nome a scelta)
   - **Region:** `EU (Frankfurt)` ← obbligatorio per latenza/GDPR Italia
   - **Database Password:** scegli una password robusta e salvala (es. in un password manager); serve per accessi diretti al DB.
3. Attendi il provisioning (~2 minuti).

---

### A.2 — Crea schema, RLS e trigger

1. Nel menu laterale: **SQL Editor → New query**.
2. Incolla **tutto** il blocco SQL qui sotto e premi **Run** (▶).

```sql
-- ============================================================
-- 1. TIPOLOGIE MEZZO
-- ============================================================
CREATE TABLE vehicle_types (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code       TEXT UNIQUE NOT NULL,
  label      TEXT NOT NULL,
  is_custom  BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO vehicle_types (code, label) VALUES
  ('ambulance',        'Ambulanza'),
  ('equipped_vehicle', 'Mezzo attrezzato'),
  ('car',              'Autovettura');

-- ============================================================
-- 2. MEZZI
-- ============================================================
CREATE TABLE vehicles (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plate      TEXT NOT NULL UNIQUE,
  alias      TEXT,
  type_id    UUID REFERENCES vehicle_types(id) ON DELETE RESTRICT,
  year       INTEGER,
  notes      TEXT,
  photo_url  TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. SCHEDE DI MANUTENZIONE
-- ============================================================
CREATE TABLE maintenance_records (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id       UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  date             DATE NOT NULL,
  km               INTEGER,
  tagliando        TEXT,
  revisione        TEXT,
  luci             TEXT,
  lampeggianti     TEXT,
  sirene           TEXT,
  spazzole         TEXT,
  distribuzione    TEXT,
  inverter         TEXT,
  batteria_servizi TEXT,
  ruote            TEXT,
  assicurazione    TEXT,
  notes            TEXT,
  custom_fields    JSONB DEFAULT '{}',
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_maintenance_vehicle ON maintenance_records (vehicle_id, date DESC);

-- ============================================================
-- 4. CAMPI PERSONALIZZATI (condivisi)
-- ============================================================
CREATE TABLE custom_maintenance_fields (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  field_key  TEXT NOT NULL UNIQUE,
  label      TEXT NOT NULL,
  field_type TEXT NOT NULL CHECK (field_type IN ('dropdown', 'text', 'number')),
  options    JSONB,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. TRIGGER updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_vehicles_updated_at
  BEFORE UPDATE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_maintenance_updated_at
  BEFORE UPDATE ON maintenance_records
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE vehicle_types             ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_records       ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_maintenance_fields ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_all" ON vehicle_types
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON vehicles
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON maintenance_records
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON custom_maintenance_fields
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
```

3. **Verifica:** vai in **Table Editor** → devono esistere le 4 tabelle, e `vehicle_types` deve contenere 3 righe (Ambulanza, Mezzo attrezzato, Autovettura).
4. **Verifica RLS:** **Authentication → Policies** → ogni tabella deve mostrare la policy `authenticated_all` con l'icona RLS attiva (lucchetto verde).

---

### A.3 — Account condiviso e blocco registrazioni

1. **Authentication → Providers → Email**: verifica che *Email* sia abilitato.
2. **Disattiva "Confirm email"** (opzionale ma comodo per un account interno: l'utente non deve cliccare nessuna email di conferma).
3. **⚠️ PASSO DI SICUREZZA OBBLIGATORIO — disabilita la registrazione pubblica:**
   - **Authentication → Sign In / Providers** (o a seconda della versione della dashboard: **Authentication → Configuration → Sign Up**)
   - Trova **"Allow new users to sign up"** e **disattivalo**.
   - Senza questo passaggio chiunque potrebbe crearsi un account, diventare `authenticated` e leggere tutti i dati.
4. **Crea l'utente condiviso dell'associazione:**
   - **Authentication → Users → Add user → Create new user**
   - Email: es. `mezzi@associazione.it` (l'email che useranno i volontari)
   - Password: scegli una password robusta e condividila con i volontari autorizzati
   - **Auto Confirm User: ON** (spunta la casella)
5. **Conserva le credenziali** in un luogo sicuro e condividi la password solo con i volontari che devono accedere.

---

### A.4 — Recupera le chiavi per l'app

1. **Project Settings → API** (menu laterale in basso).
2. Copia e salva:
   - **Project URL** → questo sarà il valore di `SUPABASE_URL` --> https://hvvfzvitygxyveiosumk.supabase.co
   - **anon public** key → questo sarà il valore di `SUPABASE_ANON_KEY` --> sb_publishable_SutfYdlbIjrUi328lqcz0Q_98l0uJrg

> ℹ️ La `anon key` non è un segreto da nascondere: finisce nel bundle scaricabile dal browser
> per design. La sicurezza è garantita dalla RLS + login obbligatorio + signup disabilitato.
> La passiamo comunque via `--dart-define` per pulizia.

**Da questo momento puoi avviare l'app con:**
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://hvvfzvitygxyveiosumk.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_SutfYdlbIjrUi328lqcz0Q_98l0uJrg
```

---

### A.5 — Verifica RLS (facoltativa ma consigliata)

Dopo aver avviato l'app almeno una volta, apri un terminale e prova:
```bash
curl "https://hvvfzvitygxyveiosumk.supabase.co/rest/v1/vehicles" \
  -H "apikey: sb_publishable_SutfYdlbIjrUi328lqcz0Q_98l0uJrg"
```
Il risultato deve essere `[]` (array vuoto) o un errore di permesso, **mai** una lista di dati.
Se vedi dati: la RLS non è attiva, torna in §A.2 e verifica.

---

---

## § B — Firebase: prerequisiti e progetto (eseguire prima dello Step 7)

### B.1 — Installa Firebase CLI

```bash
npm install -g firebase-tools
```

Verifica l'installazione:
```bash
firebase --version
```

### B.2 — Login Google

```bash
firebase login
```

Si apre il browser: accedi con il tuo account Google.

### B.3 — Crea il progetto Firebase

1. Vai su **[console.firebase.google.com](https://console.firebase.google.com)**.
2. **Add project** → Nome: `mise-pwa` (o nome a scelta).
3. Analytics: non necessario → disattiva e procedi.
4. Attendi la creazione (~1 minuto).

> ℹ️ Useremo **solo** Firebase Hosting come CDN per i file statici. Nessun Firebase Auth,
> Firestore o altro prodotto Firebase: il backend resta interamente Supabase.

---

## § C — `firebase init hosting` (eseguire durante Step 7, dopo prima build)

Dalla cartella del progetto:
```bash
firebase init hosting
```

Rispondi alle domande **esattamente così**:

| Domanda | Risposta |
|---------|----------|
| Use an existing project | ✅ Seleziona `mise-pwa` |
| What do you want to use as your public directory? | **`build/web`** |
| Configure as a single-page app (rewrite all urls to /index.html)? | **Yes** ← fondamentale per go_router |
| Set up automatic builds and deploys with GitHub? | **No** (lo configuriamo in §E) |
| File build/web/index.html already exists. Overwrite? | **No** |

Verifica che siano stati creati `firebase.json` e `.firebaserc`.

---

## § D — Primo deploy manuale (Step 7)

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://<PROGETTO>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>

firebase deploy --only hosting
```

Al termine la CLI stampa l'URL del tipo `https://<progetto>.web.app`.

**Test di verifica:**
1. Apri l'URL → deve comparire la schermata di login.
2. Fai login con le credenziali condivise → deve entrare nell'app.
3. Naviga a un dettaglio mezzo (es. `https://<progetto>.web.app/vehicles/123`) e **ricarica la pagina (F5)** → non deve dare 404. Se dà 404: il rewrite SPA non è configurato, torna in §C.

---

## § E — CI/CD con GitHub Actions (Step 7, dopo che §D funziona)

### E.1 — Collega il repo a Firebase

```bash
firebase init hosting:github
```

Il comando:
- Ti chiede il nome del repo GitHub (es. `nomeutente/mise_pwa`)
- Crea automaticamente il secret `FIREBASE_SERVICE_ACCOUNT_MISE_PWA` nel repo GitHub
- Genera un file workflow di base (puoi ignorarlo: useremo quello creato dall'assistente)

### E.2 — Aggiungi i secret Supabase su GitHub

1. Vai nel tuo repo GitHub → **Settings → Secrets and variables → Actions**.
2. Clicca **New repository secret** e aggiungi:

| Secret name | Valore |
|-------------|--------|
| `SUPABASE_URL` | `https://<PROGETTO>.supabase.co` |
| `SUPABASE_ANON_KEY` | `<LA-TUA-ANON-KEY>` |

> Il secret `FIREBASE_SERVICE_ACCOUNT_MISE_PWA` è già stato creato dal comando `firebase init hosting:github`.

### E.3 — Verifica il workflow CI

Dopo aver aggiunto i secret:
1. Fai un commit/push su `main`.
2. Vai su **GitHub → Actions** → verifica che il workflow `Deploy to Firebase Hosting` parta e si completi con successo.
3. Al termine, riapri `https://<progetto>.web.app` e verifica che rifletta l'ultima versione.

---

## Checklist riepilogativa

### Supabase (§ A)
- [ ] Progetto creato in EU Frankfurt
- [ ] SQL eseguito senza errori (4 tabelle + seed + trigger + RLS)
- [ ] Tabella `vehicle_types` ha 3 righe
- [ ] Policy `authenticated_all` visibile su tutte le tabelle con RLS attiva
- [ ] **"Allow new users to sign up" disabilitato** ⚠️
- [ ] Utente condiviso creato (Auto Confirm ON)
- [ ] `SUPABASE_URL` e `SUPABASE_ANON_KEY` copiati e salvati
- [ ] (facoltativa) Verifica RLS via `curl` → array vuoto ✅

### Firebase (§ B–E)
- [ ] `firebase-tools` installato
- [ ] `firebase login` eseguito
- [ ] Progetto `mise-pwa` creato in console Firebase
- [ ] Prima `flutter build web` eseguita con successo
- [ ] `firebase init hosting` completato con le risposte corrette
- [ ] `firebase.json` aggiornato con rewrite SPA + cache headers
- [ ] Primo deploy (`firebase deploy --only hosting`) → URL funzionante
- [ ] Ricarica su rotta profonda → nessun 404
- [ ] `firebase init hosting:github` → secret service account creato su GitHub
- [ ] Secret `SUPABASE_URL` e `SUPABASE_ANON_KEY` aggiunti su GitHub
- [ ] Push su `main` → CI verde → sito aggiornato
