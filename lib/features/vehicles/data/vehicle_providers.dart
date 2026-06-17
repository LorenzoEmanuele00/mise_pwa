import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/vehicle.dart';
import 'vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((_) => VehicleRepository());

// ── Vehicle types (quasi-static, cached) ──────────────────────
final vehicleTypesProvider = FutureProvider<List<VehicleType>>((ref) {
  return ref.read(vehicleRepositoryProvider).fetchVehicleTypes();
});

// ── Single vehicle (for detail/edit) ──────────────────────────
final vehicleProvider = FutureProvider.family<Vehicle, String>((ref, id) {
  return ref.read(vehicleRepositoryProvider).fetchVehicle(id);
});

// ── Vehicles list (mutable, supports CRUD) ────────────────────
class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() {
    return ref.read(vehicleRepositoryProvider).fetchVehicles();
  }

  Future<String> create(CreateVehicleInput input) async {
    final id = await ref.read(vehicleRepositoryProvider).createVehicle(input);
    ref.invalidateSelf();
    return id;
  }

  Future<void> save(String id, CreateVehicleInput input) async {
    await ref.read(vehicleRepositoryProvider).updateVehicle(id, input);
    ref.invalidateSelf();
    ref.invalidate(vehicleProvider(id));
  }

  Future<void> delete(String id) async {
    await ref.read(vehicleRepositoryProvider).deleteVehicle(id);
    ref.invalidateSelf();
  }
}

final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(VehiclesNotifier.new);
