import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  dark,
  light,
  system,
}

class AppColors {
  // Brand Accents
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryGlow = Color(0xFF3B82F6); // Bright Blue
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color secondaryGlow = Color(0xFF22D3EE);
  static const Color purple = Color(0xFF7C3AED); // Violet / Purple
  static const Color purpleGlow = Color(0xFFA78BFA);
  static const Color accentGreen = Color(0xFF16A34A); // Emerald Green / Success
  static const Color accentAmber = Color(0xFFF59E0B); // Amber / Warning
  static const Color accentRose = Color(0xFFDC2626); // Crimson / Error
  static const Color accentBlue = Color(0xFF2563EB); // Royal Blue

  // Light Mode Color System
  static const Color lightBackground = Color(0xFFF5F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC);
  static const Color lightSurfaceHighlight = Color(0xFFEEF2F6);
  static const Color lightBorder = Color(0x2664748B); // rgba(100,116,139,0.15)
  static const Color lightTextPrimary = Color(0xFF172033);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF090D18);
  static const Color darkSurface = Color(0xFF11182B);
  static const Color darkSurfaceElevated = Color(0xFF18223C);
  static const Color darkSurfaceHighlight = Color(0xFF1E2C4D);
  static const Color darkBorder = Color(0x24FFFFFF);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Static Legacy / Default Tokens (for const constructors)
  static const Color surface = darkSurface;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color surfaceHighlight = darkSurfaceHighlight;
  static const Color textMuted = darkTextMuted;
  static const Color accentPurple = purple;
  static const Color purpleAccent = purple;
  static const Color borderLight = lightBorder;
  static const Color borderGlow = Color(0x402563EB);
  static const Color textMutedLegacy = darkTextMuted;

  // Dynamic Theme Helpers
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getSurfaceElevated(bool isDark) => isDark ? darkSurfaceElevated : lightSurfaceElevated;
  static Color cardBackground(bool isDark) => isDark 
      ? const Color(0xFF11182B).withValues(alpha: 0.82) 
      : Colors.white.withValues(alpha: 0.88);
  static Color cardBorder(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color textMutedDynamic(bool isDark) => isDark ? darkTextMuted : lightTextMuted;
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  static const String _themePrefKey = 'gsg_app_theme_mode_v3';
  AppThemeMode _themeMode = AppThemeMode.dark;

  AppThemeMode get themeMode => _themeMode;
  bool isDarkMode(BuildContext context) {
    if (_themeMode == AppThemeMode.dark) return true;
    if (_themeMode == AppThemeMode.light) return false;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themePrefKey);
      if (saved == 'light') {
        _themeMode = AppThemeMode.light;
      } else if (saved == 'system') {
        _themeMode = AppThemeMode.system;
      } else {
        _themeMode = AppThemeMode.dark;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeService init error: $e');
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = mode == AppThemeMode.light ? 'light' : (mode == AppThemeMode.system ? 'system' : 'dark');
      await prefs.setString(_themePrefKey, str);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: Colors.transparent,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        error: AppColors.accentRose,
        onSurface: AppColors.darkTextPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
    );
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: Colors.transparent,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        error: AppColors.accentRose,
        onSurface: AppColors.lightTextPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
    );
  }
}
