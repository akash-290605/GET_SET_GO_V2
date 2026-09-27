import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  dark,
  light,
  system,
}

class AppColors {
  // Brand Accents
  static const Color primary = Color(0xFF8B5CF6); // Electric Violet
  static const Color primaryGlow = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF06B6D4); // Cyber Cyan
  static const Color secondaryGlow = Color(0xFF22D3EE);
  static const Color accentGreen = Color(0xFF10B981); // Emerald Green
  static const Color accentAmber = Color(0xFFF59E0B); // Sunset Amber
  static const Color accentRose = Color(0xFFF43F5E); // Radiant Rose
  static const Color accentBlue = Color(0xFF3B82F6); // Cosmic Blue
  static const Color accentPurple = Color(0xFFC084FC); // Soft Lilac

  // Neutral / Surface tokens
  static const Color background = Color(0xFF090D18);
  static const Color surface = Color(0xFF11182B);
  static const Color surfaceElevated = Color(0xFF18223C);
  static const Color surfaceHighlight = Color(0xFF1E2C4D);
  static const Color borderLight = Color(0x1FFFFFFF);
  static const Color borderGlow = Color(0x408B5CF6);
  static const Color textMuted = Color(0xFF94A3B8);

  // Dark Palette
  static const Color darkBackground = Color(0xFF090D18);
  static const Color darkSurface = Color(0xFF11182B);
  static const Color darkSurfaceElevated = Color(0xFF18223C);
  static const Color darkSurfaceHighlight = Color(0xFF1E2C4D);
  static const Color darkBorder = Color(0x24FFFFFF);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextPrimary = Colors.white;

  // Light Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceHighlight = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0x1F0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextPrimary = Color(0xFF0F172A);
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
