import '../domain/maintenance_field.dart';
import '../../../services/supabase_service.dart';

class MaintenanceFieldRepository {
  /// Carica tutti i campi attivi, ordinati per sort_order.
  /// Include il join con vehicle_types per verificare type_id, ma restituisce
  /// solo i dati del campo (il filtro per tipo viene fatto lato client).
  Future<List<MaintenanceField>> fetchFields() async {
    final data = await supabase
        .from('maintenance_fields')
        .select()
        .eq('active', true)
        .order('sort_order');
    return (data as List).map((e) => MaintenanceField.fromJson(e)).toList();
  }
}
