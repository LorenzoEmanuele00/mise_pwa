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
import '../domain/maintenance_field.dart';
import '../domain/maintenance_record.dart';

const _kOther = 'Altro…';

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
  // ── Fixed core fields ────────────────────────────────────────
  DateTime _date = DateTime.now();
  final _kmCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── Dynamic field state (keyed by field_key) ─────────────────
  /// Dropdown selection (may be _kOther).
  final Map<String, String?> _selected = {};
  /// Text controller for dropdown "Altro…" entries and text/number fields.
  final Map<String, TextEditingController> _ctrls = {};
  /// Expiry date for fields with tracksExpiry = true (null = not set).
  final Map<String, DateTime?> _expiry = {};

  bool _loading = false;
  bool _initialized = false;
  String? _initError; // M2: set se il caricamento fallisce in initState

  @override
  void initState() {
    super.initState();
    // M2: init asincrono in initState — stesso pattern dei form Settings (Round 1).
    // _maybeInit chiama setState; farlo qui (in un microtask post-frame) è corretto.
    if (widget.isEdit) {
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final vehicle =
              await ref.read(vehicleProvider(widget.vehicleId).future);
          final allFields =
              await ref.read(maintenanceFieldsProvider.future);
          final record =
              await ref.read(maintenanceRecordProvider(widget.recordId!).future);
          if (!mounted) return;
          _maybeInit(record, fieldsForType(allFields, vehicle.typeId));
        } catch (e) {
          if (!mounted) return;
          setState(() => _initError = 'Errore caricamento: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Lazy controller access ────────────────────────────────────
  TextEditingController _ctrl(String key) =>
      _ctrls.putIfAbsent(key, () => TextEditingController());

  // ── Initialization from existing record ───────────────────────
  void _maybeInit(MaintenanceRecord r, List<MaintenanceField> fields) {
    if (_initialized) return;
    _initialized = true;
    _date = r.date;
    _kmCtrl.text = r.km?.toString() ?? '';
    _notesCtrl.text = r.notes ?? '';
    for (final f in fields) {
      if (f.tracksExpiry && f.options.isEmpty) {
        // Pure date field: only restore expiry date, no dropdown to init
      } else {
        final stored = r.value(f.fieldKey);
        if (f.fieldType == MaintenanceFieldType.dropdown) {
          _initDropdown(f.fieldKey, stored, f.options);
        } else {
          _ctrl(f.fieldKey).text = stored ?? '';
        }
      }
      if (f.tracksExpiry) {
        _expiry[f.fieldKey] = r.expiry(f.fieldKey);
      }
    }
    setState(() {});
  }

  void _initDropdown(String key, String? stored, List<String> opts) {
    if (stored == null || stored.isEmpty) {
      _selected[key] = null;
    } else if (opts.contains(stored)) {
      _selected[key] = stored;
    } else {
      // Stored value is a custom "Altro…" text
      _selected[key] = _kOther;
      _ctrl(key).text = stored;
    }
  }

  // ── Effective value helpers ───────────────────────────────────
  String? _effectiveDropdown(String key) {
    final sel = _selected[key];
    if (sel == null) return null;
    if (sel == _kOther) {
      final t = _ctrl(key).text.trim();
      return t.isEmpty ? null : t;
    }
    return sel;
  }

  // ── Build input from current form state ───────────────────────
  static String _fmtIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  CreateMaintenanceInput _buildInput(List<MaintenanceField> fields) {
    final cf = <String, dynamic>{};
    for (final f in fields) {
      if (f.tracksExpiry && f.options.isEmpty) {
        // Pure date field: only write the expiry date, no dropdown value
        final exp = _expiry[f.fieldKey];
        if (exp != null) cf[MaintenanceRecord.expiryKey(f.fieldKey)] = _fmtIso(exp);
      } else {
        String? value;
        if (f.fieldType == MaintenanceFieldType.dropdown) {
          value = _effectiveDropdown(f.fieldKey);
        } else {
          final t = _ctrl(f.fieldKey).text.trim();
          value = t.isEmpty ? null : t;
        }
        if (value != null) cf[f.fieldKey] = value;
        if (f.tracksExpiry) {
          final exp = _expiry[f.fieldKey];
          if (exp != null) cf[MaintenanceRecord.expiryKey(f.fieldKey)] = _fmtIso(exp);
        }
      }
    }
    return CreateMaintenanceInput(
      vehicleId: widget.vehicleId,
      date: _date,
      km: _kmCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_kmCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      customFields: cf,
    );
  }

  // ── Actions ───────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _loading = true);

    final allFields = ref.read(maintenanceFieldsProvider).value ?? [];
    final vehicle = ref.read(vehicleProvider(widget.vehicleId)).value;
    final fields = fieldsForType(allFields, vehicle?.typeId);

    // M1: blocca il salvataggio se "Altro…" è selezionato ma lasciato vuoto;
    // senza questo controllo il valore viene scartato silenziosamente.
    for (final f in fields) {
      if (f.fieldType == MaintenanceFieldType.dropdown &&
          _selected[f.fieldKey] == _kOther &&
          _ctrl(f.fieldKey).text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Specifica il valore per «${f.label}»'),
            backgroundColor: AppColors.badFg,
          ));
          setState(() => _loading = false);
        }
        return;
      }
    }

    final input = _buildInput(fields);
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
          content: Text(
              widget.isEdit ? 'Scheda aggiornata' : 'Scheda salvata'),
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
            'Eliminare questa scheda di manutenzione? '
            'L\'operazione non è reversibile.'),
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

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(vehicleProvider(widget.vehicleId));
    final fieldsAsync = ref.watch(maintenanceFieldsProvider);

    // Wait for vehicle and field definitions
    if (vehicleAsync.isLoading || fieldsAsync.isLoading) {
      return _buildLoadingScaffold();
    }
    if (vehicleAsync.hasError || fieldsAsync.hasError) {
      return _buildErrorScaffold(
          (vehicleAsync.error ?? fieldsAsync.error).toString());
    }

    final vehicle = vehicleAsync.value!;
    final allFields = fieldsAsync.value!;
    final fields = fieldsForType(allFields, vehicle.typeId);

    // M2: init delegato a initState — in build si controlla solo lo stato
    // (_initialized / _initError) senza chiamare setState direttamente.
    if (widget.isEdit) {
      if (_initError != null) return _buildErrorScaffold(_initError!);
      if (!_initialized) return _buildLoadingScaffold();
      // Continua a osservare il record per invalidazioni esterne (es. eliminazione
      // concorrente da un'altra tab), ma non richiama _maybeInit (guard _initialized).
      ref.watch(maintenanceRecordProvider(widget.recordId!));
    }

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
          Expanded(child: _buildForm(vehicle, fields)),
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

  Widget _buildLoadingScaffold() => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(
              title: widget.isEdit
                  ? 'Modifica manutenzione'
                  : 'Nuova manutenzione',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
            const Expanded(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            ),
          ],
        ),
      );

  Widget _buildErrorScaffold(String error) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(
              title: 'Errore',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
            Expanded(
              child: Center(
                child: Text('Impossibile caricare i dati: $error',
                    style: GoogleFonts.ibmPlexSans(color: AppColors.text2)),
              ),
            ),
          ],
        ),
      );

  // ── Form body ─────────────────────────────────────────────────
  Widget _buildForm(Vehicle vehicle, List<MaintenanceField> fields) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _VehicleContextBanner(vehicle: vehicle),
        const SizedBox(height: 22),

        // Date (fixed core field)
        GmField(
          label: 'Data',
          required: true,
          child: _DateField(
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
        ),
        const SizedBox(height: 18),

        // Km (fixed core field)
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

        // Dynamic fields (from maintenance_fields table)
        if (fields.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionDivider(label: 'Stato componenti'),
          const SizedBox(height: 18),
          ..._buildDynamicFields(fields),
        ],

        const SizedBox(height: 24),

        // Notes (fixed core field)
        GmField(
          label: 'Note',
          child: TextFormField(
            controller: _notesCtrl,
            maxLines: 4,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 15, color: AppColors.text),
            decoration: InputDecoration(
              hintText:
                  'Annotazioni, ricambi utilizzati, raccomandazioni…',
              hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 15, color: AppColors.text3),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),

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

  List<Widget> _buildDynamicFields(List<MaintenanceField> fields) {
    final widgets = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 18));
      final f = fields[i];

      if (f.tracksExpiry && f.options.isEmpty) {
        // Pure date field: single date picker, status computed from date
        widgets.add(GmField(
          label: f.label,
          child: _ExpiryDateField(
            value: _expiry[f.fieldKey],
            onChanged: (d) => setState(() => _expiry[f.fieldKey] = d),
          ),
        ));
      } else {
        // Normal dropdown / text / number field
        widgets.add(GmField(
          label: f.label,
          child: switch (f.fieldType) {
            MaintenanceFieldType.dropdown =>
              _buildDropdown(f.fieldKey, f.options),
            MaintenanceFieldType.number =>
              _buildTextField(f.fieldKey, isNumber: true),
            MaintenanceFieldType.text => _buildTextField(f.fieldKey),
          },
        ));
        if (f.tracksExpiry) {
          widgets.add(const SizedBox(height: 10));
          widgets.add(GmField(
            label: 'Da effettuare entro',
            child: _ExpiryDateField(
              value: _expiry[f.fieldKey],
              onChanged: (d) => setState(() => _expiry[f.fieldKey] = d),
            ),
          ));
        }
      }
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
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          hint: Text('—',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 15, color: AppColors.text3)),
          style: GoogleFonts.ibmPlexSans(
              fontSize: 15, color: AppColors.text),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          onChanged: (v) => setState(() => _selected[key] = v),
        ),
        if (_selected[key] == _kOther) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _ctrl(key),
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

  Widget _buildTextField(String key, {bool isNumber = false}) {
    return TextFormField(
      controller: _ctrl(key),
      keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: isNumber
          ? GoogleFonts.ibmPlexMono(fontSize: 15, color: AppColors.text)
          : GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text),
      decoration: InputDecoration(
        hintText: isNumber ? '0' : '—',
        hintStyle: GoogleFonts.ibmPlexSans(
            fontSize: 15, color: AppColors.text3),
      ),
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

// ── Nullable expiry date picker ───────────────────────────────
class _ExpiryDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _ExpiryDateField({required this.value, required this.onChanged});

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
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
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
            Icon(
              Icons.event_outlined,
              size: 16,
              color: value != null ? AppColors.accent : AppColors.text3,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : '—',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 15,
                  color: value != null ? AppColors.text : AppColors.text3,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.text3),
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
