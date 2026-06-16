import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/maintenance_record.dart';
import 'maintenance_repository.dart';

final maintenanceRepositoryProvider =
    Provider<MaintenanceRepository>((_) => MaintenanceRepository());

// List of records for a vehicle (ordered by date DESC)
final maintenanceRecordsProvider =
    FutureProvider.family<List<MaintenanceRecord>, String>((ref, vehicleId) {
  return ref.read(maintenanceRepositoryProvider).fetchRecords(vehicleId);
});

// Single record (for edit initialization)
final maintenanceRecordProvider =
    FutureProvider.family<MaintenanceRecord, String>((ref, id) {
  return ref.read(maintenanceRepositoryProvider).fetchRecord(id);
});
