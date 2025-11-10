import 'package:flutter/foundation.dart';
import 'package:real/core/utils/constant.dart';

/// A ChangeNotifier that notifies listeners when auth state changes
/// This is used by GoRouter to refresh its redirect logic
class AuthStateNotifier extends ChangeNotifier {
  static final AuthStateNotifier _instance = AuthStateNotifier._internal();

  factory AuthStateNotifier() {
    return _instance;
  }

  AuthStateNotifier._internal();

  bool get isLoggedIn => token != null && token != "";

  /// Call this method whenever the token changes (login/logout)
  void notifyAuthChanged() {
    print('[AuthStateNotifier] Auth state changed, notifying router...');
    notifyListeners();
  }
}
