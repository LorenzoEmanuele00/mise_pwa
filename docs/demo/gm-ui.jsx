// gm-ui.jsx — shared UI primitives for Gestione Mezzi

const { createContext, useContext, useState } = React;

// Context that lets any field open the bottom-sheet picker owned by App
const PickerCtx = createContext(() => {});
const usePicker = () => useContext(PickerCtx);

// ── Icons (simple glyphs only) ───────────────────────────────
const Icon = {
  back: (c = 'currentColor') => <svg width="11" height="18" viewBox="0 0 11 18" fill="none"><path d="M9.5 1.5L2 9l7.5 7.5" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  chevR: (c = 'currentColor') => <svg width="8" height="13" viewBox="0 0 8 13" fill="none"><path d="M1.5 1l5.5 5.5L1.5 12" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  plus: (c = 'currentColor') => <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M9 2v14M2 9h14" stroke={c} strokeWidth="2.2" strokeLinecap="round"/></svg>,
  search: (c = 'currentColor') => <svg width="17" height="17" viewBox="0 0 17 17" fill="none"><circle cx="7" cy="7" r="5.4" stroke={c} strokeWidth="1.8"/><path d="M11.2 11.2L16 16" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
  cal: (c = 'currentColor') => <svg width="16" height="16" viewBox="0 0 16 16" fill="none"><rect x="1.5" y="2.7" width="13" height="11.8" rx="2.2" stroke={c} strokeWidth="1.6"/><path d="M1.5 6h13M5 1.2v2.6M11 1.2v2.6" stroke={c} strokeWidth="1.6" strokeLinecap="round"/></svg>,
  check: (c = 'currentColor') => <svg width="15" height="15" viewBox="0 0 15 15" fill="none"><path d="M2 8l3.8 4L13 3.2" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  clock: (c = 'currentColor') => <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="5.6" stroke={c} strokeWidth="1.5"/><path d="M7 3.8V7l2.4 1.6" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  alert: (c = 'currentColor') => <svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M7 1.5l5.8 10H1.2L7 1.5z" stroke={c} strokeWidth="1.5" strokeLinejoin="round"/><path d="M7 5.6v2.6M7 10.1v.05" stroke={c} strokeWidth="1.6" strokeLinecap="round"/></svg>,
  trash: (c = 'currentColor') => <svg width="15" height="15" viewBox="0 0 15 15" fill="none"><path d="M2.5 3.5h10M6 3.5V2.3h3v1.2M3.6 3.5l.6 9.2h6.6l.6-9.2" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  filter: (c = 'currentColor') => <svg width="15" height="15" viewBox="0 0 15 15" fill="none"><path d="M1 2.5h13M3.5 7h8M6 11.5h3" stroke={c} strokeWidth="1.7" strokeLinecap="round"/></svg>,
  gear: (c = 'currentColor') => <svg width="19" height="19" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="2.6" stroke={c} strokeWidth="1.6"/><path d="M10 1.6v2M10 16.4v2M3.5 3.5l1.4 1.4M15.1 15.1l1.4 1.4M1.6 10h2M16.4 10h2M3.5 16.5l1.4-1.4M15.1 4.9l1.4-1.4" stroke={c} strokeWidth="1.6" strokeLinecap="round"/></svg>,
};

const TIPO_ABBR = { 'Ambulanza': 'AMB', 'Automedica': 'MED', 'Furgone': 'FUR', 'Auto di servizio': 'SRV' };

// ── Type tile ────────────────────────────────────────────────
function TypeTile({ tipo, stato, size = 46 }) {
  const cfg = STATI_MEZZO[stato] || {};
  return (
    <div style={{
      width: size, height: size, borderRadius: 12, flexShrink: 0,
      background: 'var(--surface-2)', border: '1px solid var(--border)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      position: 'relative',
    }}>
      <span style={{ fontFamily: 'var(--mono)', fontSize: size * 0.27, fontWeight: 600, letterSpacing: 0.5, color: 'var(--text-2)' }}>
        {TIPO_ABBR[tipo] || '—'}
      </span>
      <span style={{
        position: 'absolute', top: -3, right: -3, width: 12, height: 12, borderRadius: 99,
        background: cfg.dot, border: '2px solid var(--surface)',
      }} />
    </div>
  );
}

// ── Badges ───────────────────────────────────────────────────
function StatoBadge({ stato, size = 'md' }) {
  const c = STATI_MEZZO[stato]; if (!c) return null;
  const pad = size === 'sm' ? '3px 8px' : '4px 10px';
  const fs = size === 'sm' ? 11.5 : 12.5;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: pad, borderRadius: 99, background: c.bg, color: c.fg, fontSize: fs, fontWeight: 600, whiteSpace: 'nowrap' }}>
      <span style={{ width: 6, height: 6, borderRadius: 99, background: c.dot }} />
      {c.label}
    </span>
  );
}

function EsitoBadge({ esito }) {
  const c = ESITO_CFG[esito] || { fg: 'var(--text-2)', bg: 'var(--surface-2)' };
  return <span style={{ padding: '3px 9px', borderRadius: 99, background: c.bg, color: c.fg, fontSize: 11.5, fontWeight: 600, whiteSpace: 'nowrap' }}>{esito}</span>;
}

// ── Buttons ──────────────────────────────────────────────────
function Btn({ children, onClick, variant = 'primary', full, icon, disabled, danger }) {
  const base = { display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8, height: 50, padding: '0 18px', borderRadius: 14, fontFamily: 'var(--sans)', fontSize: 16, fontWeight: 600, cursor: disabled ? 'not-allowed' : 'pointer', border: 'none', width: full ? '100%' : undefined, opacity: disabled ? 0.5 : 1, transition: 'transform .08s, filter .15s', WebkitTapHighlightColor: 'transparent' };
  const styles = {
    primary:   { ...base, background: 'var(--accent)', color: '#fff', boxShadow: '0 1px 2px rgba(16,24,40,.18)' },
    secondary: { ...base, background: 'var(--surface)', color: 'var(--text)', border: '1px solid var(--border)' },
    ghost:     { ...base, background: 'transparent', color: danger ? 'var(--bad-fg)' : 'var(--accent)', height: 44 },
  };
  return (
    <button style={styles[variant]} onClick={disabled ? undefined : onClick}
      onMouseDown={e => { if (!disabled) e.currentTarget.style.transform = 'scale(.975)'; }}
      onMouseUp={e => e.currentTarget.style.transform = ''}
      onMouseLeave={e => e.currentTarget.style.transform = ''}>
      {icon}{children}
    </button>
  );
}

function Chip({ children, active, onClick, dot }) {
  return (
    <button onClick={onClick} style={{
      display: 'inline-flex', alignItems: 'center', gap: 6, height: 34, padding: '0 13px', borderRadius: 99,
      fontFamily: 'var(--sans)', fontSize: 13.5, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap',
      border: active ? '1px solid var(--accent)' : '1px solid var(--border)',
      background: active ? 'var(--accent-soft)' : 'var(--surface)',
      color: active ? 'var(--accent)' : 'var(--text-2)', transition: 'all .12s',
    }}>
      {dot && <span style={{ width: 7, height: 7, borderRadius: 99, background: dot }} />}
      {children}
    </button>
  );
}

// ── Header bar ───────────────────────────────────────────────
function TopBar({ title, subtitle, onBack, action, large }) {
  return (
    <div style={{ flexShrink: 0, paddingTop: 50, background: 'var(--bg)', borderBottom: large ? 'none' : '1px solid var(--hair)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 12px 10px', minHeight: 44 }}>
        {onBack && (
          <button onClick={onBack} style={{ display: 'flex', alignItems: 'center', gap: 3, background: 'none', border: 'none', cursor: 'pointer', color: 'var(--accent)', fontFamily: 'var(--sans)', fontSize: 16, fontWeight: 500, padding: '6px 6px 6px 2px', marginLeft: -2 }}>
            {Icon.back('var(--accent)')}
          </button>
        )}
        {!large && <div style={{ flex: 1, textAlign: 'center', fontFamily: 'var(--sans)', fontSize: 16.5, fontWeight: 600, color: 'var(--text)' }}>{title}</div>}
        <div style={{ marginLeft: large ? 'auto' : 0, display: 'flex', alignItems: 'center', gap: 4, minWidth: onBack && !large ? 30 : undefined, justifyContent: 'flex-end' }}>{action}</div>
      </div>
      {large && (
        <div style={{ padding: '2px 18px 14px' }}>
          <div style={{ fontFamily: 'var(--sans)', fontSize: 30, fontWeight: 700, letterSpacing: -0.5, color: 'var(--text)' }}>{title}</div>
          {subtitle && <div style={{ fontSize: 14, color: 'var(--text-2)', marginTop: 3 }}>{subtitle}</div>}
        </div>
      )}
    </div>
  );
}

// ── Form atoms ───────────────────────────────────────────────
function Field({ label, children, hint, required }) {
  return (
    <label style={{ display: 'block' }}>
      <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-2)', marginBottom: 7, letterSpacing: 0.1 }}>
        {label}{required && <span style={{ color: 'var(--bad-fg)' }}> *</span>}
      </div>
      {children}
      {hint && <div style={{ fontSize: 12, color: 'var(--text-3)', marginTop: 6 }}>{hint}</div>}
    </label>
  );
}

function TextInput({ value, onChange, placeholder, mono, type = 'text', inputMode }) {
  return <input className={'gm-input' + (mono ? ' gm-mono' : '')} type={type} inputMode={inputMode} value={value ?? ''} placeholder={placeholder} onChange={e => onChange(e.target.value)} />;
}

function TextArea({ value, onChange, placeholder }) {
  return <textarea className="gm-input gm-area" value={value ?? ''} placeholder={placeholder} onChange={e => onChange(e.target.value)} rows={4} />;
}

function DateField({ value, onChange }) {
  return (
    <div className="gm-input gm-select" style={{ position: 'relative' }}>
      <span style={{ fontFamily: 'var(--mono)', fontSize: 15, color: value ? 'var(--text)' : 'var(--text-3)' }}>{value ? fmtData(value) : 'gg/mm/aaaa'}</span>
      <span style={{ color: 'var(--text-3)', display: 'flex' }}>{Icon.cal('var(--text-3)')}</span>
      <input type="date" value={value || ''} onChange={e => onChange(e.target.value)} style={{ position: 'absolute', inset: 0, opacity: 0, width: '100%', height: '100%', cursor: 'pointer' }} />
    </div>
  );
}

// Select that opens the App-level bottom sheet
function SelectField({ value, placeholder, options, onChange, label }) {
  const openPicker = usePicker();
  return (
    <button className="gm-input gm-select" type="button" onClick={() => openPicker({ title: label, options, value, onSelect: onChange })}>
      <span style={{ flex: 1, minWidth: 0, fontSize: 15, color: value ? 'var(--text)' : 'var(--text-3)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{value || placeholder}</span>
      <span style={{ color: 'var(--text-3)', display: 'flex' }}>{Icon.chevR('var(--text-3)')}</span>
    </button>
  );
}

// Card / section helpers
function Card({ children, pad = 16, style }) {
  return <div style={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 16, padding: pad, ...style }}>{children}</div>;
}
function SectionLabel({ children, action }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px 9px', marginTop: 4 }}>
      <span style={{ fontSize: 12.5, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', color: 'var(--text-3)' }}>{children}</span>
      {action}
    </div>
  );
}

// ── Bottom-sheet picker ──────────────────────────────────────
function SheetPicker({ state, onClose }) {
  const [closing, setClosing] = useState(false);
  if (!state) return null;
  const close = (val) => {
    setClosing(true);
    setTimeout(() => { setClosing(false); onClose(val); }, 180);
  };
  return (
    <div onClick={() => close(undefined)} style={{ position: 'absolute', inset: 0, zIndex: 80, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(10,16,24,.38)', opacity: closing ? 0 : 1, transition: 'opacity .18s' }} />
      <div onClick={e => e.stopPropagation()} style={{
        position: 'relative', background: 'var(--surface)', borderRadius: '22px 22px 0 0',
        paddingBottom: 30, maxHeight: '74%', display: 'flex', flexDirection: 'column',
        transform: closing ? 'translateY(100%)' : 'translateY(0)', transition: 'transform .2s cubic-bezier(.32,.72,0,1)',
        boxShadow: '0 -8px 40px rgba(10,16,24,.2)',
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', paddingTop: 10 }}>
          <div style={{ width: 38, height: 5, borderRadius: 99, background: 'var(--border)' }} />
        </div>
        <div style={{ padding: '10px 18px 8px', fontFamily: 'var(--sans)', fontSize: 14, fontWeight: 700, color: 'var(--text-3)', textTransform: 'uppercase', letterSpacing: 0.5 }}>{state.title}</div>
        <div style={{ overflow: 'auto', padding: '0 12px' }}>
          {state.options.map((opt, i) => {
            const sel = opt === state.value;
            return (
              <button key={i} onClick={() => close(opt)} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%',
                padding: '14px 10px', background: 'none', border: 'none', cursor: 'pointer',
                borderBottom: i < state.options.length - 1 ? '1px solid var(--hair)' : 'none',
                fontFamily: 'var(--sans)', fontSize: 16.5, fontWeight: sel ? 600 : 450,
                color: sel ? 'var(--accent)' : 'var(--text)', textAlign: 'left',
              }}>
                {opt}{sel && Icon.check('var(--accent)')}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  PickerCtx, usePicker, Icon, TypeTile, StatoBadge, EsitoBadge, Btn, Chip, TopBar,
  Field, TextInput, TextArea, DateField, SelectField, Card, SectionLabel, SheetPicker, TIPO_ABBR,
});
