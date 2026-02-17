import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._(this._prefs) {
    _themeMode = _readThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeController._(prefs);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, _encodeThemeMode(mode));
    notifyListeners();
  }

  ThemeMode _readThemeMode() {
    final stored = _prefs.getString(_themeModeKey);
    if (stored == null) {
      return ThemeMode.system;
    }
    return _decodeThemeMode(stored);
  }

  ThemeMode _decodeThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _encodeThemeMode(ThemeMode value) {
    switch (value) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
