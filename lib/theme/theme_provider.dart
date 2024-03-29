import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_calculator/theme/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;
  ThemeData get themeData => _themeData;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    _saveThemePreference(themeData);
    notifyListeners();
  }

  void toggleTheme() {
    themeData = _themeData == lightMode ? darkMode : lightMode;
  }

  Future<void> _saveThemePreference(ThemeData themeData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', themeData == lightMode ? 'light' : 'dark');
  }

  Future<void> loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String theme = prefs.getString('theme') ?? 'light';
    themeData = theme == 'light' ? lightMode : darkMode;
  }
}
