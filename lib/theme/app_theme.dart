import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF5A8A5A); // Sage green
  static const Color primaryGreenDark = Color(0xFF4A6B4A);
  static const Color primaryGreenLight = Color(0xFF7BA37B);
  
  static const Color accentTerracotta = Color(0xFFC97D60); // Warm terracotta
  static const Color accentTerracottaLight = Color(0xFFE5A68A);
  
  static const Color earthBrown = Color(0xFF8B6F47); // Earthy brown
  static const Color earthBrownLight = Color(0xFFA68B6B);
  
  static const Color softBeige = Color(0xFFF5F1E8); // Soft beige background
  static const Color warmWhite = Color(0xFFFDFCF9);
  
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textMedium = Color(0xFF5A5A5A);
  static const Color textLight = Color(0xFF8A8A8A);
  
  static const Color successGreen = Color(0xFF6B9E6B);
  static const Color warningAmber = Color(0xFFD4A574);
  static const Color errorRed = Color(0xFFC97D60);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: accentTerracotta,
        tertiary: earthBrown,
        surface: warmWhite,
        background: softBeige,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onBackground: textDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Transparent to show animated background
      appBarTheme: AppBarTheme(
        backgroundColor: warmWhite.withOpacity(0.8), // Glassmorphism for AppBar
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: const TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: warmWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(
          color: textMedium,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: warmWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textLight,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentTerracotta,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: warmWhite,
        selectedColor: primaryGreenLight.withOpacity(0.2),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textDark,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: textDark,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          color: textDark,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textDark,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textMedium,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: textLight,
          fontSize: 12,
        ),
      ),
    );
  }

  static const Color darkBackground = Color(0xFF1B1F1B); // Very dark green-tinted
  static const Color darkSurface = Color(0xFF2A2F2A); // Dark surface with green tint
  static const Color darkSurfaceElevated = Color(0xFF333833); // Elevated surface
  static const Color darkCardBackground = Color(0xFF252A25); // Card background
  
  static const Color darkTextLight = Color(0xFFE8EDE8); // Light text with green tint
  static const Color darkTextMedium = Color(0xFFB8BFB8); // Medium text with green tint
  static const Color darkTextDark = Color(0xFF8A918A); // Dark text with green tint
  
  static const Color darkPrimaryGreen = Color(0xFF7BA37B); // Brighter sage green
  static const Color darkAccentTerracotta = Color(0xFFE5A68A); // Softer terracotta
  static const Color darkSuccessGreen = Color(0xFF8BC98B); // Brighter success
  static const Color darkWarningAmber = Color(0xFFE8C48A); // Softer warning
  static const Color darkErrorRed = Color(0xFFE59B85); // Softer error

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryGreen,
        secondary: darkAccentTerracotta,
        tertiary: earthBrownLight,
        surface: darkSurface,
        background: darkBackground,
        error: darkErrorRed,
        onPrimary: darkBackground,
        onSecondary: darkBackground,
        onSurface: darkTextLight,
        onBackground: darkTextLight,
        onError: darkBackground,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Transparent to show animated background
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface.withOpacity(0.8), // Glassmorphism for AppBar
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.5),
        iconTheme: const IconThemeData(color: darkTextLight),
        titleTextStyle: const TextStyle(
          color: darkTextLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryGreen,
          foregroundColor: darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: darkPrimaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3F443F), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3F443F), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkErrorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkErrorRed, width: 2),
        ),
        labelStyle: const TextStyle(
          color: darkTextMedium,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF6A716A),
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimaryGreen,
        unselectedItemColor: darkTextDark,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkAccentTerracotta,
        foregroundColor: darkBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceElevated,
        selectedColor: darkPrimaryGreen.withOpacity(0.2),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkTextLight,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: darkTextLight,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          color: darkTextLight,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: darkTextLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: darkTextLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: darkTextLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: darkTextLight,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: darkTextMedium,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: darkTextDark,
          fontSize: 12,
        ),
      ),
    );
  }
  
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : softBeige;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackground
        : warmWhite;
  }
  
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimaryGreen
        : primaryGreen;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextLight
        : textDark;
  }
  
  static Color getTextMediumColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextMedium
        : textMedium;
  }
  
  static Color getTextLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextDark
        : textLight;
  }
}

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}

