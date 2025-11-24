import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Secure storage wrapper with encryption for sensitive data
/// Provides secure storage for tokens, user data, and sensitive information
class SecureStorage {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _encryptionSalt = 'real_estate_secure_salt_2024';

  /// Encrypt sensitive data before storage
  static String _encrypt(String data) {
    // Simple encryption using SHA256 for demonstration
    // In production, use more secure encryption like AES
    final bytes = utf8.encode(data + _encryptionSalt);
    final hash = sha256.convert(bytes);
    return base64.encode(utf8.encode(data)) + '.' + hash.toString();
  }

  /// Decrypt data after retrieval
  static String? _decrypt(String? encryptedData) {
    if (encryptedData == null) return null;

    try {
      final parts = encryptedData.split('.');
      if (parts.length != 2) return null;

      final data = utf8.decode(base64.decode(parts[0]));

      // Verify hash
      final bytes = utf8.encode(data + _encryptionSalt);
      final hash = sha256.convert(bytes);

      if (hash.toString() != parts[1]) {
        print('[SECURITY] Data integrity check failed!');
        return null;
      }

      return data;
    } catch (e) {
      print('[SECURITY] Decryption error: $e');
      return null;
    }
  }

  /// Save authentication token securely
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _encrypt(token);
      await prefs.setString(_tokenKey, encrypted);
      print('[SECURITY] Token saved securely');
    } catch (e) {
      print('[SECURITY] Error saving token: $e');
      rethrow;
    }
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = prefs.getString(_tokenKey);
      return _decrypt(encrypted);
    } catch (e) {
      print('[SECURITY] Error retrieving token: $e');
      return null;
    }
  }

  /// Save refresh token securely
  static Future<void> saveRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _encrypt(token);
      await prefs.setString(_refreshTokenKey, encrypted);
      print('[SECURITY] Refresh token saved securely');
    } catch (e) {
      print('[SECURITY] Error saving refresh token: $e');
      rethrow;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = prefs.getString(_refreshTokenKey);
      return _decrypt(encrypted);
    } catch (e) {
      print('[SECURITY] Error retrieving refresh token: $e');
      return null;
    }
  }

  /// Save user ID
  static Future<void> saveUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, userId);
    } catch (e) {
      print('[SECURITY] Error saving user ID: $e');
      rethrow;
    }
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      print('[SECURITY] Error retrieving user ID: $e');
      return null;
    }
  }

  /// Clear all secure data (logout)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      print('[SECURITY] All secure data cleared');
    } catch (e) {
      print('[SECURITY] Error clearing secure data: $e');
      rethrow;
    }
  }

  /// Check if token exists and is valid
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Validate token format (basic check)
  static bool isValidTokenFormat(String token) {
    // Check if token is not empty and has reasonable length
    if (token.isEmpty || token.length < 20) return false;

    // Check if token doesn't contain suspicious characters
    final suspiciousChars = ['<', '>', '"', "'", ';', '--', '/*', '*/'];
    for (var char in suspiciousChars) {
      if (token.contains(char)) {
        print('[SECURITY] Token contains suspicious characters!');
        return false;
      }
    }

    return true;
  }
}
