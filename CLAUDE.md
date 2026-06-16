# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

**Gestione Mezzi** — a Flutter PWA for a volunteer association to track their vehicle fleet (ambulances, wheelchair-transport vans, cars) and maintenance records. It is deployed to **Firebase Hosting** (static files) with **Supabase** as the backend (Postgres + Auth). The app URL is the app itself — no separate landing page.

Authentication uses a **single shared account** for the entire association; no user management. Security relies on RLS + mandatory login + disabled public sign-up (not on hiding the anon key, which is intentionally public).

## Commands

```bash
# Run on Chrome (required for web development)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://hvvfzvitygxyveiosumk.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_SutfYdlbIjrUi328lqcz0Q_98l0uJrg

# Build for production (web only)
flutter build web --release \
  --dart-define=SUPABASE_URL=https://hvvfzvitygxyveiosumk.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_SutfYdlbIjrUi328lqcz0Q_98l0uJrg

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Dependency install
flutter pub get

# Code generation (freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs
# Watch mode during development:
dart run build_runner watch --delete-conflicting-outputs

# Analyze code
flutter analyze
```

## Architecture

### Feature-first folder structure

```
lib/
├── main.dart                    # Supabase init (--dart-define), usePathUrlStrategy, ProviderScope
├── app/
│   ├── app.dart                 # MaterialApp.router, AppTheme
│   ├── router.dart              # GoRouter + auth redirect guard
│   └── theme/
│       └── app_theme.dart       # AppColors tokens + AppTheme.light()/dark()
├── features/
│   ├── auth/
│   │   ├── data/auth_providers.dart
│   │   ├── domain/auth_repository.dart
│   │   └── presentation/login_screen.dart
│   ├── vehicles/                # Phase 3 — fully implemented
│   │   ├── data/                # VehicleRepository + Riverpod providers
│   │   ├── domain/vehicle.dart  # Vehicle, VehicleType, CreateVehicleInput (hand-written, no freezed)
│   │   └── presentation/        # VehicleListScreen, VehicleDetailScreen, VehicleFormScreen
│   ├── maintenance/             # Phase 4 — implemented (data-driven fields)
│   │   ├── data/                # MaintenanceRepository, MaintenanceFieldRepository, providers
│   │   ├── domain/              # MaintenanceRecord, MaintenanceField, CreateMaintenanceInput
│   │   └── presentation/        # MaintenanceFormScreen (new + edit)
│   └── settings/                # Phase 5 — stub only
├── shared/
│   └── widgets/gm_widgets.dart  # Design-system widgets (GmTopBar, GmCard, GmChip, GmField, etc.)
└── services/
    └── supabase_service.dart    # `supabase` getter — use this everywhere instead of Supabase.instance.client
```

### State management pattern

Riverpod is used throughout. The pattern is:
- `Provider<XRepository>` → repository singleton
- `FutureProvider` / `FutureProvider.family` → read-only async data
- `AsyncNotifier` + `AsyncNotifierProvider` → mutable lists with CRUD (e.g. `VehiclesNotifier`)

After any mutation, call `ref.invalidateSelf()` to trigger a refetch. Also invalidate related family providers (e.g. `ref.invalidate(vehicleProvider(id))`).

### Routing

`go_router` with `usePathUrlStrategy()` for clean URLs (no `#`). The Firebase Hosting rewrite (`**` → `/index.html`) is required for deep-link reloads to work.

`AppRoutes` constants are defined in `router.dart`. Route `/vehicles/new` **must** appear before `/vehicles/:id` in the route list to avoid `id='new'` collisions.

### Supabase queries

Always use the `supabase` getter from `lib/services/supabase_service.dart`.

Fetch vehicles with joined type: `.select('*, vehicle_types(*)')` — the JSON key for the join is `vehicle_types` (snake_case table name).

### Design system

- **`docs/demo/`** is the **authoritative UI reference** (mockups). When there is a conflict between this document and `docs/demo/`, `docs/demo/` wins for visual aspects.
- Design tokens live in `lib/app/theme/app_theme.dart` as `AppColors` constants. Never hard-code colors or spacing in widgets.
- Font: **IBM Plex Sans** for all text, **IBM Plex Mono** for monospaced values (plates, abbreviations).
- Shared UI primitives are in `lib/shared/widgets/gm_widgets.dart`: `GmTopBar`, `GmCard`, `GmChip`, `GmTypeTile`, `GmDataRow`, `GmSearchInput`, `GmCircleButton`, `GmFooterBar`, `GmPrimaryButton`.

### Database schema (Supabase / PostgreSQL)

Four tables: `vehicle_types`, `vehicles`, `maintenance_records`, `maintenance_fields`. All have RLS enabled with a single `authenticated_all` policy (`TO authenticated USING (true) WITH CHECK (true)`). `vehicles` cascades deletes to `maintenance_records`; `vehicle_types` uses `ON DELETE RESTRICT`.

**Maintenance fields are data-driven**: `maintenance_fields` defines all status fields (field_key, label, field_type, options JSONB, type_id FK to vehicle_types — NULL = global, sort_order, active, **tracks_expiry**). Field values are stored in `maintenance_records.custom_fields` (JSONB). To hide a field: set `active=false`. To scope a field to a vehicle type: set `type_id`. Manage via the Supabase dashboard (UI in-app in Phase 5).

**Expiry dates** (`tracks_expiry = true`): when a field has this flag, the form shows an optional date-picker "Da effettuare entro". The date is stored in `custom_fields` under key `{field_key}_scadenza` (ISO `YYYY-MM-DD`). Enabled by default for `revisione`, `assicurazione`, `distribuzione`. Use `MaintenanceRecord.expiryKey(fieldKey)` and `record.expiry(fieldKey)` to access expiry dates in code.

`vehicle_types.abbreviation` can be set in the DB to override the default abbreviation badge (e.g. AMB, ATT).

**Date picker**: do NOT pass `locale:` to `showDatePicker` — `flutter_localizations` is not configured and it would crash. The picker inherits the browser locale automatically.

### Responsive layout targets (Phase 6)

| Breakpoint | Layout |
|---|---|
| < 600px | Bottom Navigation Bar, full-screen forms |
| 600–1200px | NavigationRail, list/detail split |
| > 1200px | Fixed sidebar, three zones |

### Development phases

- **Phases 1–3** (setup, auth, vehicles): implemented.
- **Phase 4** (maintenance records): implemented with data-driven fields from `maintenance_fields` table.
- **Phase 5** (settings UI — CRUD for maintenance_fields in-app): stub only. Fields managed via Supabase dashboard in the meantime.
- **Phase 6** (responsive layout + PWA polish): pending.
- **Phase 7** (Firebase CI/CD): pending.
- **Photos** (`vehicles.photo_url`): column exists in schema, upload deferred post-MVP.
