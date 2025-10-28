import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CasheNetwork {
  static late SharedPreferences sharedPref;

  static Future casheInitialization() async {
    sharedPref = await SharedPreferences.getInstance();

    if (kIsWeb) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🌐 Web Storage Initialized');
      print('═══════════════════════════════════════════════════════');
      // Force reload to ensure web localStorage is synced
      await sharedPref.reload();
      final testToken = sharedPref.getString('token');
      if (testToken != null && testToken.isNotEmpty) {
        print('✅ Found existing token in localStorage');
        print('Token: ${testToken.substring(0, 20)}...');
      } else {
        print('ℹ️  No token found in localStorage');
      }
      print('═══════════════════════════════════════════════════════');
      print('');
    }
  }

  static Future<bool> insertToCashe({
    required String key,
    required String value,
  }) async {
    final result = await sharedPref.setString(key, value);

    if (kIsWeb) {
      // Force commit on web to ensure it's saved to localStorage immediately
      await sharedPref.reload();
      final saved = sharedPref.getString(key);
      if (saved == value) {
        print('✅ [Web Storage] Successfully saved $key to localStorage');
      } else {
        print('❌ [Web Storage] Failed to save $key to localStorage');
      }
    }

    return result;
  }

  static String getCasheData({required String key}) {
    return sharedPref.getString(key) ?? "";
  }

  /// Async version for web - reloads from localStorage first
  static Future<String> getCasheDataAsync({required String key}) async {
    if (kIsWeb) {
      await sharedPref.reload();
    }
    return sharedPref.getString(key) ?? "";
  }

  static Future<bool> deletecasheItem({required String key}) async {
    final result = await sharedPref.remove(key);

    if (kIsWeb) {
      await sharedPref.reload();
      print('🗑️ [Web Storage] Deleted $key from localStorage');
    }

    return result;
  }
}
