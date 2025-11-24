import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌍 Language Service
/// Handles language detection and switching
class LanguageService {
  static const String _languageKey = 'app_language';
  static String _currentLanguage = 'ar'; // Default to Arabic
  
  /// Get current language code
  static String get currentLanguage => _currentLanguage;
  
  /// Check if current language is Arabic
  static bool get isArabic => _currentLanguage == 'ar';
  
  /// Check if current language is English
  static bool get isEnglish => _currentLanguage == 'en';
  
  /// Initialize language from saved preferences
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_languageKey) ?? 'ar';
    } catch (e) {
      print('[LanguageService] Error loading language: $e');
      _currentLanguage = 'ar';
    }
  }
  
  /// Set language
  static Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('[LanguageService] Error saving language: $e');
    }
  }
  
  /// Toggle between Arabic and English
  static Future<void> toggleLanguage() async {
    await setLanguage(_currentLanguage == 'ar' ? 'en' : 'ar');
  }
  
  /// Get language from context
  static String getLanguageFromContext(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }
  
  /// Detect language from text
  static String detectTextLanguage(String text) {
    if (text.isEmpty) return _currentLanguage;
    
    // Check for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    final arabicMatches = arabicRegex.allMatches(text).length;
    
    // Check for English characters
    final englishRegex = RegExp(r'[a-zA-Z]');
    final englishMatches = englishRegex.allMatches(text).length;
    
    // Return language with more characters
    if (arabicMatches > englishMatches) return 'ar';
    if (englishMatches > arabicMatches) return 'en';
    return _currentLanguage;
  }
  
  /// Get text direction for language
  static TextDirection getTextDirection([String? languageCode]) {
    final lang = languageCode ?? _currentLanguage;
    return lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// Get locale for language
  static Locale getLocale([String? languageCode]) {
    final lang = languageCode ?? _currentLanguage;
    return Locale(lang);
  }
}

/// Language-aware text widget
class LocalizedText extends StatelessWidget {
  final String arabicText;
  final String englishText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const LocalizedText({
    super.key,
    required this.arabicText,
    required this.englishText,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
  
  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageService.isArabic;
    
    return Text(
      isArabic ? arabicText : englishText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}
