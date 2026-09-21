import "package:flutter/material.dart";

class AppTheme {
  // Primary & Accent - Exact Match to 777 Seller App
  static const Color primaryColor = Color(0xFF10B981); // Solid Emerald
  static const Color primaryLight = Color(0xFF34D399);
  static const Color accentColor = Color(0xFF6366F1); // Indigo Accent

  // 777 Seller Dark Palette
  static const Color darkBackgroundColor = Color(0xFF020617); // Deeper Black/Navy
  static const Color darkSurfaceColor = Color(0xFF1E293B); // Lighter Slate (Card color)
  static const Color darkSurfaceElevated = Color(0xFF0F172A); // Darker Slate (Input color)
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorderColor = Color(0xFF334155); // Visible border

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Tricolor Brand Accents
  static const Color saffron = Color(0xFFFF9933);
  static const Color flagGreen = Color(0xFF138808);

  // Compatibility aliases
  static const Color bgCanvas = darkBackgroundColor;
  static const Color cardSurface = darkSurfaceColor;
  static const Color cardElevated = darkSurfaceElevated;
  static const Color inputSurface = darkSurfaceElevated;
  static const Color mintGreen = primaryColor;
  static const Color mintGreenLight = primaryLight;
  static const Color appleBlue = info;
  static const Color electricViolet = accentColor;
  static const Color goldAccent = warning;
  static const Color dangerRed = error;
  static const Color warningOrange = warning;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderSubtle = darkBorderColor;
  static const Color borderHighlight = Color(0x4D10B981);

  // Helper for flexible border radius
  static BorderRadius _toBorderRadius(dynamic val, double fallback) {
    if (val is BorderRadius) return val;
    if (val is num) return BorderRadius.circular(val.toDouble());
    return BorderRadius.circular(fallback);
  }

  // Seller App Emerald Hero Card Decoration
  static BoxDecoration heroCardDecoration({
    dynamic borderRadius,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF10B981),
          Color(0xFF047857),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: _toBorderRadius(borderRadius, 24),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Apple Card Brushed Metallic alias (maps to Hero Card)
  static BoxDecoration appleCardDecoration({
    dynamic borderRadius,
    Color? borderColor,
  }) {
    return heroCardDecoration(borderRadius: borderRadius);
  }

  // Seller App Card Decoration
  static BoxDecoration cardDecoration({
    Color? bgColor,
    Color? borderColor,
    dynamic borderRadius,
  }) {
    return BoxDecoration(
      color: bgColor ?? darkSurfaceColor,
      borderRadius: _toBorderRadius(borderRadius, 20),
      border: Border.all(
        color: borderColor ?? darkBorderColor,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Seller App Pill / Input Decoration
  static BoxDecoration pillDecoration({
    Color? bgColor,
    Color? borderColor,
    bool isActive = false,
  }) {
    return BoxDecoration(
      color: bgColor ?? (isActive ? primaryColor.withValues(alpha: 0.15) : darkSurfaceElevated),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive ? primaryColor : (borderColor ?? darkBorderColor),
        width: isActive ? 1.5 : 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: darkSurfaceColor,
        onSurface: darkTextPrimary,
        outline: darkBorderColor,
        surfaceContainerHighest: darkSurfaceColor,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderColor,
        thickness: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkTextPrimary, letterSpacing: -1),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: darkTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondary, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        floatingLabelStyle: const TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorderColor),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
