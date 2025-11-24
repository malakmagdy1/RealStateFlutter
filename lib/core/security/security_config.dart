import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Security configuration and utilities
class SecurityConfig {
  // API endpoint - ensure HTTPS in production
  static const String apiBaseUrl = 'https://api.aqarapp.co';

  // Security settings
  static const bool enableSecureMode = true;
  static const bool requireHttps = kReleaseMode; // Only enforce in production
  static const bool enableCertificatePinning = false; // Can be enabled for extra security
  static const bool enableRequestSigning = false; // Can be enabled for API request signing

  // Session settings
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration refreshTokenLifetime = Duration(days: 30);

  // Validate if URL is secure
  static bool isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https' || (!requireHttps && uri.scheme == 'http');
    } catch (e) {
      debugPrint('[SECURITY] Invalid URL: $url');
      return false;
    }
  }

  /// Enforce HTTPS for web platform
  static void enforceHttps() {
    if (kIsWeb && requireHttps) {
      // Check if running on HTTP in production
      final currentUrl = Uri.base.toString();
      if (currentUrl.startsWith('http://') && !currentUrl.contains('localhost')) {
        // Redirect to HTTPS
        final httpsUrl = currentUrl.replaceFirst('http://', 'https://');
        debugPrint('[SECURITY] Redirecting to HTTPS: $httpsUrl');
        // Note: Actual redirect would need to be done via JavaScript
      }
    }
  }

  /// Get secure headers for API requests
  static Map<String, String> getSecureHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };

    // Add authentication token
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Add security headers
    if (enableSecureMode) {
      headers['X-Frame-Options'] = 'DENY';
      headers['X-Content-Type-Options'] = 'nosniff';
      headers['X-XSS-Protection'] = '1; mode=block';
    }

    return headers;
  }

  /// Validate API response
  static bool isValidApiResponse(dynamic response) {
    if (response == null) return false;

    // Check for common injection patterns in response
    if (response is String) {
      final suspicious = [
        '<script',
        'javascript:',
        'onerror=',
        'onclick=',
      ];

      final lower = response.toLowerCase();
      for (var pattern in suspicious) {
        if (lower.contains(pattern)) {
          debugPrint('[SECURITY] Suspicious content in API response detected');
          return false;
        }
      }
    }

    return true;
  }

  /// Check if request should be allowed based on environment
  static bool shouldAllowRequest(String endpoint) {
    // In debug mode, allow all requests
    if (kDebugMode) return true;

    // In production, validate endpoint
    if (!isSecureUrl(endpoint)) {
      debugPrint('[SECURITY] Insecure endpoint blocked: $endpoint');
      return false;
    }

    return true;
  }

  /// Get CORS configuration for web
  static Map<String, String> getCorsHeaders() {
    return {
      'Access-Control-Allow-Origin': kReleaseMode ? apiBaseUrl : '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '3600',
    };
  }

  /// Check if session is expired
  static bool isSessionExpired(DateTime? lastActivity) {
    if (lastActivity == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    return difference > sessionTimeout;
  }

  /// Get security recommendations
  static List<String> getSecurityRecommendations() {
    final recommendations = <String>[];

    if (!requireHttps) {
      recommendations.add('Enable HTTPS enforcement in production');
    }

    if (!enableCertificatePinning) {
      recommendations.add('Consider enabling certificate pinning for enhanced security');
    }

    if (!enableRequestSigning) {
      recommendations.add('Consider enabling request signing for API authentication');
    }

    return recommendations;
  }

  /// Log security event
  static void logSecurityEvent(String event, {
    String? details,
    SecurityEventLevel level = SecurityEventLevel.info,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final message = '[$timestamp] [${level.name.toUpperCase()}] $event';

    switch (level) {
      case SecurityEventLevel.critical:
        debugPrint('🚨 $message ${details ?? ''}');
        break;
      case SecurityEventLevel.warning:
        debugPrint('⚠️ $message ${details ?? ''}');
        break;
      case SecurityEventLevel.info:
        debugPrint('ℹ️ $message ${details ?? ''}');
        break;
    }
  }
}

/// Security event severity levels
enum SecurityEventLevel {
  info,
  warning,
  critical,
}

/// Security middleware for API calls
class SecurityMiddleware {
  /// Pre-process request before sending
  static Map<String, dynamic> preprocessRequest(Map<String, dynamic> data) {
    // Remove null values
    data.removeWhere((key, value) => value == null);

    // Validate data types
    data.forEach((key, value) {
      if (value is String && value.length > 10000) {
        SecurityConfig.logSecurityEvent(
          'Unusually large string in request',
          details: 'Key: $key, Length: ${value.length}',
          level: SecurityEventLevel.warning,
        );
      }
    });

    return data;
  }

  /// Post-process response after receiving
  static dynamic postprocessResponse(dynamic response) {
    if (!SecurityConfig.isValidApiResponse(response)) {
      SecurityConfig.logSecurityEvent(
        'Suspicious API response detected',
        level: SecurityEventLevel.critical,
      );
      throw Exception('Security: Invalid API response detected');
    }

    return response;
  }
}
