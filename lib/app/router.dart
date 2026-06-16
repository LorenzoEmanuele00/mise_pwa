import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/vehicles/presentation/vehicle_list_screen.dart';
import '../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../features/vehicles/presentation/vehicle_form_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const vehicleNew = '/vehicles/new';
  static const vehicleDetail = '/vehicles/:id';
  static const vehicleEdit = '/vehicles/:id/edit';
  static const maintenanceList = '/vehicles/:id/maintenance';
  static const maintenanceNew = '/vehicles/:id/maintenance/new';
  static const settings = '/settings';
}

// Static name for vehicles root (to avoid ambiguity with vehicleNew)
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final onLogin = state.matchedLocation == AppRoutes.login;

    if (session == null && !onLogin) return AppRoutes.login;
    if (session != null && onLogin) return AppRoutes.home;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, _) => const VehicleListScreen(),
    ),
    // NOTE: vehicleNew MUST come before vehicleDetail so '/vehicles/new'
    // is not matched as id='new'
    GoRoute(
      path: AppRoutes.vehicleNew,
      builder: (_, _) => const VehicleFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.vehicleDetail,
      builder: (_, state) =>
          VehicleDetailScreen(vehicleId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (_, state) =>
              VehicleFormScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'maintenance',
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Manutenzioni — Fase 4')),
          ),
        ),
        GoRoute(
          path: 'maintenance/new',
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('Nuova manutenzione — Fase 4')),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (_, _) => const Scaffold(
        body: Center(child: Text('Impostazioni — Fase 5')),
      ),
    ),
  ],
);
