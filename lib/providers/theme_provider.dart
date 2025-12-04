import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

enum CoffeeTheme {
  morning,  // Light, warm, cozy
  evening,  // Dark, elegant, sophisticated
  sunset,   // Gradient, vibrant, romantic
  midnight, // Very dark, minimalist, professional
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'coffee_theme';
  CoffeeTheme _currentTheme = CoffeeTheme.morning;

  CoffeeTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      _currentTheme = CoffeeTheme.values.firstWhere(
        (theme) => theme.name == savedTheme,
        orElse: () => CoffeeTheme.morning,
      );
    }

    notifyListeners();
  }

  Future<void> setTheme(CoffeeTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    notifyListeners();
  }

  Future<void> nextTheme() async {
    final themes = CoffeeTheme.values;
    final currentIndex = themes.indexOf(_currentTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    await setTheme(themes[nextIndex]);
  }

  String get themeName => _currentTheme.name;
  String get themeDisplayName {
    switch (_currentTheme) {
      case CoffeeTheme.morning:
        return 'Morning Coffee';
      case CoffeeTheme.evening:
        return 'Evening Vibes';
      case CoffeeTheme.sunset:
        return 'Sunset Mode';
      case CoffeeTheme.midnight:
        return 'Midnight Brew';
    }
  }

  // Get current theme data
  ThemeData get themeData {
    switch (_currentTheme) {
      case CoffeeTheme.morning:
        return _morningTheme;
      case CoffeeTheme.evening:
        return _eveningTheme;
      case CoffeeTheme.sunset:
        return _sunsetTheme;
      case CoffeeTheme.midnight:
        return _midnightTheme;
    }
  }

  // Backward compatibility
  ThemeData get lightTheme => _morningTheme;
  ThemeData get darkTheme => _eveningTheme;

  // Check if current theme is dark mode
  bool get isDarkMode {
    switch (_currentTheme) {
      case CoffeeTheme.evening:
      case CoffeeTheme.midnight:
        return true;
      case CoffeeTheme.morning:
      case CoffeeTheme.sunset:
        return false;
    }
  }

  // Get card color for current theme
  Color get cardColor {
    switch (_currentTheme) {
      case CoffeeTheme.morning:
        return Colors.white.withValues(alpha: 0.8);
      case CoffeeTheme.evening:
        return const Color(0xFF1F2937).withValues(alpha: 0.8);
      case CoffeeTheme.sunset:
        return Colors.white.withValues(alpha: 0.8);
      case CoffeeTheme.midnight:
        return const Color(0xFF111111);
    }
  }

  // Background color getter
  Color get backgroundColor {
    switch (_currentTheme) {
      case CoffeeTheme.morning:
        return const Color(0xFFFFFEF7); // Warm cream
      case CoffeeTheme.evening:
        return const Color(0xFF1E1B4B); // Elegant dark violet
      case CoffeeTheme.sunset:
        return const Color(0xFFFEF3F2); // Warm pink background
      case CoffeeTheme.midnight:
        return const Color(0xFF0F172A); // Elegant dark blue-black
    }
  }

  // Dynamic color getters based on current theme
  Color get primaryTextColor {
    switch (_currentTheme) {
      case CoffeeTheme.morning:
        return const Color(0xFF5C4033); // Coffee brown
      case CoffeeTheme.evening:
        return const Color(0xFFF3E8FF); // Soft violet
      case CoffeeTheme.sunset:
        return const Color(0xFF881337); // Dark pink
      case CoffeeTheme.midnight:
        return const Color(0xFF6EE7B7); // Soft emerald
    }
  }

  Color get secondaryTextColor {
    switch (_currentTheme) {
      case CoffeeTheme.morning:
        return const Color(0xFF8B6914); // Darker coffee
      case CoffeeTheme.evening:
        return const Color(0xFFCBD5E1); // Light violet gray
      case CoffeeTheme.sunset:
        return const Color(0xFFBE185D); // Darker pink
      case CoffeeTheme.midnight:
        return const Color(0xFF94A3B8); // Light emerald gray
    }
  }

  Color get accentColor {
    switch (_currentTheme) {
      case CoffeeTheme.morning:
        return const Color(0xFFD2691E); // Warm coffee
      case CoffeeTheme.evening:
        return const Color(0xFF8B5CF6); // Violet
      case CoffeeTheme.sunset:
        return const Color(0xFFEC4899); // Pink
      case CoffeeTheme.midnight:
        return const Color(0xFF10B981); // Emerald
    }
  }

  // Morning Theme - Light, warm, cozy coffee shop vibes
  ThemeData get _morningTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD2691E), // Warm coffee brown
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: const Color(0xFFFFFEF7), // Warm cream

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFEF7), // Warm cream background
        foregroundColor: Color(0xFF5C4033),
        elevation: 0,
        centerTitle: true,
      ),

      // Glass Card Theme
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.white.withValues(alpha: 0.5),
      ),

      // Modern Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD2691E),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFFD2691E).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Glass Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD2691E), width: 2),
        ),
      ),

      // Modern Text Theme
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5C4033),
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5C4033),
          letterSpacing: -0.25,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5C4033),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF5C4033),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFF5C4033),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF6B7280),
          height: 1.4,
        ),
      ),

      // Modern Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFFD2691E),
        size: 24,
      ),

      // Glass Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        selectedItemColor: const Color(0xFFD2691E),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
      ),
    );
  }

  // Evening Theme - Dark, elegant, sophisticated
  ThemeData get _eveningTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B5CF6), // Violet
        brightness: Brightness.dark,
      ),

      scaffoldBackgroundColor: const Color(0xFF1E1B4B), // Elegant dark violet

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: const Color(0xFFF3E8FF),
        elevation: 0,
        centerTitle: true,
      ),

      // Dark Glass Cards
      cardTheme: CardThemeData(
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: const Color(0xFF1F2937).withValues(alpha: 0.8),
        surfaceTintColor: const Color(0xFF6B46C1).withValues(alpha: 0.2),
      ),

      // Elegant Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B46C1),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: const Color(0xFF6B46C1).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Dark Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937).withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 2),
        ),
      ),

      // Dark Modern Text Theme
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF3E8FF),
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF3E8FF),
          letterSpacing: -0.25,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF3E8FF),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFF3E8FF),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFFE2E8F0),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFCBD5E1),
          height: 1.4,
        ),
      ),

      // Dark Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFF8B5CF6),
        size: 24,
      ),

      // Dark Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1B4B).withValues(alpha: 0.95),
        selectedItemColor: const Color(0xFFF3E8FF),
        unselectedItemColor: const Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Color(0xFFF3E8FF)),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  // Sunset Theme - Gradient, vibrant, romantic
  ThemeData get _sunsetTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFEC4899), // Pink
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: const Color(0xFFFEF3F2), // Warm pink background

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFEF3F2), // Warm pink background
        foregroundColor: const Color(0xFF831843),
        elevation: 0,
        centerTitle: true,
      ),

      // Gradient Cards
      cardTheme: CardThemeData(
        elevation: 10,
        shadowColor: const Color(0xFFEC4899).withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: const Color(0xFFEC4899).withValues(alpha: 0.1),
      ),

      // Vibrant Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC4899),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: const Color(0xFFEC4899).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Sunset Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
        ),
      ),

      // Vibrant Text Theme
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF881337), // Darker pink for better contrast
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF881337),
          letterSpacing: -0.25,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF881337),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF881337),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFF9F1239), // Darker but still readable
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFBE185D),
          height: 1.4,
        ),
      ),

      // Sunset Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFFEC4899),
        size: 24,
      ),

      // Sunset Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        selectedItemColor: const Color(0xFFEC4899),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
      ),
    );
  }

  // Midnight Theme - Elegant dark, professional
  ThemeData get _midnightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10B981), // Emerald green
        brightness: Brightness.dark,
      ),

      scaffoldBackgroundColor: const Color(0xFF0F172A), // Elegant dark blue-black

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFF6EE7B7), // Soft emerald
        elevation: 0,
        centerTitle: true,
      ),

      // Minimalist Dark Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        color: const Color(0xFF111111),
        surfaceTintColor: const Color(0xFF10B981).withValues(alpha: 0.1),
      ),

      // Professional Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),

      // Minimalist Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1),
        ),
      ),

      // Professional Text Theme (changed from jetBrainsMono to inter for better readability)
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6EE7B7), // Soft emerald for better contrast
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6EE7B7),
          letterSpacing: -0.25,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6EE7B7),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6EE7B7),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFFCBD5E1), // Light gray for readability
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF94A3B8),
          height: 1.4,
        ),
      ),

      // Professional Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFF6EE7B7), // Soft emerald
        size: 24,
      ),

      // Professional Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF6EE7B7),
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Color(0xFF6EE7B7)),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, color: Color(0xFF94A3B8)),
      ),
    );
  }
}