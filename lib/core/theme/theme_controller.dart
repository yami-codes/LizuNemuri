import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeController(this._prefs) {
    // Load theme mode from persistence
    final savedThemeMode = _prefs.getString(_themeKey);
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedThemeMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    // Persist theme mode
    await _prefs.setString(_themeKey, mode.toString());
  }

  // Cycle to next theme mode
  Future<void> toggleThemeMode() async {
    const modes = ThemeMode.values;
    final currentIndex = modes.indexOf(_themeMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setThemeMode(modes[nextIndex]);
  }
} 