import 'package:shared_preferences/shared_preferences.dart';

/// Service to get the current app language for API requests
class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static String _localeKey = 'app_locale';

  /// Statically get current language (use this in web services)
  /// Returns 'en' or 'ar'
  static String get currentLanguage {
    // For now, return 'en' as default
    // This will be loaded synchronously from SharedPreferences in a real implementation
    return _currentLang ?? 'en';
  }

  static String? _currentLang;

  /// Initialize and load the saved language
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLang = prefs.getString(_localeKey) ?? 'en';
    } catch (e) {
      _currentLang = 'en';
    }
  }

  /// Update the current language
  static Future<void> setLanguage(String languageCode) async {
    _currentLang = languageCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
    } catch (e) {
      // Ignore error
    }
  }
}
