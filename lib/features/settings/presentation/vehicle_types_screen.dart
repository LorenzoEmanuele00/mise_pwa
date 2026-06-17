import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../features/vehicles/data/vehicle_providers.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/gm_widgets.dart';

class VehicleTypesScreen extends ConsumerWidget {
  const VehicleTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(vehicleTypesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GmTopBar(
            title: 'Tipi di mezzo',
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settings),
            trailing: GmCircleButton(
              icon: const Icon(Icons.add, size: 22, color: Colors.white),
              onTap: () => context.push(AppRoutes.settingsTypeNew),
              background: AppColors.accent,
              border: AppColors.accent,
            ),
          ),
          Expanded(
            child: typesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(
                child: Text('Errore: $e',
                    style:
                        GoogleFonts.ibmPlexSans(color: AppColors.badFg)),
              ),
              data: (types) => _buildList(context, types),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<VehicleType> types) {
    final standard = types.where((t) => !t.isCustom).toList();
    final custom = types.where((t) => t.isCustom).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Tipi predefiniti ───────────────────────────────────
        if (standard.isNotEmpty) ...[
          const GmSectionLabel('Predefiniti'),
          GmCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: standard
                  .asMap()
                  .entries
                  .map((e) => _TypeRow(
                        type: e.value,
                        isLast: e.key == standard.length - 1,
                        onTap: () =>
                            context.push('/settings/types/${e.value.id}'),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Tipi personalizzati ────────────────────────────────
        GmSectionLabel(
            'Personalizzati${custom.isNotEmpty ? " · ${custom.length}" : ""}'),
        GmCard(
          padding: EdgeInsets.zero,
          child: custom.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nessun tipo personalizzato.\nUsa il pulsante + per aggiungerne uno.',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14, color: AppColors.text3),
                  ),
                )
              : Column(
                  children: custom
                      .asMap()
                      .entries
                      .map((e) => _TypeRow(
                            type: e.value,
                            isLast: e.key == custom.length - 1,
                            onTap: () =>
                                context.push('/settings/types/${e.value.id}'),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

// ── Riga singolo tipo mezzo ───────────────────────────────────
class _TypeRow extends StatelessWidget {
  final VehicleType type;
  final bool isLast;
  final VoidCallback onTap;

  const _TypeRow({
    required this.type,
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
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GmTypeTile(vehicleType: type, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        type.isCustom ? 'Personalizzato' : 'Predefinito',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 13, color: AppColors.text3),
                      ),
                    ],
                  ),
                ),
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
