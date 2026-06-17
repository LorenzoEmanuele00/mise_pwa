/// Widget condivisi che replicano il design system di docs/demo/
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../../features/vehicles/domain/vehicle.dart';

// ── GmTappable ───────────────────────────────────────────────
/// Wrapper che aggiunge feedback di opacità (stile iOS) a qualsiasi widget.
class GmTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final HitTestBehavior behavior;

  const GmTappable({
    super.key,
    required this.child,
    required this.onTap,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<GmTappable> createState() => _GmTappableState();
}

class _GmTappableState extends State<GmTappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _down ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: widget.child,
      ),
    );
  }
}

// ── GmTopBar ──────────────────────────────────────────────────
/// TopBar in due varianti: large (lista) e small (dettaglio/form).
class GmTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool large;

  const GmTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    if (large) {
      return Container(
        color: AppColors.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPad),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [?trailing],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Small/regular variant — bordo inferiore sottile
    return Container(
      color: AppColors.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPad),
          Container(
            height: 62,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(
                bottom: BorderSide(color: AppColors.hair),
              ),
            ),
            child: Row(
              children: [
                if (onBack != null)
                  _BackButton(onTap: onBack!)
                else
                  const SizedBox(width: 44),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null)
                  trailing!
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GmTappable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: const Icon(
          Icons.chevron_left_rounded,
          color: AppColors.accent,
          size: 28,
        ),
      ),
    );
  }
}

// ── GmCircleButton ────────────────────────────────────────────
class GmCircleButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final Color? background;
  final Color? border;

  const GmCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.background,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GmTappable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background ?? AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: border ?? AppColors.border,
          ),
          boxShadow: background == AppColors.accent
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: icon,
      ),
    );
  }
}

// ── GmSearchInput ─────────────────────────────────────────────
class GmSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool hasText;

  const GmSearchInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.hasText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 17, color: AppColors.text3),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 15,
                color: AppColors.text,
              ),
              decoration: InputDecoration.collapsed(
                hintText: hintText,
                hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 15,
                  color: AppColors.text3,
                ),
              ),
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 13, color: AppColors.text3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── GmChip ────────────────────────────────────────────────────
class GmChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const GmChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GmTappable(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent : AppColors.text2,
          ),
        ),
      ),
    );
  }
}

// ── GmCard ────────────────────────────────────────────────────
class GmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GmCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}

// ── GmTypeTile ────────────────────────────────────────────────
class GmTypeTile extends StatelessWidget {
  final VehicleType? vehicleType;
  final double size;

  const GmTypeTile({super.key, this.vehicleType, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        vehicleType?.abbreviation ?? '—',
        style: GoogleFonts.ibmPlexMono(
          fontSize: size * 0.27,
          fontWeight: FontWeight.w600,
          color: AppColors.text2,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── GmSectionLabel ────────────────────────────────────────────
class GmSectionLabel extends StatelessWidget {
  final String label;

  const GmSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.ibmPlexSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.text3,
        ),
      ),
    );
  }
}

// ── GmDataRow ─────────────────────────────────────────────────
class GmDataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool last;

  const GmDataRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14,
                  color: AppColors.text2,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: mono
                      ? GoogleFonts.ibmPlexMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        )
                      : GoogleFonts.ibmPlexSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.hair),
      ],
    );
  }
}

// ── GmFooterBar ───────────────────────────────────────────────
class GmFooterBar extends StatelessWidget {
  final Widget child;

  const GmFooterBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom > 0 ? bottom : 16),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.hair)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── GmField ───────────────────────────────────────────────────
/// Label + content wrapper for form fields.
class GmField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const GmField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
                letterSpacing: 0.1,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC0362C),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

// ── GmPrimaryButton ───────────────────────────────────────────
class GmPrimaryButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const GmPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
