import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../features/vehicles/data/vehicle_providers.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/gm_widgets.dart';

class VehicleTypeFormScreen extends ConsumerStatefulWidget {
  final String? typeId;

  const VehicleTypeFormScreen({super.key, this.typeId});

  bool get isEdit => typeId != null;

  @override
  ConsumerState<VehicleTypeFormScreen> createState() =>
      _VehicleTypeFormScreenState();
}

class _VehicleTypeFormScreenState
    extends ConsumerState<VehicleTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _abbreviationCtrl = TextEditingController();

  bool _loading = false;
  bool _initialized = false;
  String? _initError; // C2: set se il tipo non viene trovato nel caricamento
  bool _isCustomType = true;
  String? _existingCode;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      Future.microtask(() async {
        if (!mounted) return;
        try {
          final types = await ref.read(vehicleTypesProvider.future);
          if (!mounted) return;
          // C2: firstWhere senza orElse lancia StateError su id obsoleto;
          // usiamo firstOrNull e mostriamo un errore invece di uno spinner
          // infinito ingoiato dal catch.
          final match =
              types.where((t) => t.id == widget.typeId!).firstOrNull;
          if (match == null) {
            setState(() => _initError = 'Tipo non trovato (id obsoleto?)');
            return;
          }
          _initFromType(match);
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
    _abbreviationCtrl.dispose();
    super.dispose();
  }

  void _initFromType(VehicleType t) {
    if (_initialized) return;
    _initialized = true;
    _existingCode = t.code;
    _labelCtrl.text = t.label;
    _abbreviationCtrl.text = t.abbreviationOverride ?? '';
    setState(() => _isCustomType = t.isCustom);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final label = _labelCtrl.text.trim();
    final abbreviation = _abbreviationCtrl.text.trim().isEmpty
        ? null
        : _abbreviationCtrl.text.trim().toUpperCase();

    try {
      if (widget.isEdit) {
        await ref.read(vehicleRepositoryProvider).updateVehicleType(
              widget.typeId!,
              label: label,
              abbreviation: abbreviation,
            );
        ref.invalidate(vehicleTypesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tipo aggiornato')),
          );
          context.pop();
        }
      } else {
        final code = CreateVehicleTypeInput.labelToCode(label);
        final input = CreateVehicleTypeInput(
          code: code,
          label: label,
          isCustom: true,
          abbreviation: abbreviation,
        );
        await ref.read(vehicleRepositoryProvider).createVehicleType(input);
        ref.invalidate(vehicleTypesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tipo aggiunto')),
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
        title: const Text('Elimina tipo'),
        content: Text(
          'Eliminare il tipo "${_labelCtrl.text}"?\n\n'
          'Non è possibile eliminarlo se ci sono mezzi di questo tipo.',
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
          .read(vehicleRepositoryProvider)
          .deleteVehicleType(widget.typeId!);
      ref.invalidate(vehicleTypesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo eliminato')),
        );
        context.pop();
      }
    } on PostgrestException catch (e) {
      // ON DELETE RESTRICT: foreign key violation code 23503
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == '23503'
                  ? 'Impossibile eliminare: ci sono mezzi di questo tipo'
                  : 'Errore database: ${e.message}',
            ),
            backgroundColor: AppColors.badFg,
          ),
        );
        setState(() => _loading = false);
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
      if (e.code == '23505') return 'Codice già esistente — scegli un nome diverso';
      return 'Errore database: ${e.message}';
    }
    return 'Errore: $e';
  }

  Scaffold _buildErrorScaffold(String message) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(
              title: 'Modifica tipo',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.settingsTypes),
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
                            : context.go(AppRoutes.settingsTypes),
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

  // Mostra loading finché il tipo non è inizializzato (solo in edit)
  Scaffold _buildLoadingScaffold() => Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            GmTopBar(
              title: 'Modifica tipo',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.settingsTypes),
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
    if (widget.isEdit && !_initialized) {
      // C2: mostra errore esplicito invece di spinner infinito se l'id non esiste
      if (_initError != null) return _buildErrorScaffold(_initError!);
      return _buildLoadingScaffold();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GmTopBar(
            title: widget.isEdit ? 'Modifica tipo' : 'Nuovo tipo di mezzo',
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settingsTypes),
          ),
          Expanded(child: _buildForm()),
          GmFooterBar(
            child: GmPrimaryButton(
              label: widget.isEdit ? 'Salva modifiche' : 'Aggiungi tipo',
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          // ── Code (sola lettura in modifica) ───────────────────
          if (widget.isEdit && _existingCode != null) ...[
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
                      'Codice: ${_existingCode!} · non modificabile',
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
            label: 'Nome del tipo',
            required: true,
            child: TextFormField(
              controller: _labelCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'es. Furgone',
                hintStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 15, color: AppColors.text3),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nome obbligatorio' : null,
              textInputAction: TextInputAction.next,
            ),
          ),
          const SizedBox(height: 18),

          // ── Abbreviazione ──────────────────────────────────────
          GmField(
            label: 'Abbreviazione badge (opzionale)',
            child: TextFormField(
              controller: _abbreviationCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                TextInputFormatter.withFunction((old, nv) =>
                    nv.copyWith(text: nv.text.toUpperCase())),
              ],
              style: GoogleFonts.ibmPlexMono(
                fontSize: 15,
                color: AppColors.text,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                hintText: 'es. FRG',
                hintStyle: GoogleFonts.ibmPlexMono(
                    fontSize: 15, color: AppColors.text3),
                counterText: '',
                helperText:
                    'Sovrascrive l\'abbreviazione automatica sul badge del mezzo',
                helperStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 12.5, color: AppColors.text3),
              ),
            ),
          ),

          // ── Elimina (solo custom, solo in edit) ────────────────
          if (widget.isEdit && _isCustomType) ...[
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.badFg),
                label: Text(
                  'Elimina tipo',
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
