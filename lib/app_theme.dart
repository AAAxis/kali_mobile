import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryVariant = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF03DAC6);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF000000);
  static const Color lightOnBackground = Color(0xFF000000);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  
  // Common colors
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);

  // Custom colors for specific screens
  static const Color dashboardPrimary = Color(0xFF6366F1); // Indigo
  static const Color dashboardSecondary = Color(0xFF8B5CF6); // Purple
  static const Color dashboardBackground = Color(0xFFF8FAFC); // Light blue-gray
  static const Color dashboardSurface = Color(0xFFFFFFFF);
  static const Color dashboardAccent = Color(0xFF10B981); // Emerald

  static const Color settingsPrimary = Color(0xFF059669); // Emerald
  static const Color settingsSecondary = Color(0xFF0891B2); // Cyan
  static const Color settingsBackground = Color(0xFFF0FDF4); // Light green
  static const Color settingsSurface = Color(0xFFFFFFFF);
  static const Color settingsAccent = Color(0xFF6366F1); // Indigo

  static const Color notificationsPrimary = Color(0xFFDC2626); // Red
  static const Color notificationsSecondary = Color(0xFFEA580C); // Orange
  static const Color notificationsBackground = Color(0xFFFEF2F2); // Light red
  static const Color notificationsSurface = Color(0xFFFFFFFF);
  static const Color notificationsAccent = Color(0xFFF59E0B); // Amber

  // Dark versions
  static const Color dashboardBackgroundDark = Color(0xFF000000); // Pure black
  static const Color dashboardSurfaceDark = Color(0xFF1E1E1E); // Dark gray

  static const Color settingsBackgroundDark = Color(0xFF064E3B); // Dark emerald
  static const Color settingsSurfaceDark = Color(0xFF065F46); // Emerald

  static const Color notificationsBackgroundDark = Color(0xFF7F1D1D); // Dark red
  static const Color notificationsSurfaceDark = Color(0xFF991B1B); // Red
  
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightOnBackground),
        titleTextStyle: TextStyle(
          color: lightOnBackground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightBackground,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: lightBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: lightOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: lightOnBackground,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: lightOnBackground,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: lightOnBackground,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: lightOnBackground,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: lightOnBackground,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: lightOnBackground,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
      ),
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkOnBackground),
        titleTextStyle: TextStyle(
          color: darkOnBackground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: darkOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: darkOnBackground,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkOnBackground,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: darkOnBackground,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: darkOnBackground,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: darkOnBackground,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: darkOnBackground,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
      ),
    );
  }

  // Custom theme configurations for specific screens
  static Map<String, Color> getDashboardColors(bool isDark) {
    return {
      'background': isDark ? dashboardBackgroundDark : dashboardBackground,
      'surface': isDark ? dashboardSurfaceDark : dashboardSurface,
      'primary': dashboardPrimary,
      'secondary': dashboardSecondary,
      'accent': dashboardAccent,
      'text': isDark ? Colors.white : Colors.black87,
      'textSecondary': isDark ? Colors.grey[300]! : Colors.grey[600]!,
      'icon': isDark ? Colors.white70 : Colors.grey[700]!,
    };
  }

  static Map<String, Color> getSettingsColors(bool isDark) {
    return {
      'background': isDark ? Colors.black : Colors.white,
      'surface': isDark ? Color(0xFF1E1E1E) : Colors.white,
      'primary': isDark ? Colors.white : Colors.black,
      'secondary': isDark ? Colors.grey[300]! : Colors.grey[700]!,
      'accent': isDark ? Colors.white70 : Colors.black87,
      'text': isDark ? Colors.white : Colors.black87,
      'textSecondary': isDark ? Colors.grey[300]! : Colors.grey[600]!,
      'icon': isDark ? Colors.white70 : Colors.grey[700]!,
    };
  }

  static Map<String, Color> getNotificationsColors(bool isDark) {
    return {
      'background': isDark ? Colors.black : Colors.white,
      'surface': isDark ? Color(0xFF1E1E1E) : Colors.white,
      'primary': isDark ? Colors.white : Colors.black,
      'secondary': isDark ? Colors.grey[300]! : Colors.grey[700]!,
      'accent': isDark ? Colors.white70 : Colors.black87,
      'text': isDark ? Colors.white : Colors.black87,
      'textSecondary': isDark ? Colors.grey[300]! : Colors.grey[600]!,
      'icon': isDark ? Colors.white70 : Colors.grey[700]!,
    };
  }
  
  // Current theme (hardcoded to light for now)
  static ThemeData get currentTheme => lightTheme;
  
  // Helper method to check if current theme is dark
  static bool get isDark => false; // Hardcoded to false for now
  
  // Helper method to get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
} 