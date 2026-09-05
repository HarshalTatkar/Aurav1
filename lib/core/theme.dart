import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── AURA Color System (Premium Health-Tech) ────────────────────────
class AuraColors {
  AuraColors._();

  // Premium Backgrounds & Surfaces
  static const Color background = Color(0xFFF4F6F8); // Soft off-white
  static const Color surface = Colors.white; 
  static const Color surfaceElevated = Color(0xFFF8FAFC); // Slightly elevated neutral
  static const Color glassBorder = Color(0xFFE2E8F0);

  // Semantic Status Colors (Controlled & Professional)
  static const Color healthy = Color(0xFF0F766E); // Deep forest/emerald
  static const Color healthyDim = Color(0x150F766E);

  static const Color warning = Color(0xFFD97706); // Warm Amber
  static const Color warningDim = Color(0x15D97706);

  static const Color moderate = Color(0xFFEA580C); // Orange
  static const Color moderateDim = Color(0x15EA580C);

  static const Color critical = Color(0xFFE11D48); // Coral/Red
  static const Color criticalDim = Color(0x15E11D48);

  // Technology & Data accents
  static const Color techBlue = Color(0xFF0EA5E9); // Cool Cyan
  static const Color techBlueDim = Color(0x150EA5E9);

  // Typography Colors (Deep graphite)
  static const Color textPrimary = Color(0xFF1E293B); // Charcoal / Deep graphite
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color riskColor(int score) {
    if (score <= 30) return healthy;
    if (score <= 60) return warning;
    if (score <= 80) return moderate;
    return critical;
  }

  static Color riskDimColor(int score) {
    if (score <= 30) return healthyDim;
    if (score <= 60) return warningDim;
    if (score <= 80) return moderateDim;
    return criticalDim;
  }
}

// ─── Shadows (Subtle 3D Depth) ────────────────────────────────────────────────
class AuraShadows {
  static List<BoxShadow> get card {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
        blurRadius: 2,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> get cardElevated {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
        blurRadius: 8,
        spreadRadius: -2,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 4,
        spreadRadius: -1,
        offset: const Offset(0, 2),
      ),
    ];
  }
  
  static List<BoxShadow> get subtle {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
        blurRadius: 1,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];
  }
}

// ─── Typography (Modern Premium) ───────────────────────────────────────────
class AuraTypography {
  AuraTypography._();

  static TextTheme get textTheme {
    return GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AuraColors.textPrimary,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AuraColors.textPrimary,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AuraColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AuraColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AuraColors.textPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AuraColors.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AuraColors.textPrimary,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuraColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AuraColors.textSecondary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AuraColors.textSecondary,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AuraColors.textSecondary,
      ),
    );
  }
}

class AuraSpacing {
  static const double sm = 8.0;
  static const double base = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 40.0;
}

class AuraRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;
}

// ─── Theme Data ──────────────────────────────────────────────────────────────
class AuraTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AuraColors.background,
      textTheme: AuraTypography.textTheme,
      colorScheme: const ColorScheme.light(
        primary: AuraColors.healthy,
        secondary: AuraColors.techBlue,
        surface: AuraColors.surface,
        error: AuraColors.critical,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AuraColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AuraColors.textPrimary),
        titleTextStyle: AuraTypography.textTheme.titleLarge,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AuraColors.surface,
        selectedItemColor: AuraColors.healthy,
        unselectedItemColor: AuraColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AuraColors.healthy,
        inactiveTrackColor: AuraColors.glassBorder,
        thumbColor: AuraColors.healthy,
        overlayColor: AuraColors.healthy.withValues(alpha: 0.2),
        trackHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AuraColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AuraColors.healthy;
          return AuraColors.glassBorder;
        }),
      ),
    );
  }
}
