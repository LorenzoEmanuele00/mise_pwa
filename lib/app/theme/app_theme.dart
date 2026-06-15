import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens estratti da docs/demo/ ─────────────────────
abstract final class AppColors {
  // Backgrounds
  static const bg = Color(0xFFF1F3F6);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEEF1F5);

  // Borders & dividers
  static const border = Color(0xFFE1E5EC);
  static const hair = Color(0xFFEDF0F4);

  // Text
  static const text = Color(0xFF161B22);
  static const text2 = Color(0xFF5A6473);
  static const text3 = Color(0xFF98A1AE);

  // Accent (blu primario)
  static const accent = Color(0xFF1F62D6);
  static const accentSoft = Color(0xFFE2EBFB);

  // Status
  static const okFg = Color(0xFF0F7A3D);
  static const okBg = Color(0xFFE4F4EA);
  static const warnFg = Color(0xFF9A6206);
  static const warnBg = Color(0xFFFBEFD7);
  static const badFg = Color(0xFFC0362C);
  static const badBg = Color(0xFFFBE7E5);
  static const infoFg = Color(0xFF2563C9);
  static const infoBg = Color(0xFFE6EEFB);
}

abstract final class AppTheme {
  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return GoogleFonts.ibmPlexSansTextTheme(base).copyWith(
      // Assicura che i colori siano corretti per il tema light
      bodyLarge: GoogleFonts.ibmPlexSans(color: AppColors.text),
      bodyMedium: GoogleFonts.ibmPlexSans(color: AppColors.text),
      titleMedium: GoogleFonts.ibmPlexSans(color: AppColors.text, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.ibmPlexSans(color: AppColors.text, fontWeight: FontWeight.w700),
    );
  }

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      primary: AppColors.accent,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surface2,
      outline: AppColors.border,
      error: AppColors.badFg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: _textTheme(Brightness.light),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.ibmPlexSans(
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        iconTheme: const IconThemeData(color: AppColors.accent),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.badFg),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.badFg, width: 1.5),
        ),
        hintStyle: GoogleFonts.ibmPlexSans(color: AppColors.text3, fontSize: 15),
        labelStyle: GoogleFonts.ibmPlexSans(color: AppColors.text2),
        errorStyle: GoogleFonts.ibmPlexSans(color: AppColors.badFg),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.hair,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: GoogleFonts.ibmPlexSans(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.ibmPlexSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        contentTextStyle:
            GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.text2),
      ),
    );
  }

  static ThemeData dark() {
    // Dark mode minimale — Phase 6 lo espande con i token corretti
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        primary: const Color(0xFF6B9EF8),
      ),
      textTheme: _textTheme(Brightness.dark),
    );
  }
}
