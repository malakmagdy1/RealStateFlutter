import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Defensive URL helper to handle both full URLs and relative paths
/// This ensures images load correctly regardless of the format stored in the database
class UrlHelpers {
  // Base URL for the Laravel backend
  // For Android emulator, use 10.0.2.2 to access host machine's localhost
  static const String _baseUrl = 'http://10.0.2.2/larvel2';

  /// Fixes image URL to work on Android emulator
  ///
  /// Handles three cases:
  /// 1. If URL already has http/https -> replaces localhost with 10.0.2.2
  /// 2. If URL is a relative path -> prepends base URL
  /// 3. If URL is empty/null -> returns empty string
  ///
  /// Example:
  /// ```dart
  /// // Full URL from DB
  /// fixImageUrl('http://localhost/larvel2/storage/company-logos/123.png')
  /// // Returns: 'http://10.0.2.2/larvel2/storage/company-logos/123.png'
  ///
  /// // Relative path from DB
  /// fixImageUrl('storage/company-logos/123.png')
  /// // Returns: 'http://10.0.2.2/larvel2/storage/company-logos/123.png'
  /// ```
  static String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // Case 1: URL already has http/https prefix
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // If running on Android emulator, replace localhost/127.0.0.1 with 10.0.2.2
      if (!kIsWeb && Platform.isAndroid) {
        return url
            .replaceFirst(RegExp(r'https?://localhost'), 'http://10.0.2.2')
            .replaceFirst(RegExp(r'https?://127\.0\.0\.1'), 'http://10.0.2.2')
            .replaceFirst(RegExp(r'https?://192\.168\.[0-9.]+'), 'http://10.0.2.2');
      }
      return url;
    }

    // Case 2: Relative path - prepend base URL
    // Remove leading slash if present to avoid double slashes
    final path = url.startsWith('/') ? url.substring(1) : url;
    return '$_baseUrl/$path';
  }

  /// Checks if a URL is valid and ready to be used
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
