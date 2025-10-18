import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit to manage app locale (language)
class LocaleCubit extends Cubit<Locale> {
  static const String _localeKey = 'app_locale';

  LocaleCubit() : super(const Locale('en')) {
    _loadLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);

    if (languageCode != null) {
      emit(Locale(languageCode));
      print('[LocaleCubit] Loaded locale: $languageCode');
    } else {
      print('[LocaleCubit] No saved locale, using default: en');
    }
  }

  /// Change the app locale
  Future<void> changeLocale(Locale newLocale) async {
    if (state == newLocale) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);

    emit(newLocale);
    print('[LocaleCubit] Changed locale to: ${newLocale.languageCode}');
  }

  /// Toggle between English and Arabic
  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');

    await changeLocale(newLocale);
  }

  /// Get current language name
  String get currentLanguageName {
    return state.languageCode == 'en' ? 'English' : 'العربية';
  }

  /// Check if current language is English
  bool get isEnglish => state.languageCode == 'en';

  /// Check if current language is Arabic
  bool get isArabic => state.languageCode == 'ar';
}
