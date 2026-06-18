// B1: Unit test puri sui domain model e helper — nessuna dipendenza da Supabase
// o Flutter widget. Coprono fromJson, helper di conversione e logica di filtro.

import 'package:flutter_test/flutter_test.dart';
import 'package:mise_pwa/features/maintenance/data/maintenance_providers.dart';
import 'package:mise_pwa/features/maintenance/domain/maintenance_field.dart';
import 'package:mise_pwa/features/maintenance/domain/maintenance_record.dart';
import 'package:mise_pwa/features/vehicles/domain/vehicle.dart';

void main() {
  // ── VehicleType ────────────────────────────────────────────────
  group('VehicleType', () {
    test('fromJson – abbreviation da mappa codice noto (ambulance → AMB)', () {
      final t = VehicleType.fromJson({
        'id': 't1',
        'code': 'ambulance',
        'label': 'Ambulanza',
        'is_custom': false,
        'abbreviation': null,
      });
      expect(t.abbreviation, 'AMB');
    });

    test('fromJson – abbreviation override vince sul codice noto', () {
      final t = VehicleType.fromJson({
        'id': 't2',
        'code': 'ambulance',
        'label': 'Ambulanza',
        'is_custom': false,
        'abbreviation': 'AMB2',
      });
      expect(t.abbreviation, 'AMB2');
    });

    test('fromJson – abbreviation fallback: prime 3 lettere del label', () {
      final t = VehicleType.fromJson({
        'id': 't3',
        'code': 'custom_type',
        'label': 'Furgone',
        'is_custom': true,
        'abbreviation': null,
      });
      expect(t.abbreviation, 'FUR');
    });

    test('fromJson – label corto non crasha (clamp 0-3)', () {
      final t = VehicleType.fromJson({
        'id': 't4',
        'code': 'x',
        'label': 'AB',
        'is_custom': true,
        'abbreviation': null,
      });
      expect(t.abbreviation, isNotEmpty);
    });
  });

  // ── Vehicle ────────────────────────────────────────────────────
  group('Vehicle.fromJson', () {
    Map<String, dynamic> baseJson({
      String? alias,
      Map<String, dynamic>? vehicleTypes,
    }) =>
        {
          'id': 'v1',
          'plate': 'AA 000 BB',
          'alias': alias,
          'type_id': vehicleTypes != null ? 't1' : null,
          'vehicle_types': vehicleTypes,
          'year': 2021,
          'notes': null,
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
        };

    test('displayName = alias se presente', () {
      final v = Vehicle.fromJson(baseJson(alias: 'Alfa-1'));
      expect(v.displayName, 'Alfa-1');
    });

    test('displayName = plate se alias è null', () {
      final v = Vehicle.fromJson(baseJson());
      expect(v.displayName, 'AA 000 BB');
    });

    test('vehicleType parsato dal join vehicle_types', () {
      final v = Vehicle.fromJson(baseJson(
        vehicleTypes: {
          'id': 't1',
          'code': 'ambulance',
          'label': 'Ambulanza',
          'is_custom': false,
          'abbreviation': null,
        },
      ));
      expect(v.vehicleType, isNotNull);
      expect(v.vehicleType!.code, 'ambulance');
    });

    test('vehicleType è null se vehicle_types assente nel JSON', () {
      final v = Vehicle.fromJson(baseJson());
      expect(v.vehicleType, isNull);
    });
  });

  // ── CreateVehicleTypeInput.labelToCode ─────────────────────────
  group('CreateVehicleTypeInput.labelToCode', () {
    test('lower-case + spazi → underscore', () {
      expect(
          CreateVehicleTypeInput.labelToCode('Furgone Trasporto'),
          'furgone_trasporto');
    });

    test('accenti italiani normalizzati', () {
      expect(CreateVehicleTypeInput.labelToCode('Ambulànzà'), 'ambulanza');
    });

    test('trim leading/trailing underscores', () {
      expect(CreateVehicleTypeInput.labelToCode(' Mezzo '), 'mezzo');
    });

    test('underscore multipli collassati', () {
      expect(CreateVehicleTypeInput.labelToCode('a  --  b'), 'a_b');
    });
  });

  // ── MaintenanceRecord ──────────────────────────────────────────
  group('MaintenanceRecord', () {
    late MaintenanceRecord record;

    setUp(() {
      record = MaintenanceRecord.fromJson({
        'id': 'r1',
        'vehicle_id': 'v1',
        'date': '2024-06-01',
        'km': 12345,
        'notes': 'note di test',
        'custom_fields': {
          'tagliando': 'OK',
          'km_count': 50000, // valore numerico (int) nel JSONB
          'revisione_scadenza': '2025-12-31',
        },
        'created_at': '2024-06-01T00:00:00.000Z',
        'updated_at': '2024-06-01T00:00:00.000Z',
      });
    });

    test('fromJson: campi strutturali', () {
      expect(record.id, 'r1');
      expect(record.vehicleId, 'v1');
      expect(record.km, 12345);
      expect(record.notes, 'note di test');
    });

    test('value() restituisce stringa per campo stringa', () {
      expect(record.value('tagliando'), 'OK');
    });

    // C3: il fix ?.toString() deve gestire valori JSONB numerici senza crash
    test('value() restituisce stringa per valore JSONB numerico (no crash)', () {
      expect(record.value('km_count'), '50000');
    });

    test('value() restituisce null per chiave mancante', () {
      expect(record.value('non_esiste'), isNull);
    });

    test('expiryKey costruisce la chiave _scadenza', () {
      expect(MaintenanceRecord.expiryKey('revisione'), 'revisione_scadenza');
    });

    test('expiry() legge la data di scadenza', () {
      final exp = record.expiry('revisione');
      expect(exp, isNotNull);
      expect(exp!.year, 2025);
      expect(exp.month, 12);
      expect(exp.day, 31);
    });

    test('expiry() restituisce null per chiave mancante', () {
      expect(record.expiry('non_esiste'), isNull);
    });

    test('expiry() restituisce null per stringa non ISO valida', () {
      final r = MaintenanceRecord.fromJson({
        'id': 'r2',
        'vehicle_id': 'v1',
        'date': '2024-01-01',
        'km': null,
        'notes': null,
        'custom_fields': {'foo_scadenza': 'data-non-valida'},
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      });
      expect(r.expiry('foo'), isNull);
    });
  });

  // ── MaintenanceField.fromJson ──────────────────────────────────
  group('MaintenanceField.fromJson', () {
    test('campo dropdown globale', () {
      final f = MaintenanceField.fromJson({
        'id': 'f1',
        'field_key': 'tagliando',
        'label': 'Tagliando',
        'field_type': 'dropdown',
        'options': ['OK', 'Da fare', 'N/A'],
        'type_id': null,
        'sort_order': 10,
        'tracks_expiry': false,
        'active': true,
      });
      expect(f.fieldKey, 'tagliando');
      expect(f.fieldType, MaintenanceFieldType.dropdown);
      expect(f.options, ['OK', 'Da fare', 'N/A']);
      expect(f.typeId, isNull);
      expect(f.tracksExpiry, isFalse);
    });

    test('campo date-only con tracksExpiry', () {
      final f = MaintenanceField.fromJson({
        'id': 'f2',
        'field_key': 'revisione',
        'label': 'Revisione',
        'field_type': 'dropdown',
        'options': null,
        'type_id': 'some-type-id',
        'sort_order': 5,
        'tracks_expiry': true,
        'active': true,
      });
      expect(f.tracksExpiry, isTrue);
      expect(f.options, isEmpty);
      expect(f.typeId, 'some-type-id');
    });

    test('field_type sconosciuto → text', () {
      final f = MaintenanceField.fromJson({
        'id': 'f3',
        'field_key': 'x',
        'label': 'X',
        'field_type': 'unknown',
        'options': [],
        'type_id': null,
        'sort_order': 0,
        'tracks_expiry': false,
        'active': false,
      });
      expect(f.fieldType, MaintenanceFieldType.text);
      expect(f.active, isFalse);
    });
  });

  // ── CreateMaintenanceFieldInput.labelToKey ─────────────────────
  group('CreateMaintenanceFieldInput.labelToKey', () {
    test('conversione base', () {
      expect(
          CreateMaintenanceFieldInput.labelToKey('Tagliando motore'),
          'tagliando_motore');
    });

    test('accenti', () {
      expect(
          CreateMaintenanceFieldInput.labelToKey('Sanificazionè cabinà'),
          'sanificazione_cabina');
    });

    test('separatori multipli collassati', () {
      expect(CreateMaintenanceFieldInput.labelToKey('a  -  b'), 'a_b');
    });

    test('trim underscore bordi', () {
      expect(CreateMaintenanceFieldInput.labelToKey('  abc  '), 'abc');
    });
  });

  // ── fieldsForType ──────────────────────────────────────────────
  group('fieldsForType', () {
    MaintenanceField makeField(
      String key, {
      String? typeId,
      int sortOrder = 0,
    }) =>
        MaintenanceField(
          id: key,
          fieldKey: key,
          label: key,
          fieldType: MaintenanceFieldType.text,
          options: [],
          typeId: typeId,
          sortOrder: sortOrder,
        );

    final global = makeField('global', sortOrder: 10);
    final typeA = makeField('typeA', typeId: 'type-A', sortOrder: 5);
    final typeB = makeField('typeB', typeId: 'type-B', sortOrder: 1);

    test('include globale + tipo corrispondente, esclude altri tipi', () {
      final result = fieldsForType([global, typeA, typeB], 'type-A');
      expect(result.map((f) => f.fieldKey), containsAll(['global', 'typeA']));
      expect(result.map((f) => f.fieldKey), isNot(contains('typeB')));
    });

    test('vehicleTypeId null → solo campi globali', () {
      final result = fieldsForType([global, typeA, typeB], null);
      expect(result.map((f) => f.fieldKey), equals(['global']));
    });

    test('risultati ordinati per sortOrder', () {
      final result = fieldsForType([global, typeA], 'type-A');
      // typeA sortOrder=5, global sortOrder=10 → typeA prima
      expect(result.first.fieldKey, 'typeA');
      expect(result.last.fieldKey, 'global');
    });

    test('lista vuota → lista vuota', () {
      expect(fieldsForType([], 'type-A'), isEmpty);
    });
  });
}
