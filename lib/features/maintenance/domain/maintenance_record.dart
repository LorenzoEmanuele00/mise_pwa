class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int? km;
  final String? tagliando;
  final String? revisione;
  final String? luci;
  final String? lampeggianti;
  final String? sirene;
  final String? spazzole;
  final String? distribuzione;
  final String? inverter;
  final String? batteriaServizi;
  final String? ruote;
  final String? assicurazione;
  final String? notes;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    this.km,
    this.tagliando,
    this.revisione,
    this.luci,
    this.lampeggianti,
    this.sirene,
    this.spazzole,
    this.distribuzione,
    this.inverter,
    this.batteriaServizi,
    this.ruote,
    this.assicurazione,
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
        tagliando: json['tagliando'] as String?,
        revisione: json['revisione'] as String?,
        luci: json['luci'] as String?,
        lampeggianti: json['lampeggianti'] as String?,
        sirene: json['sirene'] as String?,
        spazzole: json['spazzole'] as String?,
        distribuzione: json['distribuzione'] as String?,
        inverter: json['inverter'] as String?,
        batteriaServizi: json['batteria_servizi'] as String?,
        ruote: json['ruote'] as String?,
        assicurazione: json['assicurazione'] as String?,
        notes: json['notes'] as String?,
        customFields:
            (json['custom_fields'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class CreateMaintenanceInput {
  final String vehicleId;
  final DateTime date;
  final int? km;
  final String? tagliando;
  final String? revisione;
  final String? luci;
  final String? lampeggianti;
  final String? sirene;
  final String? spazzole;
  final String? distribuzione;
  final String? inverter;
  final String? batteriaServizi;
  final String? ruote;
  final String? assicurazione;
  final String? notes;
  final Map<String, dynamic> customFields;

  const CreateMaintenanceInput({
    required this.vehicleId,
    required this.date,
    this.km,
    this.tagliando,
    this.revisione,
    this.luci,
    this.lampeggianti,
    this.sirene,
    this.spazzole,
    this.distribuzione,
    this.inverter,
    this.batteriaServizi,
    this.ruote,
    this.assicurazione,
    this.notes,
    this.customFields = const {},
  });

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
        'km': km,
        'tagliando': tagliando,
        'revisione': revisione,
        'luci': luci,
        'lampeggianti': lampeggianti,
        'sirene': sirene,
        'spazzole': spazzole,
        'distribuzione': distribuzione,
        'inverter': inverter,
        'batteria_servizi': batteriaServizi,
        'ruote': ruote,
        'assicurazione': assicurazione,
        'notes': notes,
        'custom_fields': customFields,
      };
}
