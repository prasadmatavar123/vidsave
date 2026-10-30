import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFA855F7);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFF87171);
  static const warning = Color(0xFFF59E0B);
  static const gradient = LinearGradient(
    colors: [violet, violetLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

extension ThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  Color get muted => cs.onSurfaceVariant;
}

class AppTheme {
  static const double radius = 22;

  static ThemeData dark() => _build(
        Brightness.dark,
        const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          onPrimary: Colors.white,
          secondary: AppColors.violetLight,
          surface: Color(0xFF161622),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFF9CA3AF),
          error: AppColors.error,
          outline: Color(0xFF3A3A4D),
          outlineVariant: Color(0xFF262636),
        ),
        const Color(0xFF0A0A12),
      );

  static ThemeData light() => _build(
        Brightness.light,
        const ColorScheme.light(
          primary: AppColors.violet,
          onPrimary: Colors.white,
          secondary: AppColors.violetLight,
          surface: Colors.white,
          onSurface: Color(0xFF14121F),
          onSurfaceVariant: Color(0xFF6B7280),
          error: Color(0xFFDC2626),
          outline: Color(0xFFCFCBE0),
          outlineVariant: Color(0xFFE5E3F0),
        ),
        const Color(0xFFF6F5FB),
      );

  static ThemeData _build(Brightness b, ColorScheme s, Color bg) {
    final base = ThemeData(brightness: b, useMaterial3: true);
    final text = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: s.onSurface, displayColor: s.onSurface);
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: s,
      scaffoldBackgroundColor: bg,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surface,
        indicatorColor: s.primary.withOpacity(.18),
        height: 68,
        labelTextStyle: WidgetStateProperty.all(
            text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.onSurface.withOpacity(.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: s.primary, width: 1.4)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
