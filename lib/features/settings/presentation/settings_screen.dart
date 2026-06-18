import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../features/auth/data/auth_providers.dart';
import '../../../shared/widgets/gm_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Esci dall\'app'),
        content: const Text(
          'Vuoi uscire? Dovrai reinserire le credenziali al prossimo accesso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Esci',
              style: GoogleFonts.ibmPlexSans(
                color: AppColors.badFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GmTopBar(
            title: 'Impostazioni',
            onBack: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // ── Sezione configurazione ──────────────────────
                const GmSectionLabel('Configurazione'),
                GmCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.tune_rounded,
                        label: 'Campi manutenzione',
                        subtitle: 'Aggiungi, modifica o disattiva i campi di stato',
                        onTap: () => context.go(AppRoutes.settingsFields),
                      ),
                      const Divider(
                          height: 1, indent: 60, color: AppColors.hair),
                      _SettingsRow(
                        icon: Icons.directions_car_rounded,
                        label: 'Tipi di mezzo',
                        subtitle: 'Gestisci le tipologie di veicolo',
                        isLast: true,
                        onTap: () => context.go(AppRoutes.settingsTypes),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Sezione account ─────────────────────────────
                const GmSectionLabel('Account'),
                GmCard(
                  padding: EdgeInsets.zero,
                  child: GmTappable(
                    onTap: () => _confirmLogout(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.badBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.logout_rounded,
                                size: 18, color: AppColors.badFg),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Esci dall\'app',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.badFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ── Nav row con icona colorata + chevron ──────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GmTappable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 13, color: AppColors.text3),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.text3),
          ],
        ),
      ),
    );
  }
}
