import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/maintenance/presentation/maintenance_form_screen.dart';
import '../features/settings/presentation/maintenance_field_form_screen.dart';
import '../features/settings/presentation/maintenance_fields_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/vehicle_type_form_screen.dart';
import '../features/settings/presentation/vehicle_types_screen.dart';
import '../features/vehicles/presentation/vehicle_list_screen.dart';
import '../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../features/vehicles/presentation/vehicle_form_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const vehicleNew = '/vehicles/new';
  static const vehicleDetail = '/vehicles/:id';
  static const vehicleEdit = '/vehicles/:id/edit';
  static const maintenanceNew = '/vehicles/:id/maintenance/new';
  static const maintenanceEdit = '/vehicles/:id/maintenance/:rid';
  static const settings = '/settings';
  static const settingsFields = '/settings/fields';
  static const settingsFieldNew = '/settings/fields/new';
  static const settingsTypes = '/settings/types';
  static const settingsTypeNew = '/settings/types/new';
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
        // NOTE: maintenance/new MUST come before maintenance/:rid
        GoRoute(
          path: 'maintenance/new',
          builder: (_, state) => MaintenanceFormScreen(
            vehicleId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'maintenance/:rid',
          builder: (_, state) => MaintenanceFormScreen(
            vehicleId: state.pathParameters['id']!,
            recordId: state.pathParameters['rid']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (_, _) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'fields',
          builder: (_, _) => const MaintenanceFieldsScreen(),
          routes: [
            // NOTE: 'new' MUST come before ':fid' to avoid 'new' being
            // parsed as a field id.
            GoRoute(
              path: 'new',
              builder: (_, _) => const MaintenanceFieldFormScreen(),
            ),
            GoRoute(
              path: ':fid',
              builder: (_, state) => MaintenanceFieldFormScreen(
                fieldId: state.pathParameters['fid']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'types',
          builder: (_, _) => const VehicleTypesScreen(),
          routes: [
            // NOTE: 'new' MUST come before ':tid'.
            GoRoute(
              path: 'new',
              builder: (_, _) => const VehicleTypeFormScreen(),
            ),
            GoRoute(
              path: ':tid',
              builder: (_, state) => VehicleTypeFormScreen(
                typeId: state.pathParameters['tid']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
