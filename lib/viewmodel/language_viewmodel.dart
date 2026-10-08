import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageViewModel {
  LanguageViewModel._();

  static const String _key = 'app_language';

  /// 'id' = Indonesia, 'en' = English
  static final ValueNotifier<String> lang = ValueNotifier<String>('id');

  static bool get isEnglish => lang.value == 'en';

  /// Panggil sekali saat aplikasi mulai (opsional, supaya pilihan bahasa
  /// tersimpan setelah aplikasi ditutup).
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'id' || saved == 'en') {
        lang.value = saved!;
      }
    } catch (_) {}
  }

  static Future<void> setLanguage(String code) async {
    if (code == lang.value) return;
    lang.value = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
  }
}

/// Pemakaian: tr('Teks Indonesia', 'English text')
String tr(String id, String en) => LanguageViewModel.isEnglish ? en : id;