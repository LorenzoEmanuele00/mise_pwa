import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
// Il refresh dell'auth guard è gestito da GoRouterRefreshStream in router.dart,
// che ascolta Supabase.instance.client.auth.onAuthStateChange direttamente.
