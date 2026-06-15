import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/vehicles/presentation/vehicle_list_screen.dart';

/// Percorsi dell'applicazione.
abstract final class AppRoutes {
  static const login = '/login';
  static const vehicles = '/';
  static const vehicleDetail = '/vehicles/:id';
  static const vehicleNew = '/vehicles/new';
  static const maintenance = '/vehicles/:id/maintenance';
  static const maintenanceNew = '/vehicles/:id/maintenance/new';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.vehicles,
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isOnLogin = state.matchedLocation == AppRoutes.login;

    if (session == null && !isOnLogin) {
      // Nessuna sessione attiva → vai al login
      return AppRoutes.login;
    }
    if (session != null && isOnLogin) {
      // Già autenticato → vai all'app
      return AppRoutes.vehicles;
    }
    return null; // nessun redirect
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.vehicles,
      builder: (context, state) => const VehicleListScreen(),
      routes: [
        GoRoute(
          path: 'vehicles/:id',
          builder: (context, state) {
            // TODO Fase 3: VehicleDetailScreen
            return const Scaffold(body: Center(child: Text('Dettaglio mezzo')));
          },
          routes: [
            GoRoute(
              path: 'maintenance',
              builder: (context, state) {
                // TODO Fase 4: MaintenanceListScreen
                return const Scaffold(
                    body: Center(child: Text('Manutenzioni')));
              },
            ),
            GoRoute(
              path: 'maintenance/new',
              builder: (context, state) {
                // TODO Fase 4: MaintenanceFormScreen
                return const Scaffold(
                    body: Center(child: Text('Nuova manutenzione')));
              },
            ),
          ],
        ),
        GoRoute(
          path: 'vehicles/new',
          builder: (context, state) {
            // TODO Fase 3: VehicleFormScreen
            return const Scaffold(body: Center(child: Text('Nuovo mezzo')));
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) {
            // TODO Fase 5: SettingsScreen
            return const Scaffold(
                body: Center(child: Text('Impostazioni')));
          },
        ),
      ],
    ),
  ],
);
