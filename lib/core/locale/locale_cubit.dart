import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real/core/locale/language_service.dart';
import 'package:real/services/fcm_service.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';

/// Cubit to manage app locale (language)
class LocaleCubit extends Cubit<Locale> {
  static String _localeKey = 'app_locale';

  LocaleCubit() : super(Locale('en')) {
    _loadLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);

    if (languageCode != null) {
      emit(Locale(languageCode));
      // Update LanguageService
      await LanguageService.setLanguage(languageCode);
      print('[LocaleCubit] Loaded locale: $languageCode');
    } else {
      print('[LocaleCubit] No saved locale, using default: en');
      // Update LanguageService with default
      await LanguageService.setLanguage('en');
    }
  }

  /// Change the app locale
  Future<void> changeLocale(Locale newLocale) async {
    if (state == newLocale) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);

    // Also save to CasheNetwork for FCM service to access
    await CasheNetwork.insertToCashe(key: 'locale', value: newLocale.languageCode);

    // Update LanguageService so API calls use the new language
    await LanguageService.setLanguage(newLocale.languageCode);

    // Update locale on backend for notifications (only if user is logged in)
    final authToken = CasheNetwork.getCasheData(key: 'token');
    if (authToken.isNotEmpty) {
      await FCMService().updateLocale(newLocale.languageCode);
    }

    emit(newLocale);
    print('[LocaleCubit] Changed locale to: ${newLocale.languageCode}');
    print('[LocaleCubit] Updated LanguageService to: ${newLocale.languageCode}');
  }

  /// Toggle between English and Arabic
  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'en'
        ? Locale('ar')
        : Locale('en');

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
