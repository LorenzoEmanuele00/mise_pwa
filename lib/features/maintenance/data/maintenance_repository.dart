import '../domain/maintenance_record.dart';
import '../../../services/supabase_service.dart';

class MaintenanceRepository {
  Future<List<MaintenanceRecord>> fetchRecords(String vehicleId) async {
    final data = await supabase
        .from('maintenance_records')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);
    return (data as List).map((e) => MaintenanceRecord.fromJson(e)).toList();
  }

  Future<MaintenanceRecord> fetchRecord(String id) async {
    final data = await supabase
        .from('maintenance_records')
        .select()
        .eq('id', id)
        .single();
    return MaintenanceRecord.fromJson(data);
  }

  Future<String> createRecord(CreateMaintenanceInput input) async {
    final data = await supabase
        .from('maintenance_records')
        .insert(input.toJson())
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> updateRecord(String id, CreateMaintenanceInput input) async {
    await supabase
        .from('maintenance_records')
        .update(input.toJson())
        .eq('id', id);
  }

  Future<void> deleteRecord(String id) async {
    await supabase.from('maintenance_records').delete().eq('id', id);
  }
}
