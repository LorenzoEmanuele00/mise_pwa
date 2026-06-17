import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

import '../../../app/theme/app_theme.dart';
import '../../../features/maintenance/data/maintenance_providers.dart';
import '../../../features/maintenance/domain/maintenance_field.dart';
import '../../../features/maintenance/domain/maintenance_record.dart';
import '../../../shared/utils/csv_export.dart';
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

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final records =
          await ref.read(maintenanceRecordsProvider(vehicle.id).future);
      if (records.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Nessuna manutenzione da esportare')),
          );
        }
        return;
      }
      final allFields = await ref.read(allMaintenanceFieldsProvider.future);
      final fields = fieldsForType(allFields, vehicle.typeId);
      final csv = buildMaintenanceCsv(
        vehicle: vehicle,
        records: records,
        fields: fields,
      );
      final filename = csvFilename(vehicle);
      _triggerCsvDownload(filename, csv);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV scaricato: $filename')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore durante l'esportazione: $e"),
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
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GmTappable(
                  onTap: () => context.push('/vehicles/${vehicle.id}/edit'),
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
                GmTappable(
                  onTap: () => _exportCsv(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Icon(Icons.download_outlined,
                        color: AppColors.accent, size: 22),
                  ),
                ),
                GmTappable(
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
                        context.push('/vehicles/${vehicle.id}/maintenance/new'),
                  ),

                  const SizedBox(height: 12),

                  _MaintenanceSection(vehicle: vehicle),
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
    return GmTappable(
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

// ── Maintenance section ───────────────────────────────────────
class _MaintenanceSection extends ConsumerWidget {
  final Vehicle vehicle;
  const _MaintenanceSection({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(maintenanceRecordsProvider(vehicle.id));
    // Field definitions (best-effort: use empty list if not yet loaded)
    final allFields = ref.watch(maintenanceFieldsProvider).value ?? [];
    final fields = fieldsForType(allFields, vehicle.typeId);

    return recordsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent),
        ),
      ),
      error: (e, _) => GmCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Impossibile caricare le schede: $e',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13, color: AppColors.text3),
          ),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return GmCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Icon(Icons.build_circle_outlined,
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
                        fontSize: 13, color: AppColors.text3, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: records
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MaintenanceCard(
                      record: r,
                      fields: fields,
                      onTap: () => context.push(
                          '/vehicles/${vehicle.id}/maintenance/${r.id}'),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ── Chip urgency status ───────────────────────────────────────
enum _ChipStatus { bad, warn, neutral }

// ── Maintenance list card ─────────────────────────────────────
class _MaintenanceCard extends StatelessWidget {
  final MaintenanceRecord record;
  final List<MaintenanceField> fields;
  final VoidCallback onTap;

  const _MaintenanceCard({
    required this.record,
    required this.fields,
    required this.onTap,
  });

  static String _fmtDate(DateTime d) {
    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _fmtKm(int km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(km % 1000 == 0 ? 0 : 1)} k km';
    }
    return '$km km';
  }

  static bool _isGood(String v) {
    final l = v.toLowerCase().trim();
    return l == 'ok' ||
        l == 'in regola' ||
        l == 'effettuato' ||
        l == 'effettuata' ||
        l == 'non applicabile';
  }

  static bool _isBad(String v) {
    final l = v.toLowerCase();
    return l.contains('scadut') ||
        l.contains('guasto') ||
        l.contains('carica bassa');
  }

  static bool _isWarn(String v) {
    final l = v.toLowerCase();
    return l.contains('in scadenza') ||
        l.contains('da fare') ||
        l.contains('da sostituire') ||
        l.contains('da verificare') ||
        l.contains('da cambiare') ||
        l.contains('usura');
  }

  static String _fmtExpiryDate(DateTime d) {
    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  List<(String, String, _ChipStatus)> _notableFields() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final result = <(String, String, _ChipStatus)>[];

    for (final f in fields) {
      if (f.tracksExpiry && f.options.isEmpty) {
        // Pure date field: status computed from expiry date
        final exp = record.expiry(f.fieldKey);
        if (exp == null) continue;
        final expDate = DateTime(exp.year, exp.month, exp.day);
        final diff = expDate.difference(todayDate).inDays;
        if (diff > 30) continue; // effettuata → good, skip
        final status = diff < 0 ? _ChipStatus.bad : _ChipStatus.warn;
        final statusLabel = diff < 0 ? 'Scaduta' : 'In scadenza';
        result.add((f.label, '$statusLabel · ${_fmtExpiryDate(exp)}', status));
        continue;
      }

      // Standard dropdown/text field
      final value = record.value(f.fieldKey);
      if (value == null || value.isEmpty || _isGood(value)) continue;
      final status = _isBad(value)
          ? _ChipStatus.bad
          : (_isWarn(value) ? _ChipStatus.warn : _ChipStatus.neutral);
      String label = value;
      if (f.tracksExpiry) {
        final exp = record.expiry(f.fieldKey);
        if (exp != null) label = '$value · ${_fmtExpiryDate(exp)}';
      }
      result.add((f.label, label, status));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final notable = _notableFields();
    return GmCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppColors.text3),
              const SizedBox(width: 5),
              Text(
                _fmtDate(record.date),
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2),
              ),
              const Spacer(),
              if (record.km != null)
                Text(
                  _fmtKm(record.km!),
                  style: GoogleFonts.ibmPlexMono(
                      fontSize: 13, color: AppColors.text3),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.text3),
            ],
          ),
          if (notable.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: notable.map((f) {
                final (label, value, status) = f;
                final (fg, bg) = switch (status) {
                  _ChipStatus.bad => (AppColors.badFg, AppColors.badBg),
                  _ChipStatus.warn => (AppColors.warnFg, AppColors.warnBg),
                  _ChipStatus.neutral =>
                    (AppColors.text2, AppColors.surface2),
                };
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$label: $value',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: fg),
                  ),
                );
              }).toList(),
            ),
          ],
          if (record.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              record.notes!,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13, color: AppColors.text3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Download CSV via Web API ──────────────────────────────────
/// Avvia il download del file CSV nel browser.
void _triggerCsvDownload(String filename, String content) {
  final encoded = Uint8List.fromList(utf8.encode(content));
  final blob = web.Blob(
    <JSAny>[encoded.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
