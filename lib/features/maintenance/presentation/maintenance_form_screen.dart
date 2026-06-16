import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../features/vehicles/data/vehicle_providers.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/gm_widgets.dart';
import '../data/maintenance_providers.dart';
import '../domain/maintenance_record.dart';

// ── Field config ──────────────────────────────────────────────
class _FC {
  final String key;
  final String label;
  final List<String> opts;
  const _FC(this.key, this.label, this.opts);
}

const _kOther = 'Altro…';

const _fieldConfigs = <_FC>[
  _FC('tagliando', 'Tagliando', ['Effettuato', 'Da fare', 'Non applicabile']),
  _FC('revisione', 'Revisione',
      ['Effettuata', 'In scadenza', 'Scaduta', 'Non applicabile']),
  _FC('luci', 'Luci', ['OK', 'Da verificare', 'Sostituire']),
  _FC('lampeggianti', 'Lampeggianti',
      ['OK', 'Da verificare', 'Sostituire', 'Non applicabile']),
  _FC('sirene', 'Sirene',
      ['OK', 'Da verificare', 'Sostituire', 'Non applicabile']),
  _FC('spazzole', 'Spazzole', ['OK', 'Da sostituire']),
  _FC('distribuzione', 'Distribuzione',
      ['OK', 'In scadenza', 'Da sostituire', 'Non applicabile']),
  _FC('inverter', 'Inverter',
      ['OK', 'Da verificare', 'Guasto', 'Non applicabile']),
  _FC('batteria_servizi', 'Batteria servizi',
      ['OK', 'Carica bassa', 'Da sostituire', 'Non applicabile']),
  _FC('ruote', 'Ruote', ['OK', 'Usura normale', 'Da cambiare']),
  _FC('assicurazione', 'Assicurazione',
      ['In regola', 'In scadenza (30 gg)', 'Scaduta']),
];

// ── Screen ────────────────────────────────────────────────────
class MaintenanceFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? recordId;

  const MaintenanceFormScreen({
    super.key,
    required this.vehicleId,
    this.recordId,
  });

  bool get isEdit => recordId != null;

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState
    extends ConsumerState<MaintenanceFormScreen> {
  DateTime _date = DateTime.now();
  final _kmCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Dropdown selections (key → chosen option, possibly _kOther)
  final Map<String, String?> _selected = {};
  // Custom text controllers for "Altro…" entries
  final Map<String, TextEditingController> _customCtrls = {};

  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    for (final f in _fieldConfigs) {
      _customCtrls[f.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _customCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromRecord(MaintenanceRecord r) {
    if (_initialized) return;
    _initialized = true;
    _date = r.date;
    _kmCtrl.text = r.km?.toString() ?? '';
    _notesCtrl.text = r.notes ?? '';
    for (final f in _fieldConfigs) {
      _initDropdown(f.key, _recordValue(r, f.key), f.opts);
    }
    setState(() {});
  }

  // Extract a field value from the record by snake_case key
  String? _recordValue(MaintenanceRecord r, String key) => switch (key) {
        'tagliando' => r.tagliando,
        'revisione' => r.revisione,
        'luci' => r.luci,
        'lampeggianti' => r.lampeggianti,
        'sirene' => r.sirene,
        'spazzole' => r.spazzole,
        'distribuzione' => r.distribuzione,
        'inverter' => r.inverter,
        'batteria_servizi' => r.batteriaServizi,
        'ruote' => r.ruote,
        'assicurazione' => r.assicurazione,
        _ => null,
      };

  void _initDropdown(String key, String? stored, List<String> opts) {
    if (stored == null || stored.isEmpty) {
      _selected[key] = null;
    } else if (opts.contains(stored)) {
      _selected[key] = stored;
    } else {
      _selected[key] = _kOther;
      _customCtrls[key]!.text = stored;
    }
  }

  String? _effectiveValue(String key) {
    final sel = _selected[key];
    if (sel == null) return null;
    if (sel == _kOther) {
      final t = _customCtrls[key]!.text.trim();
      return t.isEmpty ? null : t;
    }
    return sel;
  }

  CreateMaintenanceInput _buildInput() => CreateMaintenanceInput(
        vehicleId: widget.vehicleId,
        date: _date,
        km: _kmCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_kmCtrl.text.trim()),
        tagliando: _effectiveValue('tagliando'),
        revisione: _effectiveValue('revisione'),
        luci: _effectiveValue('luci'),
        lampeggianti: _effectiveValue('lampeggianti'),
        sirene: _effectiveValue('sirene'),
        spazzole: _effectiveValue('spazzole'),
        distribuzione: _effectiveValue('distribuzione'),
        inverter: _effectiveValue('inverter'),
        batteriaServizi: _effectiveValue('batteria_servizi'),
        ruote: _effectiveValue('ruote'),
        assicurazione: _effectiveValue('assicurazione'),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

  Future<void> _submit() async {
    setState(() => _loading = true);
    final input = _buildInput();
    final repo = ref.read(maintenanceRepositoryProvider);

    try {
      if (widget.isEdit) {
        await repo.updateRecord(widget.recordId!, input);
        ref.invalidate(maintenanceRecordProvider(widget.recordId!));
      } else {
        await repo.createRecord(input);
      }
      ref.invalidate(maintenanceRecordsProvider(widget.vehicleId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isEdit
              ? 'Scheda aggiornata'
              : 'Scheda di manutenzione salvata'),
        ));
        if (context.canPop()) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.badFg,
        ));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina scheda'),
        content: const Text(
            'Eliminare questa scheda di manutenzione? L\'operazione non è reversibile.'),
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
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .deleteRecord(widget.recordId!);
      ref.invalidate(maintenanceRecordsProvider(widget.vehicleId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scheda eliminata')));
        if (context.canPop()) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.badFg,
        ));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize form state from existing record (edit mode)
    if (widget.isEdit) {
      ref
          .watch(maintenanceRecordProvider(widget.recordId!))
          .whenData(_initFromRecord);
    }

    final vehicleAsync = ref.watch(vehicleProvider(widget.vehicleId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GmTopBar(
            title: widget.isEdit
                ? 'Modifica manutenzione'
                : 'Nuova manutenzione',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/vehicles/${widget.vehicleId}');
              }
            },
          ),
          Expanded(
            child: vehicleAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(
                  child: Text('Errore: $e',
                      style:
                          GoogleFonts.ibmPlexSans(color: AppColors.text2))),
              data: (vehicle) {
                if (widget.isEdit && !_initialized) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent));
                }
                return _buildForm(vehicle);
              },
            ),
          ),
          GmFooterBar(
            child: GmPrimaryButton(
              label: 'Salva',
              icon: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 20),
              loading: _loading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(Vehicle vehicle) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // Vehicle context banner
        _VehicleContextBanner(vehicle: vehicle),
        const SizedBox(height: 22),

        // Date
        GmField(
          label: 'Data',
          required: true,
          child: _DateField(
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
        ),
        const SizedBox(height: 18),

        // Km
        GmField(
          label: 'Chilometraggio',
          child: TextFormField(
            controller: _kmCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.ibmPlexMono(
                fontSize: 15, color: AppColors.text),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.ibmPlexMono(
                  fontSize: 15, color: AppColors.text3),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Section divider
        const _SectionDivider(label: 'Stato componenti'),
        const SizedBox(height: 18),

        // All 11 dropdown fields
        ..._buildDropdownFields(),

        const SizedBox(height: 24),

        // Notes
        GmField(
          label: 'Note',
          child: TextFormField(
            controller: _notesCtrl,
            maxLines: 4,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 15, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Annotazioni, ricambi utilizzati, raccomandazioni…',
              hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 15, color: AppColors.text3),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),

        // Delete button (edit only)
        if (widget.isEdit) ...[
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.badFg,
                textStyle: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Elimina scheda'),
              onPressed: _confirmDelete,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildDropdownFields() {
    final widgets = <Widget>[];
    for (var i = 0; i < _fieldConfigs.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 18));
      final fc = _fieldConfigs[i];
      widgets.add(GmField(
        label: fc.label,
        child: _buildDropdown(fc.key, fc.opts),
      ));
    }
    return widgets;
  }

  Widget _buildDropdown(String key, List<String> opts) {
    final allOpts = [...opts, _kOther];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selected[key],
          items: allOpts
              .map((o) =>
                  DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          hint: Text(
            '—',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 15, color: AppColors.text3),
          ),
          style: GoogleFonts.ibmPlexSans(
              fontSize: 15, color: AppColors.text),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          onChanged: (v) => setState(() => _selected[key] = v),
        ),
        if (_selected[key] == _kOther) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customCtrls[key],
            style: GoogleFonts.ibmPlexSans(
                fontSize: 15, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Specifica…',
              hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 15, color: AppColors.text3),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Vehicle context banner ────────────────────────────────────
class _VehicleContextBanner extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleContextBanner({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GmTypeTile(vehicleType: vehicle.vehicleType, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  vehicle.plate,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date picker field ─────────────────────────────────────────
class _DateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.value, required this.onChanged});

  static String _fmt(DateTime d) {
    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          locale: const Locale('it'),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.text3),
            const SizedBox(width: 10),
            Text(
              _fmt(value),
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 15, color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section divider with label ────────────────────────────────
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.hair)),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.ibmPlexSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.text3,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.hair)),
      ],
    );
  }
}
