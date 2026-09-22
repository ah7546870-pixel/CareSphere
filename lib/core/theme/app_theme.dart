import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Palette (Mild & Medical for Seniors) ───────────────────────────
  static const Color primaryTeal = Color(0xFF0E7490); // Calm Hospital Cyan/Teal
  static const Color primaryTealDark = Color(0xFF155E75); // Deep Clinical Marine
  static const Color primaryTealLight = Color(0xFF0284C7); // Soft Medical Sky Blue

  static const Color accentIndigo = Color(0xFF3B82F6); // Mild Clinical Slate Blue
  static const Color accentPurple = Color(0xFF6366F1); // Soft Lavender
  static const Color accentRose = Color(0xFFE05368); // Mild Therapeutic Coral/Rose
  static const Color accentEmerald = Color(0xFF16A34A); // Calming Clinical Sage Green
  static const Color accentAmber = Color(0xFFD97706); // Warm Amber

  // ── Light Surface (Soft on elder eyes, non-glaring) ──────────────────────
  static const Color bgLight = Color(0xFFF8FAFC); // Pearl off-white
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure clean white
  static const Color borderLight = Color(0xFFE2E8F0); // Soft subtle border

  // ── Dark Surfaces (Mild clinical slate/navy) ────────────────────────────
  static const Color deepNavy = Color(0xFF1E293B);
  static const Color navyCard = Color(0xFF243347);
  static const Color navyBorder = Color(0xFF334155);

  // ── Typography (High legibility for older adults) ───────────────────────────
  static const Color textPrimary = Color(0xFF1E293B); // Deep charcoal slate
  static const Color textSecondary = Color(0xFF475569); // Muted slate
  static const Color textTertiary = Color(0xFF64748B); // Gentle slate
  static const Color textOnDark = Color(0xFFF1F5F9);

  // ── Gradients (Calming, dignified medical gradients) ──────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, primaryTealLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient authDarkGradient = LinearGradient(
    colors: [Color(0xFF132238), Color(0xFF18304B), Color(0xFF132D38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF155E75), Color(0xFF0E7490)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient medicalSlateGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF2B608A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE05368), Color(0xFFC53030)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    primaryColor: primaryTeal,
    colorScheme: const ColorScheme.light(
      primary: primaryTeal,
      secondary: accentIndigo,
      tertiary: accentRose,
      surface: surfaceLight,
      error: accentRose,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 34,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.outfit(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.outfit(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: GoogleFonts.outfit(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      labelLarge: GoogleFonts.inter(
        color: primaryTeal,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderLight, width: 1.2),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentRose, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentRose, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryTeal.withValues(alpha: 0.1),
      side: BorderSide(color: primaryTeal.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold),
    ),
    dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: navyCard,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static ThemeData darkTheme = lightTheme;
}
