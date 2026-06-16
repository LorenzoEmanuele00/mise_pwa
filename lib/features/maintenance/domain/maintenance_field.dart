enum MaintenanceFieldType { dropdown, text, number }

class MaintenanceField {
  final String id;
  final String fieldKey;   // chiave nel JSONB custom_fields
  final String label;
  final MaintenanceFieldType fieldType;
  final List<String> options; // per dropdown
  final String? typeId;       // null = tutti i tipi di mezzo
  final int sortOrder;
  final bool tracksExpiry;    // se true: mostra date-picker scadenza nel form

  const MaintenanceField({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.options,
    this.typeId,
    required this.sortOrder,
    this.tracksExpiry = false,
  });

  factory MaintenanceField.fromJson(Map<String, dynamic> json) {
    return MaintenanceField(
      id: json['id'] as String,
      fieldKey: json['field_key'] as String,
      label: json['label'] as String,
      fieldType: _parseType(json['field_type'] as String),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      typeId: json['type_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      tracksExpiry: json['tracks_expiry'] as bool? ?? false,
    );
  }

  static MaintenanceFieldType _parseType(String v) => switch (v) {
        'dropdown' => MaintenanceFieldType.dropdown,
        'number' => MaintenanceFieldType.number,
        _ => MaintenanceFieldType.text,
      };
}
