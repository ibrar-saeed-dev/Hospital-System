import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color palette reflecting modern "emergency-tech" healthcare design
class AppColors {
  AppColors._();

  // Primary Emergency Reds
  static const Color primaryRed = Color(0xFFE11D2E);
  static const Color redDark = Color(0xFFB0121F);
  static const Color redTint = Color(0xFFFDECEE);
  static const Color redLight = Color(0xFFFFF1F2);

  // Deep Darks / Inks
  static const Color black = Color(0xFF0B0B0F);
  static const Color ink = Color(0xFF16161D);
  static const Color inkLight = Color(0xFF22222D);

  // Grey Scale & Surfaces
  static const Color textPrimary = Color(0xFF16161D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  // Status & Telemetry Indicators
  static const Color green = Color(0xFF16A34A);
  static const Color greenTint = Color(0xFFDCFCE7);
  static const Color greenDark = Color(0xFF15803D);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberTint = Color(0xFFFEF3C7);
  static const Color amberDark = Color(0xFFB45309);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueTint = Color(0xFFDBEAFE);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleTint = Color(0xFFEDE9FE);
}

/// Spacing scale (4, 8, 12, 16, 24, 32, 48)
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

/// Border Radii
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double pill = 999.0;

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
}

/// Typography Scale: "Sora" for headings & numbers, "Inter" for body
class AppTypography {
  AppTypography._();

  // Headings & Big Display Numbers (Sora)
  static TextStyle display({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.sora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing ?? -0.5,
    );
  }

  static TextStyle headingLarge({
    Color color = AppColors.ink,
    double fontSize = 24,
  }) =>
      GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle headingMedium({
    Color color = AppColors.ink,
    double fontSize = 20,
  }) =>
      GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      );

  static TextStyle headingSmall({
    Color color = AppColors.ink,
    double fontSize = 16,
  }) =>
      GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle statNumber({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.5,
      );

  // Body & UI (Inter)
  static TextStyle bodyLarge({
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.5,
      );

  static TextStyle bodyMedium({
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.4,
      );

  static TextStyle bodySmall({
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textSecondary,
  }) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle label({
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textSecondary,
    double fontSize = 11,
    double letterSpacing = 0.5,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle button({
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.white,
    double fontSize = 15,
  }) =>
      GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: 0.2,
      );
}

/// Central AppTheme definition
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryRed,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primaryRed,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.redTint,
        onPrimaryContainer: AppColors.redDark,
        secondary: AppColors.black,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.borderLight,
        onSecondaryContainer: AppColors.ink,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.primaryRed,
        onError: AppColors.white,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTypography.display(fontSize: 36),
        displayMedium: AppTypography.display(fontSize: 28),
        displaySmall: AppTypography.display(fontSize: 24),
        headlineLarge: AppTypography.headingLarge(),
        headlineMedium: AppTypography.headingMedium(),
        headlineSmall: AppTypography.headingSmall(),
        titleLarge: AppTypography.headingMedium(),
        titleMedium: AppTypography.headingSmall(),
        titleSmall: AppTypography.bodyMedium(fontWeight: FontWeight.w600),
        bodyLarge: AppTypography.bodyLarge(),
        bodyMedium: AppTypography.bodyMedium(),
        bodySmall: AppTypography.bodySmall(),
        labelLarge: AppTypography.label(fontSize: 13),
        labelMedium: AppTypography.label(fontSize: 11),
        labelSmall: AppTypography.label(fontSize: 10),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headingMedium(),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          textStyle: AppTypography.button(color: AppColors.ink),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyMedium(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
