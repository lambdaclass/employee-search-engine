import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const _themeKey = 'theme_preference';

  static Future<ThemeData> getTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final isDarkMode = preferences.getBool(_themeKey) ?? false;
    return isDarkMode ? ThemeData.dark() : ThemeData.light();
  }

  static Future<void> setTheme(bool isDarkMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themeKey, isDarkMode);
  }
}
