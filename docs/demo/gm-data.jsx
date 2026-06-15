// gm-data.jsx — seed data, dropdown options, status config, helpers

// ── Stato del mezzo ──────────────────────────────────────────
const STATI_MEZZO = {
  attivo:       { label: 'Attivo',           dot: 'var(--ok)',    fg: 'var(--ok-fg)',   bg: 'var(--ok-bg)' },
  manutenzione: { label: 'In manutenzione',  dot: 'var(--warn)',  fg: 'var(--warn-fg)', bg: 'var(--warn-bg)' },
  fermo:        { label: 'Fermo',            dot: 'var(--bad)',   fg: 'var(--bad-fg)',  bg: 'var(--bad-bg)' },
};

const TIPI_MEZZO = ['Ambulanza', 'Automedica', 'Furgone', 'Auto di servizio'];

// ── Opzioni tendine manutenzione ─────────────────────────────
const OPZ_TIPO_INTERVENTO = [
  'Tagliando', 'Riparazione', 'Revisione ministeriale',
  'Controllo straordinario', 'Sostituzione componente', 'Sanificazione',
];
const OPZ_CATEGORIA = [
  'Motore', 'Freni', 'Pneumatici', 'Impianto elettrico',
  'Impianto idraulico', 'Carrozzeria', 'Allestimento sanitario', 'Climatizzazione',
];
const OPZ_ESITO = ['Programmata', 'In corso', 'Completata'];
const OPZ_OFFICINA = [
  'Officina interna', 'Carrozzeria Belli', 'AutoService Rossi',
  'Centro Revisioni Nord', 'Gommista Marini',
];

// ── Campi personalizzati per tipo di mezzo ───────────────────
const TIPI_CAMPO = [
  { id: 'select', label: 'Menu a tendina' },
  { id: 'testo',  label: 'Testo' },
  { id: 'numero', label: 'Numero' },
  { id: 'data',   label: 'Data' },
];
const TIPO_CAMPO_LABEL = { select: 'Tendina', testo: 'Testo', numero: 'Numero', data: 'Data' };

// Config di esempio: campi extra che compaiono nella scheda manutenzione
const SEED_CAMPI = {
  'Ambulanza':        [
    { id: 'k1', label: 'Sanificazione cabina', tipo: 'select', opzioni: ['Eseguita', 'Non necessaria'] },
    { id: 'k2', label: 'Bombole O₂ controllate', tipo: 'select', opzioni: ['Sì', 'No'] },
  ],
  'Automedica':       [],
  'Furgone':          [],
  'Auto di servizio': [],
};

const ESITO_CFG = {
  'Programmata': { fg: 'var(--info-fg)', bg: 'var(--info-bg)' },
  'In corso':    { fg: 'var(--warn-fg)', bg: 'var(--warn-bg)' },
  'Completata':  { fg: 'var(--ok-fg)',   bg: 'var(--ok-bg)' },
};

// ── Helpers ──────────────────────────────────────────────────
const fmtKm = (n) => n == null || n === '' ? '—' : Number(n).toLocaleString('it-IT') + ' km';
const fmtEuro = (n) => n == null || n === '' ? '—' : '€ ' + Number(n).toLocaleString('it-IT', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const fmtData = (iso) => {
  if (!iso) return '—';
  const [y, m, d] = iso.split('-');
  return `${d}/${m}/${y}`;
};
const oggi = () => '2026-06-05';
const giorniA = (iso) => {
  if (!iso) return null;
  const ms = new Date(iso + 'T00:00:00') - new Date(oggi() + 'T00:00:00');
  return Math.round(ms / 86400000);
};
const uid = () => 'm' + Math.random().toString(36).slice(2, 9);

// ── Seed flotta ──────────────────────────────────────────────
const SEED_MEZZI = [
  {
    id: 'v1', nome: 'Ambulanza Alfa-1', tipo: 'Ambulanza',
    marca: 'Fiat', modello: 'Ducato 4x4', targa: 'DG 482 KP', anno: 2022,
    km: 84500, stato: 'attivo', prossima: '2026-06-12',
    manutenzioni: [
      { id: 'a1', tipo: 'Tagliando', categoria: 'Motore', data: '2025-12-02', km: 78200, officina: 'AutoService Rossi', esito: 'Completata', costo: 540, note: 'Cambio olio e filtri. Controllo cinghia distribuzione: ok.' },
      { id: 'a2', tipo: 'Sostituzione componente', categoria: 'Freni', data: '2026-03-18', km: 81900, officina: 'Officina interna', esito: 'Completata', costo: 310, note: 'Sostituite pastiglie anteriori.' },
    ],
  },
  {
    id: 'v2', nome: 'Ambulanza Alfa-2', tipo: 'Ambulanza',
    marca: 'Mercedes', modello: 'Sprinter 319', targa: 'EX 113 RT', anno: 2021,
    km: 121300, stato: 'manutenzione', prossima: '2026-06-08',
    manutenzioni: [
      { id: 'b1', tipo: 'Riparazione', categoria: 'Impianto idraulico', data: '2026-06-03', km: 121300, officina: 'Officina interna', esito: 'In corso', costo: '', note: 'Perdita liquido servosterzo, in attesa ricambio.' },
      { id: 'b2', tipo: 'Revisione ministeriale', categoria: 'Carrozzeria', data: '2025-09-14', km: 110400, officina: 'Centro Revisioni Nord', esito: 'Completata', costo: 95, note: 'Revisione superata.' },
    ],
  },
  {
    id: 'v3', nome: 'Automedica Mike-1', tipo: 'Automedica',
    marca: 'Volkswagen', modello: 'Tiguan', targa: 'FT 902 ZL', anno: 2023,
    km: 45200, stato: 'attivo', prossima: '2026-09-20',
    manutenzioni: [
      { id: 'c1', tipo: 'Tagliando', categoria: 'Motore', data: '2026-01-22', km: 40100, officina: 'AutoService Rossi', esito: 'Completata', costo: 420, note: '' },
    ],
  },
  {
    id: 'v4', nome: 'Furgone Logistica', tipo: 'Furgone',
    marca: 'Renault', modello: 'Master L3H2', targa: 'DM 551 AB', anno: 2020,
    km: 156800, stato: 'fermo', prossima: '2026-06-05',
    manutenzioni: [
      { id: 'd1', tipo: 'Riparazione', categoria: 'Motore', data: '2026-05-28', km: 156800, officina: 'AutoService Rossi', esito: 'Programmata', costo: '', note: 'Guasto turbina, fermo in attesa preventivo.' },
    ],
  },
  {
    id: 'v5', nome: 'Auto Servizi 1', tipo: 'Auto di servizio',
    marca: 'Fiat', modello: 'Panda', targa: 'GA 220 XY', anno: 2024,
    km: 12400, stato: 'attivo', prossima: '2026-11-02',
    manutenzioni: [],
  },
];

Object.assign(window, {
  STATI_MEZZO, TIPI_MEZZO, OPZ_TIPO_INTERVENTO, OPZ_CATEGORIA, OPZ_ESITO, OPZ_OFFICINA,
  ESITO_CFG, fmtKm, fmtEuro, fmtData, oggi, giorniA, uid, SEED_MEZZI,
  TIPI_CAMPO, TIPO_CAMPO_LABEL, SEED_CAMPI,
});
