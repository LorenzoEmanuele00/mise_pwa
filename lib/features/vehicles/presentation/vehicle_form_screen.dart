import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/gm_widgets.dart';
import '../data/vehicle_providers.dart';
import '../domain/vehicle.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final String? vehicleId;
  const VehicleFormScreen({super.key, this.vehicleId});

  bool get isEdit => vehicleId != null;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedTypeId;
  bool _loading = false;
  bool _initialized = false;
  String? _initError; // M2: set se il caricamento del veicolo fallisce in initState

  @override
  void initState() {
    super.initState();
    // M2: init asincrono in initState — stesso pattern dei form Settings (Round 1).
    // _initFromVehicle chiama setState; farlo qui (in un microtask post-frame) è corretto.
    if (widget.isEdit) {
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final vehicle =
              await ref.read(vehicleProvider(widget.vehicleId!).future);
          if (!mounted) return;
          _initFromVehicle(vehicle);
        } catch (e) {
          if (!mounted) return;
          setState(() => _initError = 'Errore caricamento: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initFromVehicle(Vehicle v) {
    if (_initialized) return;
    _initialized = true;
    _aliasCtrl.text = v.alias ?? '';
    _plateCtrl.text = v.plate;
    _yearCtrl.text = v.year?.toString() ?? '';
    _notesCtrl.text = v.notes ?? '';
    setState(() => _selectedTypeId = v.typeId);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final input = CreateVehicleInput(
      plate: _plateCtrl.text,
      alias: _aliasCtrl.text.trim().isEmpty ? null : _aliasCtrl.text.trim(),
      typeId: _selectedTypeId,
      year: _yearCtrl.text.trim().isEmpty ? null : int.tryParse(_yearCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      final notifier = ref.read(vehiclesProvider.notifier);
      if (widget.isEdit) {
        await notifier.save(widget.vehicleId!, input);
        ref.invalidate(vehicleProvider(widget.vehicleId!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mezzo aggiornato')),
          );
          context.pop();
        }
      } else {
        final newId = await notifier.create(input);
        if (mounted) context.pushReplacement('/vehicles/$newId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.badFg,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(vehicleTypesProvider);

    // M2: init delegato a initState — in build si controlla solo lo stato
    // (_initialized / _initError) senza chiamare setState direttamente.
    if (widget.isEdit) {
      if (_initError != null) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              GmTopBar(
                title: 'Modifica mezzo',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/'),
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
                          _initError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                              color: AppColors.text2),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/'),
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
      }
      if (!_initialized) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              GmTopBar(
                title: 'Modifica mezzo',
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
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GmTopBar(
            title: widget.isEdit ? 'Modifica mezzo' : 'Nuovo mezzo',
            onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
          ),
          Expanded(
            child: typesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(
                  child: Text('Errore caricamento tipi: $e',
                      style:
                          GoogleFonts.ibmPlexSans(color: AppColors.text2))),
              data: (types) => _buildForm(types),
            ),
          ),
          // Footer fisso con CTA
          GmFooterBar(
            child: GmPrimaryButton(
              label: widget.isEdit ? 'Salva modifiche' : 'Aggiungi mezzo',
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
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
          // Nome / alias
          GmField(
            label: 'Nome / identificativo',
            child: TextFormField(
              controller: _aliasCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'es. Ambulanza Alfa-3',
                hintStyle:
                    GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text3),
              ),
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 18),

          // Tipo veicolo
          GmField(
            label: 'Tipo veicolo',
            required: true,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedTypeId,
              hint: Text('Seleziona tipo',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 15, color: AppColors.text3)),
              style:
                  GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              items: types
                  .map((t) => DropdownMenuItem(value: t.id, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedTypeId = v),
              validator: (v) =>
                  v == null ? 'Seleziona un tipo di veicolo' : null,
            ),
          ),
          const SizedBox(height: 18),

          // Targa + Anno
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: GmField(
                  label: 'Targa',
                  required: true,
                  child: TextFormField(
                    controller: _plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                      TextInputFormatter.withFunction((old, nv) =>
                          nv.copyWith(text: nv.text.toUpperCase())),
                    ],
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 15,
                      color: AppColors.text,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'AA 000 BB',
                      hintStyle: GoogleFonts.ibmPlexMono(
                          fontSize: 15, color: AppColors.text3),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Targa obbligatoria'
                        : null,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: GmField(
                  label: 'Anno',
                  child: TextFormField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: '2025',
                      hintStyle: GoogleFonts.ibmPlexMono(
                          fontSize: 15, color: AppColors.text3),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final y = int.tryParse(v);
                        if (y == null || y < 1900 || y > 2100) {
                          return 'Anno non valido';
                        }
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Note
          GmField(
            label: 'Note generali',
            child: TextFormField(
              controller: _notesCtrl,
              maxLines: 4,
              style:
                  GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Annotazioni, allestimenti speciali…',
                hintStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 15, color: AppColors.text3),
                alignLabelWithHint: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

