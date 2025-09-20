import 'package:flutter/material.dart';

ThemeData buildAppTheme(TextTheme text) {
  final primaryColor = const Color(0xFF34D399); // Vibrant green
  final secondaryColor = const Color(0xFF059669); // Darker green
  final textColor = const Color(0xFF6B7280); // Subtle grey for text
  final backgroundColor = const Color(0xFFFFFFFF); // Crisp white
  final lightGrey = const Color(0xFFF3F4F6); // Light grey for backgrounds/borders

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor,
      background: backgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1F2937), // Darker text for contrast
      onBackground: const Color(0xFF1F2937),
      error: const Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF111827),
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF111827),
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
      bodyLarge: text.bodyLarge?.copyWith(
        color: textColor,
      ),
      bodyMedium: text.bodyMedium?.copyWith(
        color: textColor,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: const Color(0xFF1F2937),
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2937),
        fontSize: 18,
      ),
      iconTheme: IconThemeData(
        color: textColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Removed focus border color
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(
        color: textColor.withOpacity(0.8),
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: backgroundColor,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withOpacity(0.1),
      selectedColor: primaryColor.withOpacity(0.2),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: secondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: backgroundColor,
      elevation: 8,
      height: 65,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primaryColor, size: 24);
        }
        return IconThemeData(color: textColor, size: 24);
      }),
    ),
  );
}
