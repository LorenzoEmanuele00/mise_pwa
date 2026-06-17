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
  final bool active;          // false = nascosto senza perdere i dati storici

  const MaintenanceField({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.options,
    this.typeId,
    required this.sortOrder,
    this.tracksExpiry = false,
    this.active = true,
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
      active: json['active'] as bool? ?? true,
    );
  }

  static MaintenanceFieldType _parseType(String v) => switch (v) {
        'dropdown' => MaintenanceFieldType.dropdown,
        'number' => MaintenanceFieldType.number,
        _ => MaintenanceFieldType.text,
      };

  /// Enum → stringa DB ('dropdown' | 'number' | 'text').
  static String typeToDb(MaintenanceFieldType t) => switch (t) {
        MaintenanceFieldType.dropdown => 'dropdown',
        MaintenanceFieldType.number => 'number',
        MaintenanceFieldType.text => 'text',
      };
}

// ── Input class per create / update ───────────────────────────
class CreateMaintenanceFieldInput {
  final String fieldKey;
  final String label;
  final MaintenanceFieldType fieldType;
  final List<String> options;
  final String? typeId;
  final int sortOrder;
  final bool active;
  final bool tracksExpiry;

  const CreateMaintenanceFieldInput({
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.options,
    this.typeId,
    required this.sortOrder,
    required this.active,
    required this.tracksExpiry,
  });

  Map<String, dynamic> toJson() => {
        'field_key': fieldKey,
        'label': label,
        'field_type': MaintenanceField.typeToDb(fieldType),
        'options': options,
        'type_id': typeId,
        'sort_order': sortOrder,
        'active': active,
        'tracks_expiry': tracksExpiry,
      };

  /// Genera un field_key valido (snake_case, solo a-z0-9_) da un'etichetta.
  /// ⚠️ Il field_key è la chiave nei JSONB custom_fields: non va mai cambiato
  /// dopo la creazione, altrimenti i dati storici diventano irraggiungibili.
  static String labelToKey(String label) {
    return label
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
