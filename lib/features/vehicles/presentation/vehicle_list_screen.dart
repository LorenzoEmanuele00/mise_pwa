import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/router.dart';
import '../../../shared/widgets/gm_widgets.dart';
import '../data/vehicle_providers.dart';
import '../domain/vehicle.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterTypeId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Vehicle> _filtered(List<Vehicle> all) {
    return all.where((v) {
      if (_filterTypeId != null && v.typeId != _filterTypeId) return false;
      if (_query.trim().isNotEmpty) {
        final q = _query.trim().toLowerCase();
        final hay = '${v.alias ?? ''} ${v.plate} ${v.vehicleType?.label ?? ''}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final typesAsync = ref.watch(vehicleTypesProvider);

    final totalCount = vehiclesAsync.when(data: (d) => d.length, loading: () => 0, error: (_, _) => 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Header fisso ────────────────────────────────────
          GmTopBar(
            title: 'Mezzi',
            subtitle: '$totalCount ${totalCount == 1 ? 'veicolo' : 'veicoli'} in flotta',
            large: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GmCircleButton(
                  icon: const Icon(Icons.settings_outlined,
                      size: 19, color: AppColors.text2),
                  onTap: () => context.go(AppRoutes.settings),
                ),
                const SizedBox(width: 8),
                GmCircleButton(
                  icon: const Icon(Icons.add, size: 22, color: Colors.white),
                  onTap: () => context.push(AppRoutes.vehicleNew),
                  background: AppColors.accent,
                  border: AppColors.accent,
                ),
              ],
            ),
          ),

          // ── Contenuto scrollabile ───────────────────────────
          Expanded(
            child: vehiclesAsync.when(
              loading: () => _buildScrollable(
                typesAsync: typesAsync,
                content: Column(
                  children: List.generate(4, (_) => const _SkeletonCard()),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: AppColors.text3),
                      const SizedBox(height: 12),
                      Text('Errore di rete',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      const SizedBox(height: 8),
                      Text('$e',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 13, color: AppColors.text2)),
                      const SizedBox(height: 20),
                      _GhostButton(
                        label: 'Riprova',
                        onTap: () => ref.invalidate(vehiclesProvider),
                      ),
                    ],
                  ),
                ),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return _EmptyState(onAdd: () => context.push(AppRoutes.vehicleNew));
                }
                final list = _filtered(all);
                return _buildScrollable(
                  typesAsync: typesAsync,
                  content: list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Text('Nessun mezzo trovato',
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text2)),
                              const SizedBox(height: 4),
                              Text('Prova a modificare ricerca o filtri.',
                                  style: GoogleFonts.ibmPlexSans(
                                      fontSize: 13.5, color: AppColors.text3)),
                            ],
                          ),
                        )
                      : Column(
                          children: list
                              .map((v) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _VehicleCard(
                                      vehicle: v,
                                      onTap: () => context.push('/vehicles/${v.id}'),
                                    ),
                                  ))
                              .toList(),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollable({
    required AsyncValue<List<VehicleType>> typesAsync,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: GmSearchInput(
              controller: _searchCtrl,
              hintText: 'Cerca per targa, nome, modello…',
              onChanged: (v) => setState(() => _query = v),
              hasText: _query.isNotEmpty,
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          ),

          // Filter chips
          typesAsync.whenData((types) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  GmChip(
                    label: 'Tutti',
                    selected: _filterTypeId == null,
                    onTap: () => setState(() => _filterTypeId = null),
                  ),
                  ...types.map((t) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GmChip(
                          label: t.label,
                          selected: _filterTypeId == t.id,
                          onTap: () => setState(() =>
                              _filterTypeId = _filterTypeId == t.id ? null : t.id),
                        ),
                      )),
                ],
              ),
            );
          }).when(data: (w) => w, loading: () => const SizedBox.shrink(), error: (_, _) => const SizedBox.shrink()),

          // List content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: content,
          ),
        ],
      ),
    );
  }
}

// ── Vehicle card ─────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GmTappable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GmTypeTile(vehicleType: vehicle.vehicleType),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome + targa
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.displayName,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vehicle.plate,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Tipo · Anno
                  Text(
                    [
                      if (vehicle.vehicleType != null) vehicle.vehicleType!.label,
                      if (vehicle.year != null) vehicle.year.toString(),
                    ].join(' · '),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      color: AppColors.text2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.directions_car_outlined,
                  size: 38, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'Nessun mezzo registrato',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi il primo mezzo con il pulsante + in alto a destra.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppColors.text2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GmPrimaryButton(
              label: 'Aggiungi mezzo',
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ghost text button ─────────────────────────────────────────
class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GmTappable(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

// ── Skeleton card ─────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 130, height: 15),
                const SizedBox(height: 8),
                _Shimmer(width: 90, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
