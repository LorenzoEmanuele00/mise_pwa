import '../../features/maintenance/domain/maintenance_field.dart';
import '../../features/maintenance/domain/maintenance_record.dart';
import '../../features/vehicles/domain/vehicle.dart';

/// Costruisce una stringa CSV con lo storico manutenzioni di un mezzo.
///
/// Separatore: `;` (compatibilità Excel italiano).
/// Prefissata con BOM UTF-8 per la corretta visualizzazione degli accenti.
/// Righe terminate con CRLF.
///
/// Colonne in ordine:
///   1. Data (dd/MM/yyyy)
///   2. Km
///   3. Per ogni [fields] in sortOrder:
///      - Colonna valore con `field.label` come header, **saltata** per campi
///        "solo data" (tracksExpiry == true && options.isEmpty).
///      - Colonna `"{field.label} (scadenza)"` se tracksExpiry == true.
///   4. Note
String buildMaintenanceCsv({
  required Vehicle vehicle,
  required List<MaintenanceRecord> records,
  required List<MaintenanceField> fields,
}) {
  const sep = ';';
  const nl = '\r\n';

  // Ordina in modo difensivo per sortOrder (fieldsForType lo fa già,
  // ma il builder rimane corretto anche se riceve campi non ordinati).
  final sortedFields = [...fields]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // ── Intestazioni ──────────────────────────────────────────────
  final headers = <String>['Data', 'Km'];
  for (final f in sortedFields) {
    // Campo "solo data": salva SOLO la chiave _scadenza; nessuna colonna valore.
    final isPureDate = f.tracksExpiry && f.options.isEmpty;
    if (!isPureDate) headers.add(f.label);
    if (f.tracksExpiry) headers.add('${f.label} (scadenza)');
  }
  headers.add('Note');

  final buf = StringBuffer();
  buf.write('﻿'); // BOM UTF-8
  buf.write(headers.map(_csvCell).join(sep));
  buf.write(nl);

  // ── Righe dati ────────────────────────────────────────────────
  for (final r in records) {
    final row = <String>[
      _fmtDate(r.date),
      r.km?.toString() ?? '',
    ];
    for (final f in sortedFields) {
      final isPureDate = f.tracksExpiry && f.options.isEmpty;
      if (!isPureDate) row.add(r.value(f.fieldKey) ?? '');
      if (f.tracksExpiry) {
        final exp = r.expiry(f.fieldKey);
        row.add(exp != null ? _fmtDate(exp) : '');
      }
    }
    row.add(r.notes ?? '');
    buf.write(row.map(_csvCell).join(sep));
    buf.write(nl);
  }

  return buf.toString();
}

/// Nome file CSV: `manutenzioni_{TARGA}_{yyyy-MM-dd}.csv`
String csvFilename(Vehicle vehicle) {
  final plate = vehicle.plate
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '_');
  final now = DateTime.now();
  final date = '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  return 'manutenzioni_${plate}_$date.csv';
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

/// Escaping CSV: racchiude tra virgolette se il valore contiene `;`, `"`, `\n`
/// o `\r`; raddoppia le virgolette interne.
String _csvCell(String value) {
  if (value.contains(';') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
