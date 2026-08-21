import 'package:flutter/material.dart';

class ThemeViewModel {
  // State terpusat untuk menyimpan mode tema (Light / Dark)
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  // Getter untuk mengecek status Dark Mode
  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  // Aksi/Fungsi logika untuk mengubah tema
  static void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}