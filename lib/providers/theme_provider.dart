import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';

  ThemeMode _themeMode = ThemeMode.dark;
  Color _primaryColor = const Color(0xFFFF6F00); // Default Saffron
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load ThemeMode
    final String? themeStr = _prefs?.getString(_themeModeKey);
    if (themeStr != null) {
      if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    // Load Primary Color
    final int? colorValue = _prefs?.getInt(_primaryColorKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    
    notifyListeners();
  }

  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_themeModeKey, isOn ? 'dark' : 'light');
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_primaryColorKey, color.value);
  }
}
