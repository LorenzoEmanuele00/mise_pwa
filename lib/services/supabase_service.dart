import 'package:supabase_flutter/supabase_flutter.dart';

/// Punto d'accesso centralizzato al client Supabase.
/// Usare `supabase` invece di `Supabase.instance.client` nei repository.
SupabaseClient get supabase => Supabase.instance.client;
