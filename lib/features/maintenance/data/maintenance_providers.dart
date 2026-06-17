import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/maintenance_field.dart';
import '../domain/maintenance_record.dart';
import 'maintenance_field_repository.dart';
import 'maintenance_repository.dart';

// ── Repository providers ──────────────────────────────────────
final maintenanceRepositoryProvider =
    Provider<MaintenanceRepository>((_) => MaintenanceRepository());

final maintenanceFieldRepositoryProvider =
    Provider<MaintenanceFieldRepository>((_) => MaintenanceFieldRepository());

// ── Field definitions (all active, ordered by sort_order) ─────
// Usato dal form manutenzione. Mostra solo i campi active = true.
final maintenanceFieldsProvider =
    FutureProvider<List<MaintenanceField>>((ref) {
  return ref.read(maintenanceFieldRepositoryProvider).fetchFields();
});

// ── All fields (inclusi disattivati) — per la UI Impostazioni ─
class MaintenanceFieldsNotifier
    extends AsyncNotifier<List<MaintenanceField>> {
  @override
  Future<List<MaintenanceField>> build() {
    return ref.read(maintenanceFieldRepositoryProvider).fetchAllFields();
  }

  Future<void> create(CreateMaintenanceFieldInput input) async {
    await ref.read(maintenanceFieldRepositoryProvider).createField(input);
    ref.invalidateSelf();
    ref.invalidate(maintenanceFieldsProvider);
  }

  Future<void> save(String id, CreateMaintenanceFieldInput input) async {
    await ref.read(maintenanceFieldRepositoryProvider).updateField(id, input);
    ref.invalidateSelf();
    ref.invalidate(maintenanceFieldsProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(maintenanceFieldRepositoryProvider).deleteField(id);
    ref.invalidateSelf();
    ref.invalidate(maintenanceFieldsProvider);
  }
}

final allMaintenanceFieldsProvider =
    AsyncNotifierProvider<MaintenanceFieldsNotifier, List<MaintenanceField>>(
        MaintenanceFieldsNotifier.new);

// ── Records for a vehicle (ordered by date DESC) ─────────────
final maintenanceRecordsProvider =
    FutureProvider.family<List<MaintenanceRecord>, String>((ref, vehicleId) {
  return ref.read(maintenanceRepositoryProvider).fetchRecords(vehicleId);
});

// ── Single record (for edit initialization) ───────────────────
final maintenanceRecordProvider =
    FutureProvider.family<MaintenanceRecord, String>((ref, id) {
  return ref.read(maintenanceRepositoryProvider).fetchRecord(id);
});

// ── Helper: filter fields visible for a given vehicle type ────
/// Returns fields where typeId is null (global) OR matches [vehicleTypeId].
List<MaintenanceField> fieldsForType(
  List<MaintenanceField> all,
  String? vehicleTypeId,
) {
  return all
      .where((f) => f.typeId == null || f.typeId == vehicleTypeId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
