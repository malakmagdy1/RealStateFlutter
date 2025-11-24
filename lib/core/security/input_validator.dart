import 'package:flutter/foundation.dart';

/// Input validation and sanitization utility
/// Prevents XSS, SQL Injection, and other injection attacks
class InputValidator {
  // Regex patterns for validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$', // E.164 format
  );

  static final RegExp _alphanumericRegex = RegExp(r'^[a-zA-Z0-9\s]+$');

  // Name regex: Supports letters (including international), spaces, dots, hyphens, apostrophes
  // Using a more permissive pattern that works across all platforms
  static final RegExp _nameRegex = RegExp(
    r"^[a-zA-Z\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\s\.\-']+$",
    unicode: true, // Support international characters including Arabic
  );

  // Dangerous characters and patterns
  static final List<String> _sqlInjectionPatterns = [
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER',
    'EXEC', 'EXECUTE', 'UNION', 'DECLARE', '--', '/*', '*/', ';',
    'xp_', 'sp_', 'WAITFOR', 'DELAY', 'BENCHMARK', 'SLEEP',
  ];

  static final List<String> _xssPatterns = [
    '<script', '</script>', 'javascript:', 'onerror=', 'onload=',
    'onclick=', 'onmouseover=', '<iframe', '</iframe>', '<object',
    '<embed', 'eval(', 'expression(', 'vbscript:', 'data:text/html',
  ];

  /// Sanitize general text input
  static String sanitizeText(String input, {int? maxLength}) {
    if (input.isEmpty) return input;

    String sanitized = input.trim();

    // Limit length
    if (maxLength != null && sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');

    // Remove control characters except newlines and tabs
    sanitized = sanitized.replaceAll(
      RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'),
      '',
    );

    return sanitized;
  }

  /// Validate and sanitize email
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    final sanitized = sanitizeText(email.toLowerCase(), maxLength: 255);

    if (!_emailRegex.hasMatch(sanitized)) {
      return 'Invalid email format';
    }

    // Check for suspicious patterns
    if (_containsSuspiciousPatterns(sanitized)) {
      return 'Email contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate and sanitize password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (password.length > 128) {
      return 'Password is too long';
    }

    // Check for null bytes
    if (password.contains('\x00')) {
      return 'Password contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate and sanitize name
  static String? validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.isEmpty) {
      return '$fieldName is required';
    }

    final sanitized = sanitizeText(name, maxLength: 100);

    if (sanitized.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (!_nameRegex.hasMatch(sanitized)) {
      return '$fieldName contains invalid characters';
    }

    // Check for suspicious patterns
    if (_containsSuspiciousPatterns(sanitized)) {
      return '$fieldName contains invalid characters';
    }

    return null; // Valid
  }

  /// Validate phone number
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Phone is optional in many cases
    }

    // Remove spaces, dashes, parentheses
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Invalid phone number format';
    }

    return null; // Valid
  }

  /// Validate search query
  static String? validateSearchQuery(String? query) {
    if (query == null || query.isEmpty) {
      return null; // Empty search is allowed
    }

    final sanitized = sanitizeText(query, maxLength: 200);

    // Check for SQL injection patterns
    if (_containsSqlInjection(sanitized)) {
      debugPrint('[SECURITY] SQL injection attempt detected in search: $query');
      return 'Search query contains invalid characters';
    }

    return null; // Valid
  }

  /// Check for SQL injection patterns
  static bool _containsSqlInjection(String input) {
    final upperInput = input.toUpperCase();

    for (var pattern in _sqlInjectionPatterns) {
      if (upperInput.contains(pattern.toUpperCase())) {
        return true;
      }
    }

    return false;
  }

  /// Check for XSS patterns
  static bool _containsXss(String input) {
    final lowerInput = input.toLowerCase();

    for (var pattern in _xssPatterns) {
      if (lowerInput.contains(pattern.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// Check for suspicious patterns (both SQL and XSS)
  static bool _containsSuspiciousPatterns(String input) {
    return _containsSqlInjection(input) || _containsXss(input);
  }

  /// Sanitize HTML (remove all HTML tags)
  static String stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/');
  }

  /// Escape special characters for safe display
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Validate URL
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // URL is optional
    }

    try {
      final uri = Uri.parse(url);

      // Only allow http and https
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return 'Invalid URL scheme';
      }

      // Check for suspicious patterns
      if (_containsXss(url)) {
        debugPrint('[SECURITY] XSS attempt detected in URL: $url');
        return 'URL contains invalid characters';
      }

      return null; // Valid
    } catch (e) {
      return 'Invalid URL format';
    }
  }

  /// Validate numeric input
  static String? validateNumber(String? input, {
    String fieldName = 'Value',
    double? min,
    double? max,
  }) {
    if (input == null || input.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(input);

    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null; // Valid
  }

  /// Sanitize user input before API calls
  static Map<String, dynamic> sanitizeApiPayload(Map<String, dynamic> payload) {
    final sanitized = <String, dynamic>{};

    payload.forEach((key, value) {
      if (value is String) {
        sanitized[key] = sanitizeText(value);
      } else if (value is Map) {
        sanitized[key] = sanitizeApiPayload(value as Map<String, dynamic>);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return sanitizeText(item);
          } else if (item is Map) {
            return sanitizeApiPayload(item as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }
}
