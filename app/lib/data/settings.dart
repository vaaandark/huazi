import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式：跟随系统 / 浅色 / 深色
class AppSettings {
  AppSettings._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('theme_mode');
    themeMode.value = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
