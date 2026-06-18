import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../features/maintenance/data/maintenance_providers.dart';
import '../../../features/maintenance/domain/maintenance_field.dart';
import '../../../features/vehicles/data/vehicle_providers.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/gm_widgets.dart';

class MaintenanceFieldFormScreen extends ConsumerStatefulWidget {
  final String? fieldId;

  const MaintenanceFieldFormScreen({super.key, this.fieldId});

  bool get isEdit => fieldId != null;

  @override
  ConsumerState<MaintenanceFieldFormScreen> createState() =>
      _MaintenanceFieldFormScreenState();
}

class _MaintenanceFieldFormScreenState
    extends ConsumerState<MaintenanceFieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController();

  List<TextEditingController> _optionCtrls = [];
  MaintenanceFieldType _fieldType = MaintenanceFieldType.dropdown;
  String? _typeId; // null = tutti i tipi
  bool _tracksExpiry = false;
  bool _active = true;
  bool _loading = false;
  bool _initialized = false;
  String? _initError; // C2: set se il campo non viene trovato nel caricamento
  String? _existingFieldKey; // solo in edit mode

  @override
  void initState() {
    super.initState();
    if (!widget.isEdit) {
      _optionCtrls = [TextEditingController(), TextEditingController()];
      _sortOrderCtrl.text = '100';
    } else {
      // Carica il campo in modo asincrono, fuori dal ciclo build, così
      // setState può essere chiamato in sicurezza.
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final fields =
              await ref.read(allMaintenanceFieldsProvider.future);
          if (!mounted) return;
          // C2: firstWhere senza orElse lancia StateError su id obsoleto;
          // usiamo firstOrNull e mostriamo un errore invece di uno spinner
          // infinito ingoiato dal catch.
          final match =
              fields.where((f) => f.id == widget.fieldId!).firstOrNull;
          if (match == null) {
            setState(() => _initError = 'Campo non trovato (id obsoleto?)');
            return;
          }
          _initFromField(match);
        } catch (e) {
          if (!mounted) return;
          setState(() => _initError = 'Errore di caricamento: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _sortOrderCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromField(MaintenanceField f) {
    if (_initialized) return;
    _initialized = true;
    _existingFieldKey = f.fieldKey;
    _labelCtrl.text = f.label;
    _sortOrderCtrl.text = f.sortOrder.toString();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    _optionCtrls = f.options.isNotEmpty
        ? f.options.map((o) => TextEditingController(text: o)).toList()
        : [TextEditingController()];
    setState(() {
      _fieldType = f.fieldType;
      _typeId = f.typeId;
      _tracksExpiry = f.tracksExpiry;
      _active = f.active;
    });
  }

  List<String> get _cleanOptions => _optionCtrls
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _addOption() {
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    final c = _optionCtrls[i];
    setState(() => _optionCtrls.removeAt(i));
    c.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validazione opzioni: solo se non è un campo solo-datepicker
    if (!_tracksExpiry &&
        _fieldType == MaintenanceFieldType.dropdown &&
        _cleanOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aggiungi almeno un\'opzione valida'),
          backgroundColor: AppColors.badFg,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final label = _labelCtrl.text.trim();
    final fieldKey = widget.isEdit
        ? _existingFieldKey!
        : CreateMaintenanceFieldInput.labelToKey(label);
    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 100;

    // Se traccia scadenza → solo date-picker: il tipo e le opzioni non contano
    final input = CreateMaintenanceFieldInput(
      fieldKey: fieldKey,
      label: label,
      fieldType: _fieldType,
      options: (!_tracksExpiry && _fieldType == MaintenanceFieldType.dropdown)
          ? _cleanOptions
          : [],
      typeId: _typeId,
      sortOrder: sortOrder,
      active: _active,
      tracksExpiry: _tracksExpiry,
    );

    try {
      final notifier = ref.read(allMaintenanceFieldsProvider.notifier);
      if (widget.isEdit) {
        await notifier.save(widget.fieldId!, input);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campo aggiornato')),
          );
          context.pop();
        }
      } else {
        await notifier.create(input);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campo aggiunto')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppColors.badFg,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina campo'),
        content: Text(
          'Eliminare "${_labelCtrl.text}"?\n\n'
          'I valori già salvati nelle schede rimarranno nel database ma non '
          'saranno più visibili.\n\n'
          'In alternativa puoi disattivare il campo (toggle Attivo) '
          'per nasconderlo senza perdere i dati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Elimina',
              style: GoogleFonts.ibmPlexSans(
                  color: AppColors.badFg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(allMaintenanceFieldsProvider.notifier)
          .delete(widget.fieldId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campo eliminato')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppColors.badFg,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  // M6: usa PostgrestException tipizzata invece di string matching su e.toString()
  String _friendlyError(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') return 'Chiave già esistente — scegli un nome diverso';
      return 'Errore database: ${e.message}';
    }
    return 'Errore: $e';
  }

  Scaffold _buildErrorScaffold(String message) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(
              title: 'Modifica campo',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.settingsFields),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppColors.text3),
                      const SizedBox(height: 16),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(color: AppColors.text2),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.settingsFields),
                        child: const Text('Torna indietro'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Scaffold _buildLoadingScaffold(String title) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(
              title: title,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.settingsFields),
            ),
            const Expanded(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(vehicleTypesProvider);

    // Mostra loading finché _initFromField (lanciato da initState) non
    // ha completato e chiamato setState. Questo garantisce che i valori
    // del form siano corretti al primo render.
    if (widget.isEdit && !_initialized) {
      // C2: mostra errore esplicito invece di spinner infinito se l'id non esiste
      if (_initError != null) return _buildErrorScaffold(_initError!);
      return _buildLoadingScaffold('Modifica campo');
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GmTopBar(
            title: widget.isEdit ? 'Modifica campo' : 'Nuovo campo',
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settingsFields),
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
              data: (types) => _buildForm(types),
            ),
          ),
          GmFooterBar(
            child: GmPrimaryButton(
              label: widget.isEdit ? 'Salva modifiche' : 'Aggiungi campo',
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

  Widget _buildForm(List<VehicleType> types) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          // ── field_key (sola lettura in modifica) ───────────────
          if (widget.isEdit && _existingFieldKey != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.info_outline_rounded,
                        size: 15, color: AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chiave: ${_existingFieldKey!}\n'
                      'Non modificabile — è la chiave usata nei dati storici.',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 12, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── Nome ───────────────────────────────────────────────
          GmField(
            label: 'Nome del campo',
            required: true,
            child: TextFormField(
              controller: _labelCtrl,
              textCapitalization: TextCapitalization.sentences,
              style:
                  GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'es. Sanificazione cabina',
                hintStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 15, color: AppColors.text3),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 18),

          // ── Traccia scadenza (in alto: determina il tipo di campo) ─
          GmCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(
                'Traccia data di scadenza',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 15, color: AppColors.text),
              ),
              subtitle: Text(
                _tracksExpiry
                    ? 'Il campo mostrerà solo il selettore di data'
                    : 'Attiva per usare questo campo come date-picker',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13, color: AppColors.text3),
              ),
              value: _tracksExpiry,
              onChanged: (v) => setState(() => _tracksExpiry = v),
            ),
          ),
          const SizedBox(height: 18),

          // ── Tipo + Opzioni (nascosti se traccia scadenza attivo) ───
          if (!_tracksExpiry) ...[
            GmField(
              label: 'Tipo di campo',
              child: DropdownButtonFormField<MaintenanceFieldType>(
                initialValue: _fieldType,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 15, color: AppColors.text),
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                items: const [
                  DropdownMenuItem(
                    value: MaintenanceFieldType.dropdown,
                    child: Text('Tendina a scelta'),
                  ),
                  DropdownMenuItem(
                    value: MaintenanceFieldType.text,
                    child: Text('Testo libero'),
                  ),
                  DropdownMenuItem(
                    value: MaintenanceFieldType.number,
                    child: Text('Numero'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _fieldType = v;
                    if (v == MaintenanceFieldType.dropdown &&
                        _optionCtrls.isEmpty) {
                      _optionCtrls = [
                        TextEditingController(),
                        TextEditingController(),
                      ];
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 18),

            if (_fieldType == MaintenanceFieldType.dropdown) ...[
              GmField(
                label: 'Opzioni della tendina',
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._optionCtrls.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ctrl = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ctrl,
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 15, color: AppColors.text),
                                decoration: InputDecoration(
                                  hintText: 'Opzione ${i + 1}',
                                  hintStyle: GoogleFonts.ibmPlexSans(
                                      fontSize: 15, color: AppColors.text3),
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GmTappable(
                              onTap: _optionCtrls.length <= 1
                                  ? () {}
                                  : () => _removeOption(i),
                              child: Container(
                                width: 42,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(13),
                                  color: AppColors.surface,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: _optionCtrls.length <= 1
                                      ? AppColors.text3
                                      : AppColors.badFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Aggiungi opzione',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ],

          // ── Ambito (tutti i tipi / specifico) ──────────────────
          GmField(
            label: 'Si applica a',
            child: DropdownButtonFormField<String?>(
              initialValue: _typeId,
              style:
                  GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tutti i tipi di mezzo'),
                ),
                ...types.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.label),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _typeId = v),
            ),
          ),
          const SizedBox(height: 18),

          // ── Attivo / disattivato ───────────────────────────────
          GmCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(
                'Attivo',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 15, color: AppColors.text),
              ),
              subtitle: Text(
                'Se disattivato non compare nelle nuove schede (i dati storici restano)',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 13, color: AppColors.text3),
              ),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ),
          const SizedBox(height: 18),

          // ── Ordine ─────────────────────────────────────────────
          GmField(
            label: 'Ordine di visualizzazione',
            child: TextFormField(
              controller: _sortOrderCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                hintText: '100',
                hintStyle: GoogleFonts.ibmPlexMono(
                    fontSize: 15, color: AppColors.text3),
              ),
            ),
          ),

          // ── Elimina (solo in edit) ─────────────────────────────
          if (widget.isEdit) ...[
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.badFg),
                label: Text(
                  'Elimina campo',
                  style: GoogleFonts.ibmPlexSans(
                    color: AppColors.badFg,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.badFg),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
