// app.jsx — root orchestrator: navigation, data, picker, tweaks

const { useState: uS, useEffect: uE } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#1F62D6",
  "font": "IBM Plex Sans"
}/*EDITMODE-END*/;

function Toast({ msg }) {
  if (!msg) return null;
  return (
    <div style={{ position: 'absolute', bottom: 46, left: 0, right: 0, display: 'flex', justifyContent: 'center', zIndex: 90, pointerEvents: 'none' }}>
      <div className="gm-toast" style={{ display: 'inline-flex', alignItems: 'center', gap: 8, background: 'var(--text)', color: '#fff', padding: '11px 18px', borderRadius: 99, fontFamily: 'var(--sans)', fontSize: 14.5, fontWeight: 600, boxShadow: '0 8px 28px rgba(16,24,40,.3)' }}>
        {Icon.check('#fff')}{msg}
      </div>
    </div>
  );
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [mezzi, setMezzi] = uS(SEED_MEZZI);
  const [campi, setCampi] = uS(SEED_CAMPI);
  const [stack, setStack] = uS([{ screen: 'lista' }]);
  const [dir, setDir] = uS('push');
  const [picker, setPicker] = uS(null);
  const [toast, setToast] = uS('');

  const top = stack[stack.length - 1];
  const curMezzo = top.vehicleId ? mezzi.find(m => m.id === top.vehicleId) : null;

  const push = (entry) => { setDir('push'); setStack(s => [...s, entry]); };
  const back = () => { setDir('pop'); setStack(s => s.length > 1 ? s.slice(0, -1) : s); };
  const flash = (m) => { setToast(m); setTimeout(() => setToast(''), 1900); };

  const nav = {
    goAddMezzo: () => push({ screen: 'formMezzo' }),
    goEditMezzo: (id) => push({ screen: 'formMezzo', vehicleId: id }),
    goMezzo: (id) => push({ screen: 'mezzo', vehicleId: id }),
    goNuovaManut: (id) => push({ screen: 'formManut', vehicleId: id }),
    goEditManut: (id, mid) => push({ screen: 'formManut', vehicleId: id, manutId: mid }),
    goConfig: () => push({ screen: 'config' }),
    goAddCampo: (tipoVeicolo) => push({ screen: 'formCampo', tipoVeicolo }),
    goEditCampo: (tipoVeicolo, campoId) => push({ screen: 'formCampo', tipoVeicolo, campoId }),
    back,
  };

  const saveMezzo = (f) => {
    if (f.id) setMezzi(ms => ms.map(m => m.id === f.id ? { ...m, ...f } : m));
    else setMezzi(ms => [{ ...f, id: uid(), km: f.km === '' ? 0 : Number(f.km), manutenzioni: [] }, ...ms]);
    back(); flash(f.id ? 'Mezzo aggiornato' : 'Mezzo aggiunto');
  };

  const saveManut = (vehicleId, f) => {
    setMezzi(ms => ms.map(m => {
      if (m.id !== vehicleId) return m;
      const exists = m.manutenzioni.some(x => x.id === f.id);
      const manutenzioni = exists
        ? m.manutenzioni.map(x => x.id === f.id ? f : x)
        : [...m.manutenzioni, { ...f, id: uid() }];
      // riflette lo stato del mezzo in base all'esito
      let stato = m.stato;
      if (f.esito === 'In corso' || f.esito === 'Programmata') stato = 'manutenzione';
      else if (f.esito === 'Completata' && m.stato === 'manutenzione') stato = 'attivo';
      return { ...m, manutenzioni, stato };
    }));
    back(); flash(f.id ? 'Manutenzione aggiornata' : 'Manutenzione salvata');
  };

  const deleteManut = (vehicleId, mid) => {
    setMezzi(ms => ms.map(m => m.id === vehicleId ? { ...m, manutenzioni: m.manutenzioni.filter(x => x.id !== mid) } : m));
    back(); flash('Intervento eliminato');
  };

  const saveCampo = (tipoVeicolo, f) => {
    setCampi(c => {
      const list = c[tipoVeicolo] || [];
      const exists = list.some(x => x.id === f.id);
      const next = exists ? list.map(x => x.id === f.id ? f : x) : [...list, { ...f, id: uid() }];
      return { ...c, [tipoVeicolo]: next };
    });
    back(); flash(f.id ? 'Campo aggiornato' : 'Campo aggiunto');
  };

  const deleteCampo = (tipoVeicolo, campoId) => {
    setCampi(c => ({ ...c, [tipoVeicolo]: (c[tipoVeicolo] || []).filter(x => x.id !== campoId) }));
    back(); flash('Campo eliminato');
  };

  let screen;
  if (top.screen === 'lista') screen = <ListaMezzi mezzi={mezzi} nav={nav} />;
  else if (top.screen === 'formMezzo') screen = <FormMezzo mezzo={curMezzo} nav={nav} onSave={saveMezzo} />;
  else if (top.screen === 'mezzo') screen = <SchedaMezzo mezzo={curMezzo} nav={nav} campiTipo={campi[curMezzo?.tipo] || []} />;
  else if (top.screen === 'config') screen = <ConfigCampi campi={campi} nav={nav} />;
  else if (top.screen === 'formCampo') {
    const campo = top.campoId ? (campi[top.tipoVeicolo] || []).find(x => x.id === top.campoId) : null;
    screen = <FormCampo tipoVeicolo={top.tipoVeicolo} campo={campo} nav={nav}
      onSave={(f) => saveCampo(top.tipoVeicolo, f)} onDelete={() => deleteCampo(top.tipoVeicolo, top.campoId)} />;
  }
  else if (top.screen === 'formManut') {
    const manut = top.manutId ? curMezzo.manutenzioni.find(x => x.id === top.manutId) : null;
    screen = <FormManutenzione mezzo={curMezzo} manut={manut} nav={nav} campiTipo={campi[curMezzo?.tipo] || []}
      onSave={(f) => saveManut(curMezzo.id, f)} onDelete={() => deleteManut(curMezzo.id, top.manutId)} />;
  }

  const rootVars = {
    '--accent': t.accent,
    '--accent-soft': `color-mix(in srgb, ${t.accent} 13%, white)`,
    '--sans': `'${t.font}', -apple-system, system-ui, sans-serif`,
    height: '100%', position: 'relative', overflow: 'hidden', background: 'var(--bg)',
  };

  return (
    <PickerCtx.Provider value={setPicker}>
      <div style={rootVars}>
        <div key={stack.length + top.screen + (top.vehicleId || '') + (top.manutId || '') + (top.tipoVeicolo || '') + (top.campoId || '')} className={dir === 'push' ? 'scr-push' : 'scr-pop'} style={{ position: 'absolute', inset: 0 }}>
          {screen}
        </div>
        <SheetPicker state={picker} onClose={(val) => { if (val !== undefined) picker.onSelect(val); setPicker(null); }} />
        <Toast msg={toast} />
        <TweaksPanel title="Tweaks">
          <TweakSection label="Colore" />
          <TweakColor label="Accento" value={t.accent}
            options={['#1F62D6', '#0E7C7B', '#3A4B8A', '#475569']}
            onChange={(v) => setTweak('accent', v)} />
          <TweakSection label="Tipografia" />
          <TweakSelect label="Font interfaccia" value={t.font}
            options={['IBM Plex Sans', 'Manrope', 'Public Sans']}
            onChange={(v) => setTweak('font', v)} />
        </TweaksPanel>
      </div>
    </PickerCtx.Provider>
  );
}

function Root() {
  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24, boxSizing: 'border-box', background: 'var(--stage)' }}>
      <IOSDevice>
        <App />
      </IOSDevice>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<Root />);
