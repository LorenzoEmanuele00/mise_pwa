// gm-screens.jsx — the screens for Gestione Mezzi

const { useState: useS, useMemo } = React;

// Urgency pill for "prossima manutenzione"
function ProssimaPill({ iso, stato }) {
  const g = giorniA(iso);
  let txt, tone;
  if (stato === 'fermo') { txt = 'Mezzo fermo', tone = 'bad'; }
  else if (g == null) { txt = '—'; tone = 'mute'; }
  else if (g < 0) { txt = `Scaduta da ${Math.abs(g)} g`; tone = 'bad'; }
  else if (g === 0) { txt = 'Scade oggi'; tone = 'bad'; }
  else if (g <= 7) { txt = `Tra ${g} g`; tone = 'warn'; }
  else if (g <= 30) { txt = `Tra ${g} g`; tone = 'mute'; }
  else { txt = fmtData(iso); tone = 'mute'; }
  const tones = {
    bad:  { fg: 'var(--bad-fg)',  bg: 'var(--bad-bg)' },
    warn: { fg: 'var(--warn-fg)', bg: 'var(--warn-bg)' },
    mute: { fg: 'var(--text-2)',  bg: 'var(--surface-2)' },
  };
  const c = tones[tone];
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '3px 9px', borderRadius: 8, background: c.bg, color: c.fg, fontSize: 12, fontWeight: 600, whiteSpace: 'nowrap' }}>
      {(tone === 'bad' || tone === 'warn') && Icon.alert(c.fg)}
      {txt}
    </span>
  );
}

// ════════════════════════════════════════════════════════════
// 1 · LISTA MEZZI
// ════════════════════════════════════════════════════════════
function ListaMezzi({ mezzi, nav }) {
  const [q, setQ] = useS('');
  const [fStato, setFStato] = useS(null);
  const [fTipo, setFTipo] = useS(null);

  const list = useMemo(() => mezzi.filter(m => {
    if (fStato && m.stato !== fStato) return false;
    if (fTipo && m.tipo !== fTipo) return false;
    if (q.trim()) {
      const s = (m.nome + ' ' + m.targa + ' ' + m.marca + ' ' + m.modello).toLowerCase();
      if (!s.includes(q.trim().toLowerCase())) return false;
    }
    return true;
  }), [mezzi, q, fStato, fTipo]);

  const urgenti = mezzi.filter(m => m.stato === 'fermo' || (giorniA(m.prossima) != null && giorniA(m.prossima) <= 7)).length;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TopBar large title="Mezzi" subtitle={`${mezzi.length} veicoli in flotta`}
        action={<React.Fragment>
          <button onClick={nav.goConfig} aria-label="Campi personalizzati" style={{ width: 38, height: 38, borderRadius: 99, background: 'var(--surface)', color: 'var(--text-2)', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>{Icon.gear('var(--text-2)')}</button>
          <button onClick={nav.goAddMezzo} aria-label="Aggiungi mezzo" style={{ width: 38, height: 38, borderRadius: 99, background: 'var(--accent)', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', boxShadow: '0 1px 3px rgba(16,24,40,.2)' }}>{Icon.plus('#fff')}</button>
        </React.Fragment>} />

      <div style={{ flex: 1, overflow: 'auto', padding: '0 0 90px' }}>
        {/* search */}
        <div style={{ padding: '4px 16px 10px' }}>
          <div className="gm-input" style={{ display: 'flex', alignItems: 'center', gap: 9, height: 42 }}>
            {Icon.search('var(--text-3)')}
            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Cerca per targa, nome, modello…" style={{ border: 'none', outline: 'none', background: 'none', flex: 1, fontFamily: 'var(--sans)', fontSize: 15, color: 'var(--text)' }} />
            {q && <button onClick={() => setQ('')} style={{ border: 'none', background: 'var(--surface-2)', borderRadius: 99, width: 20, height: 20, cursor: 'pointer', color: 'var(--text-3)', fontSize: 13, lineHeight: 1 }}>✕</button>}
          </div>
        </div>

        {/* filter chips */}
        <div style={{ display: 'flex', gap: 8, padding: '0 16px 12px', overflowX: 'auto', WebkitOverflowScrolling: 'touch' }} className="gm-noscroll">
          <Chip active={!fStato && !fTipo} onClick={() => { setFStato(null); setFTipo(null); }}>Tutti</Chip>
          {Object.entries(STATI_MEZZO).map(([k, v]) => (
            <Chip key={k} active={fStato === k} dot={v.dot} onClick={() => setFStato(fStato === k ? null : k)}>{v.label}</Chip>
          ))}
          <span style={{ width: 1, alignSelf: 'center', height: 20, background: 'var(--border)', flexShrink: 0 }} />
          {TIPI_MEZZO.map(t => (
            <Chip key={t} active={fTipo === t} onClick={() => setFTipo(fTipo === t ? null : t)}>{t}</Chip>
          ))}
        </div>

        {/* urgency banner */}
        {urgenti > 0 && !fStato && !fTipo && !q && (
          <div style={{ margin: '0 16px 12px', padding: '11px 14px', borderRadius: 12, background: 'var(--bad-bg)', display: 'flex', alignItems: 'center', gap: 10 }}>
            {Icon.alert('var(--bad-fg)')}
            <span style={{ fontSize: 13.5, fontWeight: 600, color: 'var(--bad-fg)' }}>{urgenti} {urgenti === 1 ? 'mezzo richiede' : 'mezzi richiedono'} attenzione</span>
          </div>
        )}

        {/* list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: '0 16px' }}>
          {list.map(m => (
            <button key={m.id} onClick={() => nav.goMezzo(m.id)} className="gm-card-btn" style={{ textAlign: 'left', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 16, padding: 14, cursor: 'pointer', display: 'flex', gap: 13, alignItems: 'flex-start' }}>
              <TypeTile tipo={m.tipo} stato={m.stato} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
                  <span style={{ fontSize: 16, fontWeight: 650, color: 'var(--text)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{m.nome}</span>
                  <span style={{ fontFamily: 'var(--mono)', fontSize: 13, fontWeight: 600, color: 'var(--text-2)', flexShrink: 0, whiteSpace: 'nowrap' }}>{m.targa}</span>
                </div>
                <div style={{ fontSize: 13, color: 'var(--text-2)', marginTop: 2 }}>{m.marca} {m.modello} · {m.anno}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 11, flexWrap: 'wrap' }}>
                  <StatoBadge stato={m.stato} size="sm" />
                  <ProssimaPill iso={m.prossima} stato={m.stato} />
                  <span style={{ marginLeft: 'auto', fontFamily: 'var(--mono)', fontSize: 12.5, color: 'var(--text-3)', whiteSpace: 'nowrap' }}>{fmtKm(m.km)}</span>
                </div>
              </div>
            </button>
          ))}
          {list.length === 0 && (
            <div style={{ textAlign: 'center', padding: '50px 20px', color: 'var(--text-3)' }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--text-2)' }}>Nessun mezzo trovato</div>
              <div style={{ fontSize: 13.5, marginTop: 4 }}>Prova a modificare ricerca o filtri.</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 2 · FORM MEZZO (nuovo / modifica)
// ════════════════════════════════════════════════════════════
function FormMezzo({ mezzo, nav, onSave }) {
  const isEdit = !!mezzo;
  const [f, setF] = useS(mezzo || { nome: '', tipo: '', marca: '', modello: '', targa: '', anno: '', km: '', stato: 'attivo', prossima: '' });
  const set = (k, v) => setF(s => ({ ...s, [k]: v }));
  const valid = f.nome.trim() && f.targa.trim() && f.tipo;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TopBar title={isEdit ? 'Modifica mezzo' : 'Nuovo mezzo'} onBack={nav.back} />
      <div style={{ flex: 1, overflow: 'auto', padding: '16px 16px 24px', display: 'flex', flexDirection: 'column', gap: 18 }}>
        <Field label="Nome / identificativo" required>
          <TextInput value={f.nome} onChange={v => set('nome', v)} placeholder="es. Ambulanza Alfa-3" />
        </Field>
        <Field label="Tipo veicolo" required>
          <SelectField label="Tipo veicolo" value={f.tipo} placeholder="Seleziona tipo" options={TIPI_MEZZO} onChange={v => set('tipo', v)} />
        </Field>
        <div style={{ display: 'flex', gap: 12 }}>
          <div style={{ flex: 1 }}><Field label="Marca"><TextInput value={f.marca} onChange={v => set('marca', v)} placeholder="es. Fiat" /></Field></div>
          <div style={{ flex: 1 }}><Field label="Modello"><TextInput value={f.modello} onChange={v => set('modello', v)} placeholder="es. Ducato" /></Field></div>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <div style={{ flex: 1.3 }}><Field label="Targa" required><TextInput mono value={f.targa} onChange={v => set('targa', v.toUpperCase())} placeholder="AA 000 BB" /></Field></div>
          <div style={{ flex: 1 }}><Field label="Anno"><TextInput mono type="number" inputMode="numeric" value={f.anno} onChange={v => set('anno', v)} placeholder="2025" /></Field></div>
        </div>
        <Field label="Chilometraggio attuale" hint="In km. Per mezzi a ore di lavoro, inserire le ore.">
          <TextInput mono inputMode="numeric" value={f.km} onChange={v => set('km', v.replace(/\D/g, ''))} placeholder="0" />
        </Field>
        <Field label="Stato operativo">
          <SelectField label="Stato operativo" value={STATI_MEZZO[f.stato]?.label} placeholder="Seleziona" options={Object.values(STATI_MEZZO).map(s => s.label)} onChange={v => set('stato', Object.keys(STATI_MEZZO).find(k => STATI_MEZZO[k].label === v))} />
        </Field>
        <Field label="Prossima manutenzione prevista">
          <DateField value={f.prossima} onChange={v => set('prossima', v)} />
        </Field>
      </div>
      <FooterBar>
        <Btn full disabled={!valid} onClick={() => onSave(f)} icon={Icon.check('#fff')}>{isEdit ? 'Salva modifiche' : 'Aggiungi mezzo'}</Btn>
      </FooterBar>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 3 · SCHEDA MEZZO (dettaglio)
// ════════════════════════════════════════════════════════════
function DatoRow({ label, children, last }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '11px 0', borderBottom: last ? 'none' : '1px solid var(--hair)' }}>
      <span style={{ fontSize: 14, color: 'var(--text-2)' }}>{label}</span>
      <span style={{ fontSize: 14.5, fontWeight: 600, color: 'var(--text)', textAlign: 'right' }}>{children}</span>
    </div>
  );
}

function SchedaMezzo({ mezzo, nav, campiTipo = [] }) {
  if (!mezzo) return null;
  const storico = [...mezzo.manutenzioni].sort((a, b) => (b.data || '').localeCompare(a.data || ''));
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TopBar title={mezzo.nome} onBack={nav.back}
        action={<button onClick={() => nav.goEditMezzo(mezzo.id)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--accent)', fontFamily: 'var(--sans)', fontSize: 16, fontWeight: 500, padding: 6 }}>Modifica</button>} />
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px 100px' }}>
        {/* identity card */}
        <Card style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
          <TypeTile tipo={mezzo.tipo} stato={mezzo.stato} size={56} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--text)', lineHeight: 1.15 }}>{mezzo.nome}</div>
            <div style={{ fontSize: 13.5, color: 'var(--text-2)', marginTop: 1 }}>{mezzo.marca} {mezzo.modello}</div>
            <div style={{ marginTop: 9 }}><StatoBadge stato={mezzo.stato} size="sm" /></div>
          </div>
          <div style={{ alignSelf: 'flex-start', fontFamily: 'var(--mono)', fontSize: 14, fontWeight: 600, color: 'var(--text)', background: 'var(--surface-2)', padding: '5px 9px', borderRadius: 8, whiteSpace: 'nowrap' }}>{mezzo.targa}</div>
        </Card>

        {/* current data */}
        <div style={{ marginTop: 18 }}>
          <SectionLabel>Dati attuali</SectionLabel>
          <Card pad="2px 16px">
            <DatoRow label="Tipo veicolo">{mezzo.tipo}</DatoRow>
            <DatoRow label="Anno"><span style={{ fontFamily: 'var(--mono)' }}>{mezzo.anno || '—'}</span></DatoRow>
            <DatoRow label="Chilometraggio"><span style={{ fontFamily: 'var(--mono)' }}>{fmtKm(mezzo.km)}</span></DatoRow>
            <DatoRow label="Prossima manutenzione" last><ProssimaPill iso={mezzo.prossima} stato={mezzo.stato} /></DatoRow>
          </Card>
        </div>

        {/* nuova manutenzione */}
        <div style={{ marginTop: 16 }}>
          <Btn full onClick={() => nav.goNuovaManut(mezzo.id)} icon={Icon.plus('#fff')}>Nuova manutenzione</Btn>
        </div>

        {/* storico */}
        <div style={{ marginTop: 22 }}>
          <SectionLabel>{`Storico interventi (${storico.length})`}</SectionLabel>
          {storico.length === 0 ? (
            <Card style={{ textAlign: 'center', padding: '28px 20px' }}>
              <div style={{ fontSize: 14.5, fontWeight: 600, color: 'var(--text-2)' }}>Nessun intervento registrato</div>
              <div style={{ fontSize: 13, color: 'var(--text-3)', marginTop: 4 }}>Avvia la prima manutenzione con il pulsante qui sopra.</div>
            </Card>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {storico.map(mn => (
                <button key={mn.id} onClick={() => nav.goEditManut(mezzo.id, mn.id)} className="gm-card-btn" style={{ textAlign: 'left', background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 14, padding: 14, cursor: 'pointer' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
                    <span style={{ fontSize: 15.5, fontWeight: 650, color: 'var(--text)' }}>{mn.tipo}</span>
                    <EsitoBadge esito={mn.esito} />
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 6, flexWrap: 'wrap', fontSize: 13, color: 'var(--text-2)' }}>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>{Icon.cal('var(--text-3)')}<span style={{ fontFamily: 'var(--mono)' }}>{fmtData(mn.data)}</span></span>
                    <span style={{ color: 'var(--border)' }}>·</span>
                    <span>{mn.categoria}</span>
                    {mn.km !== '' && mn.km != null && (<><span style={{ color: 'var(--border)' }}>·</span><span style={{ fontFamily: 'var(--mono)', whiteSpace: 'nowrap' }}>{fmtKm(mn.km)}</span></>)}
                  </div>
                  {campiTipo.some(c => (mn.custom || {})[c.id]) && (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 9 }}>
                      {campiTipo.filter(c => (mn.custom || {})[c.id]).map(c => (
                        <span key={c.id} style={{ fontSize: 11.5, color: 'var(--text-2)', background: 'var(--surface-2)', padding: '3px 8px', borderRadius: 7 }}>
                          {c.label}: <strong style={{ fontWeight: 600, color: 'var(--text)' }}>{(mn.custom || {})[c.id]}</strong>
                        </span>
                      ))}
                    </div>
                  )}
                  {mn.note && <div style={{ fontSize: 13, color: 'var(--text-3)', marginTop: 8, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{mn.note}</div>}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// 4 · FORM MANUTENZIONE (nuova / modifica)
// ════════════════════════════════════════════════════════════
function FormManutenzione({ mezzo, manut, nav, onSave, onDelete, campiTipo = [] }) {
  const isEdit = !!manut;
  const [f, setF] = useS(manut || { tipo: '', categoria: '', data: oggi(), km: mezzo?.km ?? '', officina: '', esito: 'Programmata', costo: '', note: '', custom: {} });
  const set = (k, v) => setF(s => ({ ...s, [k]: v }));
  const setCustom = (id, v) => setF(s => ({ ...s, custom: { ...(s.custom || {}), [id]: v } }));
  const valid = f.tipo && f.data;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TopBar title={isEdit ? 'Modifica manutenzione' : 'Nuova manutenzione'} onBack={nav.back} />
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px 24px' }}>
        <div style={{ fontSize: 13, color: 'var(--text-2)', marginBottom: 16, padding: '10px 12px', background: 'var(--accent-soft)', borderRadius: 10, display: 'flex', gap: 8, alignItems: 'center' }}>
          <TypeTile tipo={mezzo.tipo} stato={mezzo.stato} size={32} />
          <div><div style={{ fontWeight: 650, color: 'var(--text)' }}>{mezzo.nome}</div><div style={{ fontFamily: 'var(--mono)', fontSize: 12, color: 'var(--text-2)' }}>{mezzo.targa}</div></div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          <Field label="Tipo di intervento" required>
            <SelectField label="Tipo di intervento" value={f.tipo} placeholder="Seleziona intervento" options={OPZ_TIPO_INTERVENTO} onChange={v => set('tipo', v)} />
          </Field>
          <Field label="Categoria">
            <SelectField label="Categoria" value={f.categoria} placeholder="Seleziona categoria" options={OPZ_CATEGORIA} onChange={v => set('categoria', v)} />
          </Field>
          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ flex: 1 }}><Field label="Data" required><DateField value={f.data} onChange={v => set('data', v)} /></Field></div>
            <div style={{ flex: 1 }}><Field label="Km / ore"><TextInput mono inputMode="numeric" value={f.km} onChange={v => set('km', String(v).replace(/\D/g, ''))} placeholder="0" /></Field></div>
          </div>
          <Field label="Officina / fornitore">
            <SelectField label="Officina / fornitore" value={f.officina} placeholder="Seleziona officina" options={OPZ_OFFICINA} onChange={v => set('officina', v)} />
          </Field>
          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ flex: 1 }}><Field label="Esito"><SelectField label="Esito" value={f.esito} placeholder="Seleziona" options={OPZ_ESITO} onChange={v => set('esito', v)} /></Field></div>
            <div style={{ flex: 1 }}><Field label="Costo"><TextInput mono inputMode="decimal" value={f.costo} onChange={v => set('costo', String(v).replace(/[^\d.,]/g, ''))} placeholder="€ 0,00" /></Field></div>
          </div>
          {campiTipo.length > 0 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 18, paddingTop: 4, marginTop: 2, borderTop: '1px solid var(--hair)' }}>
              <div style={{ fontSize: 12.5, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: 'var(--text-3)', marginTop: 8 }}>{`Campi ${mezzo.tipo}`}</div>
              {campiTipo.map(c => (
                <Field key={c.id} label={c.label}>
                  <CampoCustomInput campo={c} value={(f.custom || {})[c.id]} onChange={v => setCustom(c.id, v)} />
                </Field>
              ))}
            </div>
          )}
          <Field label="Note">
            <TextArea value={f.note} onChange={v => set('note', v)} placeholder="Annotazioni, ricambi utilizzati, raccomandazioni…" />
          </Field>
          {isEdit && (
            <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 2 }}>
              <Btn variant="ghost" danger icon={Icon.trash('var(--bad-fg)')} onClick={onDelete}>Elimina intervento</Btn>
            </div>
          )}
        </div>
      </div>
      <FooterBar>
        <Btn full disabled={!valid} onClick={() => onSave(f)} icon={Icon.check('#fff')}>Salva</Btn>
      </FooterBar>
    </div>
  );
}

// Sticky footer that floats above the home indicator
function FooterBar({ children }) {
  return (
    <div style={{ flexShrink: 0, padding: '12px 16px 30px', background: 'var(--bg)', borderTop: '1px solid var(--hair)', boxShadow: '0 -4px 16px rgba(16,24,40,.04)' }}>
      {children}
    </div>
  );
}

Object.assign(window, { ProssimaPill, ListaMezzi, FormMezzo, SchedaMezzo, FormManutenzione, FooterBar, DatoRow });
