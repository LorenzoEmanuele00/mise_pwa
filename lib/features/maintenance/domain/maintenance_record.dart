/// Colonne strutturali di maintenance_records.
/// I campi di stato (tagliando, revisione, ecc.) sono stati migrati a
/// custom_fields (JSONB) e sono ora pilotati dalla tabella maintenance_fields.
class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int? km;
  final String? notes;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    this.km,
    this.notes,
    required this.customFields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        date: DateTime.parse(json['date'] as String),
        km: json['km'] as int?,
        notes: json['notes'] as String?,
        customFields:
            (json['custom_fields'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Legge il valore di un campo dinamico dal JSONB.
  String? value(String fieldKey) => customFields[fieldKey] as String?;

  /// Chiave nel JSONB dove viene salvata la data di scadenza di un campo.
  static String expiryKey(String fieldKey) => '${fieldKey}_scadenza';

  /// Legge la data di scadenza di un campo (null se non impostata).
  DateTime? expiry(String fieldKey) {
    final raw = customFields[expiryKey(fieldKey)];
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }
}

class CreateMaintenanceInput {
  final String vehicleId;
  final DateTime date;
  final int? km;
  final String? notes;
  final Map<String, dynamic> customFields;

  const CreateMaintenanceInput({
    required this.vehicleId,
    required this.date,
    this.km,
    this.notes,
    this.customFields = const {},
  });

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        'km': km,
        'notes': notes,
        'custom_fields': customFields,
      };
}
