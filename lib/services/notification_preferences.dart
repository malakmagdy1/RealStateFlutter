import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/core/utils/web_utils.dart';

/// Service to manage notification preferences
class NotificationPreferences {
  static const String _key = 'notifications_enabled';
  static const String _webLocalStorageKey = 'flutter.notifications_enabled';

  /// Get whether notifications are enabled
  /// Returns true by default (notifications enabled)
  static Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_key) ?? true; // enabled by default

      print('[NotificationPreferences] ✅ Getting preference: $value');
      return value;
    } catch (e) {
      print('[NotificationPreferences] ❌ Error getting preference: $e');
      return true; // default to enabled on error
    }
  }

  /// Set whether notifications are enabled
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      print('[NotificationPreferences] 🔄 Setting notifications to: $enabled');

      // Save to SharedPreferences (works on all platforms)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
      print('[NotificationPreferences] ✅ SharedPreferences saved: $_key = $enabled');

      // For web, ALSO save directly to localStorage so service worker can read it
      if (kIsWeb) {
        try {
          // Use the web_utils to set localStorage directly
          setLocalStorageItem(_webLocalStorageKey, enabled.toString());
          print('[NotificationPreferences] ✅ Web localStorage saved: $_webLocalStorageKey = ${enabled.toString()}');

          // Verify it was saved
          final verifyValue = getLocalStorageItem(_webLocalStorageKey);
          print('[NotificationPreferences] 🔍 Verification - localStorage value: $verifyValue');
        } catch (webError) {
          print('[NotificationPreferences] ⚠️ Web localStorage error: $webError');
        }
      }

      print('[NotificationPreferences] ✅ Notifications ${enabled ? "enabled" : "disabled"}');
    } catch (e, stackTrace) {
      print('[NotificationPreferences] ❌ Error setting preference: $e');
      print('[NotificationPreferences] ❌ Stack trace: $stackTrace');
      rethrow;
    }
  }
}
