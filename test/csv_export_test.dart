import 'package:flutter_test/flutter_test.dart';
import 'package:mise_pwa/features/maintenance/domain/maintenance_field.dart';
import 'package:mise_pwa/features/maintenance/domain/maintenance_record.dart';
import 'package:mise_pwa/features/vehicles/domain/vehicle.dart';
import 'package:mise_pwa/shared/utils/csv_export.dart';

void main() {
  // ── Helper factories ─────────────────────────────────────────

  Vehicle makeVehicle({String plate = 'AB 123 CD'}) => Vehicle(
        id: 'v1',
        plate: plate,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  MaintenanceField makeField({
    required String fieldKey,
    required String label,
    bool tracksExpiry = false,
    List<String> options = const [],
    int sortOrder = 0,
  }) =>
      MaintenanceField(
        id: 'f_$fieldKey',
        fieldKey: fieldKey,
        label: label,
        fieldType: options.isEmpty
            ? MaintenanceFieldType.text
            : MaintenanceFieldType.dropdown,
        options: options,
        sortOrder: sortOrder,
        tracksExpiry: tracksExpiry,
      );

  MaintenanceRecord makeRecord({
    DateTime? date,
    int? km,
    String? notes,
    Map<String, dynamic> customFields = const {},
  }) =>
      MaintenanceRecord(
        id: 'r1',
        vehicleId: 'v1',
        date: date ?? DateTime(2024, 3, 15),
        km: km,
        notes: notes,
        customFields: customFields,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  // Ritorna le righe non vuote (salta BOM dalla prima riga)
  List<String> rows(String csv) =>
      csv.split('\r\n').where((l) => l.isNotEmpty).toList();

  List<String> cells(String row) => row.split(';');

  // ── buildMaintenanceCsv ──────────────────────────────────────

  group('buildMaintenanceCsv', () {
    test('inizia con BOM UTF-8', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord()],
        fields: [],
      );
      expect(csv.startsWith('﻿'), isTrue);
    });

    test('righe terminate con CRLF', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord()],
        fields: [],
      );
      // Rimuove il BOM
      final content = csv.replaceFirst('﻿', '');
      expect(content.contains('\r\n'), isTrue);
    });

    test('separatore è punto e virgola', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord(km: 1000)],
        fields: [],
      );
      final header = rows(csv)[0];
      expect(header.contains(';'), isTrue);
    });

    test('header contiene Data, Km, Note', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord()],
        fields: [],
      );
      final header = rows(csv)[0];
      expect(header, contains('Data'));
      expect(header, contains('Km'));
      expect(header, contains('Note'));
    });

    test('nessun record: solo header (1 riga)', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [],
        fields: [],
      );
      expect(rows(csv).length, 1);
    });

    test('data formattata come dd/MM/yyyy con zeri iniziali', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord(date: DateTime(2024, 1, 5))],
        fields: [],
      );
      expect(csv, contains('05/01/2024'));
    });

    test('km vuoto se null', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord(km: null)],
        fields: [],
      );
      final dataRow = rows(csv)[1];
      expect(cells(dataRow)[1], ''); // indice 1 = Km
    });

    test('km come stringa intera se valorizzato', () {
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord(km: 12345)],
        fields: [],
      );
      final dataRow = rows(csv)[1];
      expect(cells(dataRow)[1], '12345');
    });

    // ── Campo standard (senza tracksExpiry) ─────────────────────

    test('colonna valore per campo standard', () {
      final field = makeField(fieldKey: 'tagliando', label: 'Tagliando');
      final record = makeRecord(customFields: {'tagliando': 'Effettuato'});
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [record],
        fields: [field],
      );
      final header = rows(csv)[0];
      final dataRow = rows(csv)[1];
      expect(header, contains('Tagliando'));
      expect(dataRow, contains('Effettuato'));
    });

    // ── Campo con scadenza (tracksExpiry, options non vuote) ─────

    test('colonne valore e scadenza per campo con tracksExpiry', () {
      final field = makeField(
        fieldKey: 'revisione',
        label: 'Revisione',
        tracksExpiry: true,
        options: ['OK', 'In scadenza'],
      );
      final record = makeRecord(customFields: {
        'revisione': 'OK',
        'revisione_scadenza': '2025-06-30',
      });
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [record],
        fields: [field],
      );
      final header = rows(csv)[0];
      final dataRow = rows(csv)[1];
      expect(header, contains('Revisione'));
      expect(header, contains('Revisione (scadenza)'));
      expect(dataRow, contains('OK'));
      expect(dataRow, contains('30/06/2025'));
    });

    test('scadenza vuota se non presente nel record', () {
      final field = makeField(
        fieldKey: 'revisione',
        label: 'Revisione',
        tracksExpiry: true,
        options: ['OK'],
      );
      final record = makeRecord(customFields: {'revisione': 'OK'});
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [record],
        fields: [field],
      );
      final dataRow = rows(csv)[1];
      // Celle: Data;Km;Revisione;Revisione (scadenza);Note
      final c = cells(dataRow);
      expect(c[3], ''); // scadenza vuota
    });

    // ── Campo solo-data (tracksExpiry && options.isEmpty) ────────

    test('campo solo-data: solo colonna scadenza, nessuna colonna valore', () {
      final field = makeField(
        fieldKey: 'assicurazione',
        label: 'Assicurazione',
        tracksExpiry: true,
        options: [], // pura data
      );
      final record = makeRecord(customFields: {
        'assicurazione_scadenza': '2025-12-31',
      });
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [record],
        fields: [field],
      );
      final headerCells = cells(rows(csv)[0]);
      // Deve esserci "Assicurazione (scadenza)"
      expect(headerCells.contains('Assicurazione (scadenza)'), isTrue);
      // "Assicurazione" da solo NON deve essere una colonna
      expect(headerCells.where((c) => c == 'Assicurazione').isEmpty, isTrue);
      // Il valore della data deve comparire nel CSV
      expect(csv, contains('31/12/2025'));
    });

    // ── Escaping ─────────────────────────────────────────────────

    test('punto e virgola nel valore viene racchiuso tra virgolette', () {
      final field = makeField(fieldKey: 'desc', label: 'Descrizione');
      final record =
          makeRecord(customFields: {'desc': 'valore; con separatore'});
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [record],
        fields: [field],
      );
      expect(csv, contains('"valore; con separatore"'));
    });

    test('virgolette nel valore vengono raddoppiate', () {
      final record = makeRecord(notes: 'dice "ciao"');
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [record],
        fields: [],
      );
      expect(csv, contains('"dice ""ciao"""'));
    });

    test('a-capo nelle note viene racchiuso tra virgolette', () {
      final record = makeRecord(notes: 'riga1\nriga2');
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [record],
        fields: [],
      );
      expect(csv, contains('"riga1\nriga2"'));
    });

    // ── Ordine colonne ───────────────────────────────────────────

    test('i campi appaiono in ordine di sortOrder', () {
      final fields = [
        makeField(fieldKey: 'b', label: 'Campo B', sortOrder: 2),
        makeField(fieldKey: 'a', label: 'Campo A', sortOrder: 1),
      ];
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord()],
        fields: fields,
      );
      final header = rows(csv)[0];
      expect(
        header.indexOf('Campo A') < header.indexOf('Campo B'),
        isTrue,
        reason: 'Campo A (sortOrder=1) deve precedere Campo B (sortOrder=2)',
      );
    });

    test('Note è sempre l\'ultima colonna', () {
      final field = makeField(fieldKey: 'x', label: 'Campo X');
      final csv = buildMaintenanceCsv(
        vehicle: makeVehicle(),
        records: [makeRecord()],
        fields: [field],
      );
      final headerCells = cells(rows(csv)[0]);
      expect(headerCells.last, 'Note');
    });
  });

  // ── csvFilename ──────────────────────────────────────────────

  group('csvFilename', () {
    test('inizia con "manutenzioni_" e finisce con ".csv"', () {
      final name = csvFilename(makeVehicle());
      expect(name, startsWith('manutenzioni_'));
      expect(name, endsWith('.csv'));
    });

    test('contiene la targa maiuscola con spazi sostituiti da _', () {
      final name = csvFilename(makeVehicle(plate: 'ab 123 cd'));
      expect(name, contains('AB_123_CD'));
    });

    test('caratteri speciali nella targa vengono sanitizzati', () {
      final name = csvFilename(makeVehicle(plate: 'XX-999-ZZ'));
      // I trattini nella targa diventano underscore
      expect(name, contains('XX_999_ZZ'));
      // La targa originale con trattini non compare (ma la data usa "-" e va bene)
      expect(name, isNot(contains('XX-999-ZZ')));
    });
  });
}
