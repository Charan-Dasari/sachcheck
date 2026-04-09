import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Dark palette ──────────────────────────────────────────────────────────
  static const background = Color(0xFF0D0D1A);
  static const surface = Color(0xFF1A1A2E);
  static const surfaceCard = Color(0xFF16213E);
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9C8FFF);
  static const accent = Color(0xFF00D4FF);
  static const verified = Color(0xFF00E676);
  static const caution = Color(0xFFFFD600);
  static const notVerified = Color(0xFFFF5252);
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF9E9EBE);
  static const divider = Color(0xFF2A2A4A);
  static const shimmerBase = Color(0xFF1E1E36);
  static const shimmerHighlight = Color(0xFF2A2A4A);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF5F5FF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceCard = Color(0xFFEEEEFF);
  static const lightTextPrimary = Color(0xFF13131F);
  static const lightTextSecondary = Color(0xFF6B6B8A);
  static const lightDivider = Color(0xFFD0D0E8);
}

class AppTheme {
  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final surf = isDark ? AppColors.surface : AppColors.lightSurface;
    final txtPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final txtSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final div = isDark ? AppColors.divider : AppColors.lightDivider;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.notVerified,
        onError: Colors.white,
        surface: surf,
        onSurface: txtPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(
        bodyColor: txtPrimary,
        displayColor: txtPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: txtPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: txtPrimary),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: isDark ? 0 : 2,
        shadowColor: isDark ? Colors.transparent : AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: div, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: txtSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: div, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: div),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: div),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: txtSecondary),
        hintStyle: TextStyle(color: txtSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(color: txtPrimary, fontSize: 17, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.inter(color: txtSecondary, fontSize: 13, height: 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
