import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';

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

/// Adatta uno [Stream] auth come [Listenable] per [GoRouter.refreshListenable].
/// Ogni evento auth (login, logout, token refresh) fa ri-eseguire il redirect
/// della guardia, così la UI risponde alla scadenza della sessione anche senza
/// navigazione manuale.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Static name for vehicles root (to avoid ambiguity with vehicleNew)
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  // C1: aggancia il redirect allo stream auth di Supabase, così la guardia
  // viene rivalutata automaticamente a login, logout e scadenza token.
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final onLogin = state.matchedLocation == AppRoutes.login;

    if (session == null && !onLogin) return AppRoutes.login;
    if (session != null && onLogin) return AppRoutes.home;
    return null;
  },
  // M4: URL non riconosciuti (es. deep-link obsoleti) mostrano una schermata
  // di errore invece della schermata rossa di default di go_router.
  errorBuilder: (context, state) => const _NotFoundScreen(),
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

/// Schermata mostrata per URL non riconosciuti dal router.
/// Con il rewrite Firebase `** → /index.html`, qualunque path sconosciuto
/// avvia l'app e termina qui invece che nella schermata rossa di go_router.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    // Mostra il path che non è stato trovato, utile per debug
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 52, color: AppColors.text3),
                const SizedBox(height: 20),
                Text(
                  'Pagina non trovata',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  path,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 13,
                    color: AppColors.text3,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Torna alla lista mezzi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
