import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service to track app version and force logout on updates
class VersionService {
  static const String _versionKey = 'app_version';

  // ⚠️ INCREMENT THIS VERSION WHEN YOU DEPLOY NEW UPDATES ⚠️
  // This will force all logged-in users to logout and re-login
  static const String currentVersion = '1.0.6'; // Changed to force logout test

  /// Check if user needs to logout due to version update
  /// Returns true if user should be forced to logout
  static Future<bool> shouldForceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString(_versionKey);

    print('[VERSION] 🌐 Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
    print('[VERSION] Current version: $currentVersion');
    print('[VERSION] Saved version: $savedVersion');

    // If no saved version, this is first time - save current version
    if (savedVersion == null) {
      await _saveCurrentVersion();
      print('[VERSION] First launch - saved version');
      return false;
    }

    // If versions don't match, force logout
    if (savedVersion != currentVersion) {
      print('[VERSION] ⚠️ Version mismatch - forcing logout');
      return true;
    }

    print('[VERSION] ✓ Version matches - no logout needed');
    return false;
  }

  /// Save current version after successful login/logout
  static Future<void> updateVersion() async {
    await _saveCurrentVersion();
    print('[VERSION] ✓ Version updated to: $currentVersion');
  }

  static Future<void> _saveCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, currentVersion);
    print('[VERSION] 💾 Saved version: $currentVersion (${kIsWeb ? "localStorage" : "SharedPreferences"})');
  }

  /// Clear version (call on logout)
  static Future<void> clearVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
    print('[VERSION] Version cleared');
  }
}
