import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;
  static const String _themeKey = 'theme_mode';

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;

  // Charge le thème depuis les préférences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isLoaded = true;
      notifyListeners();
      print('✅ Thème chargé: ${_themeMode == ThemeMode.dark ? "Sombre" : "Clair"}');
    } catch (e) {
      print('❌ Erreur chargement thème: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Change le thème et sauvegarde la préférence
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    print('🔄 Changement de thème vers: ${_themeMode == ThemeMode.dark ? "Sombre" : "Clair"}');
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
      print('💾 Thème sauvegardé');
    } catch (e) {
      print('❌ Erreur sauvegarde thème: $e');
    }
  }

  // Définir un thème spécifique
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    print('🎨 Thème défini: ${mode == ThemeMode.dark ? "Sombre" : "Clair"}');
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, mode == ThemeMode.dark);
      print('💾 Thème sauvegardé');
    } catch (e) {
      print('❌ Erreur sauvegarde thème: $e');
    }
  }
}