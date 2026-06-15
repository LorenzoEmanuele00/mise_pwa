// gm-config.jsx — pannello "Campi personalizzati" per tipo di mezzo

const { useState: uSc } = React;

// Renders a single custom field's input inside the maintenance form
function CampoCustomInput({ campo, value, onChange }) {
  if (campo.tipo === 'select')
    return <SelectField label={campo.label} value={value} placeholder={'Seleziona ' + campo.label.toLowerCase()} options={campo.opzioni || []} onChange={onChange} />;
  if (campo.tipo === 'numero')
    return <TextInput mono inputMode="numeric" value={value} onChange={v => onChange(String(v).replace(/\D/g, ''))} placeholder="0" />;
  if (campo.tipo === 'data')
    return <DateField value={value} onChange={onChange} />;
  return <TextInput value={value} onChange={onChange} placeholder={campo.label} />;
}

function TipoCampoBadge({ tipo }) {
  return <span style={{ padding: '2px 8px', borderRadius: 7, background: 'var(--surface-2)', color: 'var(--text-2)', fontSize: 11, fontWeight: 600 }}>{TIPO_CAMPO_LABEL[tipo]}</span>;
}

// ════════════════════════════════════════════════════════════
// CONFIG — elenco tipi con i loro campi personalizzati
// ════════════════════════════════════════════════════════════
function ConfigCampi({ campi, nav }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TopBar title="Campi personalizzati" onBack={nav.back} />
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px 28px' }}>
        <div style={{ fontSize: 13.5, color: 'var(--text-2)', lineHeight: 1.5, padding: '0 2px 16px' }}>
          Aggiungi campi extra alle schede di manutenzione. I campi definiti qui compaiono solo per i mezzi del tipo corrispondente.
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {TIPI_MEZZO.map(tipo => {
            const list = campi[tipo] || [];
            return (
              <div key={tipo}>
                <SectionLabel>{`${tipo}${list.length ? ' · ' + list.length : ''}`}</SectionLabel>
                <Card pad={list.length ? '4px 14px 14px' : 14}>
                  {list.length === 0 ? (
                    <div style={{ fontSize: 13.5, color: 'var(--text-3)', padding: '8px 2px 14px' }}>Nessun campo personalizzato.</div>
                  ) : (
                    list.map((c, i) => (
                      <button key={c.id} onClick={() => nav.goEditCampo(tipo, c.id)} style={{
                        display: 'flex', alignItems: 'center', gap: 10, width: '100%', textAlign: 'left',
                        background: 'none', border: 'none', cursor: 'pointer', padding: '12px 2px',
                        borderBottom: '1px solid var(--hair)',
                      }}>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--text)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.label}</div>
                          {c.tipo === 'select' && c.opzioni?.length > 0 && (
                            <div style={{ fontSize: 12.5, color: 'var(--text-3)', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.opzioni.join(' · ')}</div>
                          )}
                        </div>
                        <TipoCampoBadge tipo={c.tipo} />
                        <span style={{ display: 'flex' }}>{Icon.chevR('var(--text-3)')}</span>
                      </button>
                    ))
                  )}
                  <button onClick={() => nav.goAddCampo(tipo)} style={{
                    display: 'flex', alignItems: 'center', gap: 8, width: '100%',
                    background: 'none', border: 'none', cursor: 'pointer', padding: list.length ? '14px 2px 4px' : '4px 2px',
                    color: 'var(--accent)', fontFamily: 'var(--sans)', fontSize: 14.5, fontWeight: 600,
                  }}>
                    {Icon.plus('var(--accent)')}Aggiungi campo
                  </button>
                </Card>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
// FORM CAMPO — crea / modifica un campo personalizzato
// ════════════════════════════════════════════════════════════
function FormCampo({ tipoVeicolo, campo, nav, onSave, onDelete }) {
  const isEdit = !!campo;
  const [f, setF] = uSc(campo || { label: '', tipo: 'select', opzioni: ['', ''] });
  const set = (k, v) => setF(s => ({ ...s, [k]: v }));
  const setOpt = (i, v) => setF(s => { const o = [...s.opzioni]; o[i] = v; return { ...s, opzioni: o }; });
  const addOpt = () => setF(s => ({ ...s, opzioni: [...s.opzioni, ''] }));
  const rmOpt = (i) => setF(s => ({ ...s, opzioni: s.opzioni.filter((_, j) => j !== i) }));

  const isSelect = f.tipo === 'select';
  const cleanOpts = (f.opzioni || []).map(o => o.trim()).filter(Boolean);
  const valid = f.label.trim() && (!isSelect || cleanOpts.length >= 1);

  const save = () => onSave({ ...f, label: f.label.trim(), opzioni: isSelect ? cleanOpts : undefined });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TopBar title={isEdit ? 'Modifica campo' : 'Nuovo campo'} onBack={nav.back} />
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px 24px' }}>
        <div style={{ fontSize: 12.5, color: 'var(--text-2)', marginBottom: 16, padding: '9px 12px', background: 'var(--accent-soft)', borderRadius: 10 }}>
          Questo campo apparirà nelle manutenzioni dei mezzi di tipo <strong style={{ color: 'var(--text)' }}>{tipoVeicolo}</strong>.
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          <Field label="Nome del campo" required>
            <TextInput value={f.label} onChange={v => set('label', v)} placeholder="es. Sanificazione cabina" />
          </Field>

          <Field label="Tipo di campo">
            <SelectField label="Tipo di campo" value={TIPI_CAMPO.find(t => t.id === f.tipo)?.label}
              placeholder="Seleziona" options={TIPI_CAMPO.map(t => t.label)}
              onChange={(lbl) => set('tipo', TIPI_CAMPO.find(t => t.label === lbl).id)} />
          </Field>

          {isSelect && (
            <div>
              <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-2)', marginBottom: 7 }}>Opzioni della tendina <span style={{ color: 'var(--bad-fg)' }}>*</span></div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
                {f.opzioni.map((o, i) => (
                  <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                    <div style={{ flex: 1 }}><TextInput value={o} onChange={v => setOpt(i, v)} placeholder={`Opzione ${i + 1}`} /></div>
                    <button onClick={() => rmOpt(i)} disabled={f.opzioni.length <= 1} style={{
                      width: 40, height: 40, flexShrink: 0, borderRadius: 11, border: '1px solid var(--border)',
                      background: 'var(--surface)', cursor: f.opzioni.length <= 1 ? 'not-allowed' : 'pointer',
                      opacity: f.opzioni.length <= 1 ? 0.4 : 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>{Icon.trash('var(--text-3)')}</button>
                  </div>
                ))}
              </div>
              <button onClick={addOpt} style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 11, background: 'none', border: 'none', cursor: 'pointer', color: 'var(--accent)', fontFamily: 'var(--sans)', fontSize: 14, fontWeight: 600, padding: '2px' }}>
                {Icon.plus('var(--accent)')}Aggiungi opzione
              </button>
            </div>
          )}

          {isEdit && (
            <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 2 }}>
              <Btn variant="ghost" danger icon={Icon.trash('var(--bad-fg)')} onClick={onDelete}>Elimina campo</Btn>
            </div>
          )}
        </div>
      </div>
      <FooterBar>
        <Btn full disabled={!valid} onClick={save} icon={Icon.check('#fff')}>{isEdit ? 'Salva campo' : 'Aggiungi campo'}</Btn>
      </FooterBar>
    </div>
  );
}

Object.assign(window, { CampoCustomInput, ConfigCampi, FormCampo, TipoCampoBadge });
