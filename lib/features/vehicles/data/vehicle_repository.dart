import '../domain/vehicle.dart';
import '../../../services/supabase_service.dart';

class VehicleRepository {
  Future<List<VehicleType>> fetchVehicleTypes() async {
    final data = await supabase
        .from('vehicle_types')
        .select()
        .order('is_custom')
        .order('label');
    return (data as List).map((e) => VehicleType.fromJson(e)).toList();
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final data = await supabase
        .from('vehicles')
        .select('*, vehicle_types(*)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => Vehicle.fromJson(e)).toList();
  }

  Future<Vehicle> fetchVehicle(String id) async {
    final data = await supabase
        .from('vehicles')
        .select('*, vehicle_types(*)')
        .eq('id', id)
        .single();
    return Vehicle.fromJson(data);
  }

  Future<String> createVehicle(CreateVehicleInput input) async {
    final data = await supabase
        .from('vehicles')
        .insert(input.toJson())
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> updateVehicle(String id, CreateVehicleInput input) async {
    await supabase.from('vehicles').update(input.toJson()).eq('id', id);
  }

  Future<void> deleteVehicle(String id) async {
    await supabase.from('vehicles').delete().eq('id', id);
  }

  // ── Vehicle types CRUD (per Settings) ────────────────────────

  Future<String> createVehicleType(CreateVehicleTypeInput input) async {
    final data = await supabase
        .from('vehicle_types')
        .insert(input.toJson())
        .select('id')
        .single();
    return data['id'] as String;
  }

  /// Aggiorna solo label e abbreviation (code e is_custom non sono modificabili).
  Future<void> updateVehicleType(
    String id, {
    required String label,
    String? abbreviation,
  }) async {
    await supabase.from('vehicle_types').update({
      'label': label,
      'abbreviation': abbreviation?.trim().isEmpty == true ? null : abbreviation?.trim(),
    }).eq('id', id);
  }

  /// ⚠️ vehicle_types usa ON DELETE RESTRICT: fallisce se ci sono veicoli
  /// associati. Catturare PostgrestException con code '23503' nel caller.
  Future<void> deleteVehicleType(String id) async {
    await supabase.from('vehicle_types').delete().eq('id', id);
  }
}
