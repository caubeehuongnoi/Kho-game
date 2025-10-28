import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _textScale = 1.0; // Giới hạn từ 0.8 đến 1.4

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    final scale = prefs.getDouble('textScale') ?? 1.0;

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _textScale = scale.clamp(0.8, 1.4);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value.clamp(0.8, 1.4);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', _textScale);
  }
}