import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../features/maintenance/data/maintenance_providers.dart';
import '../../../features/maintenance/domain/maintenance_field.dart';
import '../../../features/vehicles/data/vehicle_providers.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/gm_widgets.dart';

class MaintenanceFieldsScreen extends ConsumerWidget {
  const MaintenanceFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(allMaintenanceFieldsProvider);
    final typesAsync = ref.watch(vehicleTypesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GmTopBar(
            title: 'Campi manutenzione',
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settings),
            trailing: GmCircleButton(
              icon: const Icon(Icons.add, size: 22, color: Colors.white),
              onTap: () => context.go(AppRoutes.settingsFieldNew),
              background: AppColors.accent,
              border: AppColors.accent,
            ),
          ),
          Expanded(
            child: fieldsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(
                child: Text('Errore caricamento: $e',
                    style: GoogleFonts.ibmPlexSans(color: AppColors.badFg)),
              ),
              data: (fields) => typesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent)),
                error: (e, _) => Center(child: Text('Errore: $e')),
                data: (types) => _buildList(context, fields, types),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<MaintenanceField> fields,
    List<VehicleType> types,
  ) {
    // Separa globali (typeId null) dai campo per tipo
    final global = fields.where((f) => f.typeId == null).toList();
    final Map<String, List<MaintenanceField>> byType = {};
    for (final f in fields.where((f) => f.typeId != null)) {
      byType.putIfAbsent(f.typeId!, () => []).add(f);
    }

    if (fields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune_rounded, size: 48, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(
              'Nessun campo configurato',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 16, color: AppColors.text3),
            ),
            const SizedBox(height: 6),
            Text(
              'Usa il pulsante + per aggiungerne uno',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 14, color: AppColors.text3),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Campi globali ───────────────────────────────────────
        GmSectionLabel(
            'Tutti i tipi${global.isNotEmpty ? " · ${global.length}" : ""}'),
        GmCard(
          padding: EdgeInsets.zero,
          child: global.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nessun campo globale.',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14, color: AppColors.text3),
                  ),
                )
              : Column(
                  children: global
                      .asMap()
                      .entries
                      .map((e) => _FieldRow(
                            field: e.value,
                            isLast: e.key == global.length - 1,
                            onTap: () => context
                                .push('/settings/fields/${e.value.id}'),
                          ))
                      .toList(),
                ),
        ),

        // ── Campi per tipo mezzo ────────────────────────────────
        for (final type in types)
          if (byType.containsKey(type.id)) ...[
            const SizedBox(height: 16),
            GmSectionLabel(
                '${type.label} · ${byType[type.id]!.length}'),
            GmCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: byType[type.id]!
                    .asMap()
                    .entries
                    .map((e) => _FieldRow(
                          field: e.value,
                          isLast: e.key == byType[type.id]!.length - 1,
                          onTap: () =>
                              context.go('/settings/fields/${e.value.id}'),
                        ))
                    .toList(),
              ),
            ),
          ],
      ],
    );
  }
}

// ── Riga singolo campo ────────────────────────────────────────
class _FieldRow extends StatelessWidget {
  final MaintenanceField field;
  final bool isLast;
  final VoidCallback onTap;

  const _FieldRow({
    required this.field,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GmTappable(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Riga label + badge stato
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              field.label,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: field.active
                                    ? AppColors.text
                                    : AppColors.text3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!field.active) ...[
                            const SizedBox(width: 8),
                            _StatusBadge(
                                label: 'disattivato',
                                fg: AppColors.badFg,
                                bg: AppColors.badBg),
                          ],
                          if (field.tracksExpiry) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.event_available_rounded,
                                size: 14, color: AppColors.text3),
                          ],
                        ],
                      ),
                      // Preview opzioni (solo dropdown)
                      if (field.fieldType ==
                              MaintenanceFieldType.dropdown &&
                          field.options.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          field.options.join(' · '),
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5, color: AppColors.text3),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _FieldTypeBadge(field.fieldType),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.text3),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 16, color: AppColors.hair),
      ],
    );
  }
}

// ── Badge tipo campo (tendina / testo / numero) ───────────────
class _FieldTypeBadge extends StatelessWidget {
  final MaintenanceFieldType type;

  const _FieldTypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    const labels = {
      MaintenanceFieldType.dropdown: 'tendina',
      MaintenanceFieldType.text: 'testo',
      MaintenanceFieldType.number: 'numero',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        labels[type]!,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.text2,
        ),
      ),
    );
  }
}

// ── Badge stato (disattivato, ecc.) ──────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _StatusBadge(
      {required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
