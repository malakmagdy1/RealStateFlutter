import 'dart:async';
import 'package:flutter/material.dart';

/// Singleton class to manage token expiration events
/// and trigger navigation to login screen when token expires
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  // Stream controller to broadcast token expiration events
  final _tokenExpiredController = StreamController<bool>.broadcast();
  Stream<bool> get onTokenExpired => _tokenExpiredController.stream;

  // Global navigator key to allow navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Call this when token expires (401 error detected)
  void notifyTokenExpired() {
    print('[TokenManager] Token expired - notifying listeners');
    _tokenExpiredController.add(true);
  }

  /// Navigate to login screen
  void navigateToLogin() {
    print('[TokenManager] Navigating to login screen');
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  void dispose() {
    _tokenExpiredController.close();
  }
}
