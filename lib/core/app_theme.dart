import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema visual de la aplicación Caída
class AppTheme {
  AppTheme._();

  // ──────────────────────────────────────────────
  // COLORES
  // ──────────────────────────────────────────────
  static const Color background = Color(0xFF0A1628);
  static const Color surface = Color(0xFF122040);
  static const Color surfaceVariant = Color(0xFF1A2E55);
  static const Color primary = Color(0xFFD4AF37); // Dorado
  static const Color primaryDark = Color(0xFF9B7B1A);
  static const Color accent = Color(0xFF4ECDC4);
  static const Color cardRed = Color(0xFFE53935);
  static const Color cardBlack = Color(0xFF1A1A2E);
  static const Color cardBackground = Color(0xFFFFF8E7);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color mesaBlue = Color(0xFF0038A8);
  static const Color mesaBlueLight = Color(0xFF0056B3);

  // ──────────────────────────────────────────────
  // GRADIENTES
  // ──────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF122040), Color(0xFF0D1F3C)],
  );

  static const LinearGradient mesaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00247D), Color(0xFF0038A8), Color(0xFF0056B3)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFB8860B)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8E7), Color(0xFFFFF3D0)],
  );

  // ──────────────────────────────────────────────
  // TIPOGRAFÍA
  // ──────────────────────────────────────────────
  static TextTheme get textTheme => GoogleFonts.cinzelTextTheme().copyWith(
        displayLarge: GoogleFonts.cinzel(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.cinzel(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.cinzel(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.lato(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.lato(
          color: textSecondary,
          fontSize: 14,
        ),
      );

  // ──────────────────────────────────────────────
  // TEMA MATERIAL
  // ──────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          background: background,
        ),
        textTheme: textTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: background,
            textStyle: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      );

  // ──────────────────────────────────────────────
  // DECORACIONES
  // ──────────────────────────────────────────────
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      );

  static BoxDecoration get mesaDecoration => BoxDecoration(
        gradient: mesaGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
