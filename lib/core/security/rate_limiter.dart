import 'package:flutter/foundation.dart';

/// Rate limiter to prevent abuse and DOS attacks
/// Limits the number of requests per endpoint within a time window
class RateLimiter {
  // Store request timestamps for each endpoint
  static final Map<String, List<DateTime>> _requestHistory = {};

  // Configuration
  static const int _maxRequestsPerMinute = 60;
  static const int _maxRequestsPer10Seconds = 15;
  static const int _maxLoginAttempts = 5;
  static const int _loginBlockDuration = 15; // minutes

  // Track failed login attempts
  static final Map<String, List<DateTime>> _failedLoginAttempts = {};
  static final Map<String, DateTime> _blockedUsers = {};

  /// Check if request is allowed for the given endpoint
  static bool isRequestAllowed(String endpoint) {
    final now = DateTime.now();

    // Initialize history for this endpoint
    if (!_requestHistory.containsKey(endpoint)) {
      _requestHistory[endpoint] = [];
    }

    final history = _requestHistory[endpoint]!;

    // Remove old entries (older than 1 minute)
    history.removeWhere((timestamp) {
      return now.difference(timestamp).inMinutes >= 1;
    });

    // Check requests in the last minute
    if (history.length >= _maxRequestsPerMinute) {
      debugPrint('[SECURITY] Rate limit exceeded for $endpoint (per minute)');
      return false;
    }

    // Check requests in the last 10 seconds
    final recent = history.where((timestamp) {
      return now.difference(timestamp).inSeconds <= 10;
    }).length;

    if (recent >= _maxRequestsPer10Seconds) {
      debugPrint('[SECURITY] Rate limit exceeded for $endpoint (per 10 seconds)');
      return false;
    }

    // Add current request
    history.add(now);
    return true;
  }

  /// Record a failed login attempt
  static void recordFailedLogin(String identifier) {
    final now = DateTime.now();

    if (!_failedLoginAttempts.containsKey(identifier)) {
      _failedLoginAttempts[identifier] = [];
    }

    final attempts = _failedLoginAttempts[identifier]!;

    // Remove old attempts (older than 15 minutes)
    attempts.removeWhere((timestamp) {
      return now.difference(timestamp).inMinutes >= _loginBlockDuration;
    });

    attempts.add(now);

    // Check if should block user
    if (attempts.length >= _maxLoginAttempts) {
      _blockedUsers[identifier] = now;
      debugPrint('[SECURITY] User blocked due to too many failed login attempts: $identifier');
    }
  }

  /// Check if user is blocked from login
  static bool isLoginBlocked(String identifier) {
    if (!_blockedUsers.containsKey(identifier)) {
      return false;
    }

    final blockedAt = _blockedUsers[identifier]!;
    final now = DateTime.now();

    // Check if block duration has passed
    if (now.difference(blockedAt).inMinutes >= _loginBlockDuration) {
      _blockedUsers.remove(identifier);
      _failedLoginAttempts.remove(identifier);
      return false;
    }

    return true;
  }

  /// Get remaining block time for user
  static Duration? getRemainingBlockTime(String identifier) {
    if (!_blockedUsers.containsKey(identifier)) {
      return null;
    }

    final blockedAt = _blockedUsers[identifier]!;
    final now = DateTime.now();
    final elapsed = now.difference(blockedAt);
    final remaining = Duration(minutes: _loginBlockDuration) - elapsed;

    if (remaining.isNegative) {
      _blockedUsers.remove(identifier);
      _failedLoginAttempts.remove(identifier);
      return null;
    }

    return remaining;
  }

  /// Record successful login (clear failed attempts)
  static void recordSuccessfulLogin(String identifier) {
    _failedLoginAttempts.remove(identifier);
    _blockedUsers.remove(identifier);
  }

  /// Get number of failed login attempts
  static int getFailedLoginAttempts(String identifier) {
    if (!_failedLoginAttempts.containsKey(identifier)) {
      return 0;
    }

    final now = DateTime.now();
    final attempts = _failedLoginAttempts[identifier]!;

    // Remove old attempts
    attempts.removeWhere((timestamp) {
      return now.difference(timestamp).inMinutes >= _loginBlockDuration;
    });

    return attempts.length;
  }

  /// Clear all rate limit data
  static void clearAll() {
    _requestHistory.clear();
    _failedLoginAttempts.clear();
    _blockedUsers.clear();
  }

  /// Clear rate limit for specific endpoint
  static void clearEndpoint(String endpoint) {
    _requestHistory.remove(endpoint);
  }

  /// Check if specific action is being done too frequently
  /// Useful for preventing spam (e.g., sending too many messages, creating too many items)
  static bool isActionAllowed(String actionKey, {
    int maxActions = 10,
    Duration window = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();

    if (!_requestHistory.containsKey(actionKey)) {
      _requestHistory[actionKey] = [];
    }

    final history = _requestHistory[actionKey]!;

    // Remove old entries
    history.removeWhere((timestamp) {
      return now.difference(timestamp) >= window;
    });

    // Check if limit exceeded
    if (history.length >= maxActions) {
      debugPrint('[SECURITY] Action rate limit exceeded for $actionKey');
      return false;
    }

    // Add current action
    history.add(now);
    return true;
  }

  /// Get statistics for monitoring
  static Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'endpoints': _requestHistory.length,
      'blocked_users': _blockedUsers.length,
      'total_requests': 0,
    };

    _requestHistory.forEach((endpoint, history) {
      stats['total_requests'] += history.length;
    });

    return stats;
  }
}
