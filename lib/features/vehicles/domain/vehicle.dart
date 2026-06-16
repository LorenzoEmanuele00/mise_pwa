import 'package:flutter/material.dart';

class VehicleType {
  final String id;
  final String code;
  final String label;
  final bool isCustom;
  /// Abbreviazione definita a DB (colonna `abbreviation` su vehicle_types).
  /// Se null, si usa il fallback basato sul codice / prime lettere del label.
  final String? abbreviationOverride;

  const VehicleType({
    required this.id,
    required this.code,
    required this.label,
    required this.isCustom,
    this.abbreviationOverride,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) => VehicleType(
        id: json['id'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        isCustom: json['is_custom'] as bool? ?? false,
        abbreviationOverride: json['abbreviation'] as String?,
      );

  String get abbreviation {
    if (abbreviationOverride != null && abbreviationOverride!.isNotEmpty) {
      return abbreviationOverride!;
    }
    const map = {
      'ambulance': 'AMB',
      'equipped_vehicle': 'ATT',
      'car': 'AUTO',
    };
    return map[code] ??
        label.substring(0, label.length.clamp(0, 3)).toUpperCase();
  }

  Color get tileColor => const Color(0xFFF0F4FF);
}

class Vehicle {
  final String id;
  final String plate;
  final String? alias;
  final String? typeId;
  final VehicleType? vehicleType;
  final int? year;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.plate,
    this.alias,
    this.typeId,
    this.vehicleType,
    this.year,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        plate: json['plate'] as String,
        alias: json['alias'] as String?,
        typeId: json['type_id'] as String?,
        vehicleType: json['vehicle_types'] != null
            ? VehicleType.fromJson(json['vehicle_types'] as Map<String, dynamic>)
            : null,
        year: json['year'] as int?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'plate': plate,
        'alias': alias,
        'type_id': typeId,
        'year': year,
        'notes': notes,
      };

  String get displayName => (alias?.isNotEmpty == true) ? alias! : plate;
}

class CreateVehicleInput {
  final String plate;
  final String? alias;
  final String? typeId;
  final int? year;
  final String? notes;

  const CreateVehicleInput({
    required this.plate,
    this.alias,
    this.typeId,
    this.year,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'plate': plate.toUpperCase().trim(),
        'alias': alias?.trim().isEmpty == true ? null : alias?.trim(),
        'type_id': typeId,
        'year': year,
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      };
}
