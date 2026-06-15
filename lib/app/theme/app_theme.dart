import 'package:flutter/material.dart';

/// Design token centrali dell'app.
/// I valori saranno estratti dai mockup in docs/demo/ nella Fase 6.
abstract final class AppColors {
  static const primary = Color(0xFF1565C0); // blu associazione
  static const seedColor = primary;
}

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seedColor,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seedColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
