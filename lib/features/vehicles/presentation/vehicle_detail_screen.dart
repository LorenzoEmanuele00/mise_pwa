import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/gm_widgets.dart';
import '../data/vehicle_providers.dart';
import '../domain/vehicle.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleProvider(vehicleId));

    return vehicleAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(title: '', onBack: () => context.pop()),
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(title: 'Errore', onBack: () => context.pop()),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.text3),
                    const SizedBox(height: 12),
                    Text('Impossibile caricare il mezzo',
                        style: GoogleFonts.ibmPlexSans(
                            color: AppColors.text2, fontSize: 15)),
                    const SizedBox(height: 16),
                    _RetryButton(onTap: () => ref.invalidate(vehicleProvider(vehicleId))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      data: (vehicle) => _VehicleDetailView(vehicle: vehicle),
    );
  }
}

class _VehicleDetailView extends ConsumerWidget {
  final Vehicle vehicle;
  const _VehicleDetailView({required this.vehicle});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina mezzo'),
        content: Text(
          'Eliminare "${vehicle.displayName}"?\n'
          'Le schede di manutenzione associate verranno eliminate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annulla',
                style: GoogleFonts.ibmPlexSans(color: AppColors.text2)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.badFg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Elimina',
                style: GoogleFonts.ibmPlexSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(vehiclesProvider.notifier).delete(vehicle.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mezzo eliminato')),
        );
        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.badFg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Top bar con "Modifica" a destra
          GmTopBar(
            title: vehicle.displayName,
            onBack: () => context.go('/'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => context.go('/vehicles/${vehicle.id}/edit'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Modifica',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Icon(Icons.delete_outline_rounded,
                        color: AppColors.badFg, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Identity card ──────────────────────────
                  GmCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GmTypeTile(vehicleType: vehicle.vehicleType, size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.displayName,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                  height: 1.2,
                                ),
                              ),
                              if (vehicle.vehicleType != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  vehicle.vehicleType!.label,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.5,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Targa badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicle.plate,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Dati attuali ───────────────────────────
                  const GmSectionLabel('Dati attuali'),
                  GmCard(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      children: [
                        GmDataRow(
                            label: 'Tipo veicolo',
                            value: vehicle.vehicleType?.label ?? '—'),
                        GmDataRow(
                            label: 'Anno',
                            value: vehicle.year?.toString() ?? '—',
                            mono: true),
                        GmDataRow(
                            label: 'Note',
                            value: vehicle.notes?.isNotEmpty == true
                                ? vehicle.notes!
                                : '—',
                            last: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Manutenzioni ───────────────────────────
                  const GmSectionLabel('Storico interventi'),

                  GmPrimaryButton(
                    label: 'Nuova manutenzione',
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: () =>
                        context.go('/vehicles/${vehicle.id}/maintenance/new'),
                  ),

                  const SizedBox(height: 12),

                  // Placeholder Fase 4
                  GmCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(Icons.build_circle_outlined,
                              size: 40, color: AppColors.text3),
                          const SizedBox(height: 10),
                          Text(
                            'Nessun intervento registrato',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Avvia la prima manutenzione con il pulsante qui sopra.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              color: AppColors.text3,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Riprova',
            style: GoogleFonts.ibmPlexSans(
                color: AppColors.accent, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
