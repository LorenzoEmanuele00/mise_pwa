import '../domain/maintenance_field.dart';
import '../../../services/supabase_service.dart';

class MaintenanceFieldRepository {
  /// Carica tutti i campi **attivi**, ordinati per sort_order.
  /// Usato dal form manutenzione (non mostra i campi disattivati).
  Future<List<MaintenanceField>> fetchFields() async {
    final data = await supabase
        .from('maintenance_fields')
        .select()
        .eq('active', true)
        .order('sort_order');
    return (data as List).map((e) => MaintenanceField.fromJson(e)).toList();
  }

  /// Carica **tutti** i campi (inclusi disattivati), ordinati per sort_order.
  /// Usato dalla schermata Impostazioni per il CRUD completo.
  Future<List<MaintenanceField>> fetchAllFields() async {
    final data = await supabase
        .from('maintenance_fields')
        .select()
        .order('sort_order');
    return (data as List).map((e) => MaintenanceField.fromJson(e)).toList();
  }

  /// Carica un singolo campo per id (inclusi disattivati).
  Future<MaintenanceField> fetchField(String id) async {
    final data = await supabase
        .from('maintenance_fields')
        .select()
        .eq('id', id)
        .single();
    return MaintenanceField.fromJson(data);
  }

  Future<String> createField(CreateMaintenanceFieldInput input) async {
    final data = await supabase
        .from('maintenance_fields')
        .insert(input.toJson())
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<void> updateField(String id, CreateMaintenanceFieldInput input) async {
    await supabase
        .from('maintenance_fields')
        .update(input.toJson())
        .eq('id', id);
  }

  Future<void> deleteField(String id) async {
    await supabase.from('maintenance_fields').delete().eq('id', id);
  }
}
