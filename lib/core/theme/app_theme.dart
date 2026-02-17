import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF1565C0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(elevation: 0),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
      ),
    );
  }
}
