import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/services/fcm_service.dart';
import 'package:real/core/services/route_persistence_service.dart';
import 'package:real/core/services/device_service.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:real/core/security/secure_storage.dart';
import 'package:real/core/security/rate_limiter.dart';
import 'package:real/core/services/version_service.dart';
import 'package:real/feature/notifications/data/services/notification_cache_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _repository;

  LoginBloc({required AuthRepository repository})
      : _repository = repository,
        super(LoginInitial()) {
    on<LoginSubmitEvent>(_onLoginSubmit);
    on<LogoutEvent>(_onLogout);
  }

  // Expose repository for Google sign-in
  AuthRepository get repository => _repository;

  Future<void> _onLoginSubmit(
    LoginSubmitEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      // Get device information
      final deviceInfo = await DeviceService.getAllDeviceInfo();

      // Try login with device information
      final authService = AuthWebServices();
      final response = await authService.loginWithDevice(event.request, deviceInfo);

      // Security: Validate token before storing
      final receivedToken = response.token ?? '';
      if (!SecureStorage.isValidTokenFormat(receivedToken)) {
        print('[SECURITY] Invalid token format received from server');
        // Record failed login
        RateLimiter.recordFailedLogin(event.request.email);
        throw Exception('Invalid authentication response');
      }

      // Security: Store token securely (encrypted)
      await SecureStorage.saveToken(receivedToken);

      // Also save to old storage for backward compatibility (will migrate later)
      await CasheNetwork.insertToCashe(key: "token", value: receivedToken);

      // Save user ID
      if (response.user.id != null) {
        await SecureStorage.saveUserId(response.user.id!);
        await CasheNetwork.insertToCashe(
          key: "user_id",
          value: response.user.id.toString()
        );
      }

      // IMPORTANT: Update global token and userId variables
      token = receivedToken;
      userId = response.user.id?.toString() ?? '';
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[LoginBloc] 🔒 Token saved securely (encrypted)');
      print('[LoginBloc] Token length: ${receivedToken.length}');
      print('[LoginBloc] User ID: ${response.user.id}');
      print('[LoginBloc] Device Info: $deviceInfo');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // Security: Clear failed login attempts on successful login
      RateLimiter.recordSuccessfulLogin(event.request.email);

      // ⭐ SEND FCM TOKEN TO BACKEND AFTER SUCCESSFUL LOGIN (with locale)
      final fcmToken = FCMService().fcmToken;
      if (fcmToken != null) {
        // Get current app locale from cache
        final locale = CasheNetwork.getCasheData(key: 'locale');
        final effectiveLocale = locale.isNotEmpty ? locale : 'en';
        print('[LoginBloc] 📤 Sending FCM token to backend with locale: $effectiveLocale');
        await FCMService().sendTokenToBackend(fcmToken, locale: effectiveLocale);
      } else {
        print('[LoginBloc] ⚠️ FCM token not available');
      }

      // ⚠️ Update version tracking (for force update feature)
      await VersionService.updateVersion();

      emit(LoginSuccess(response));
    } on DeviceLimitException catch (e) {
      // Security: Record failed login attempt
      RateLimiter.recordFailedLogin(event.request.email);
      // Special handling for device limit errors
      emit(LoginDeviceLimitError(e.message, e.devices));
    } catch (e) {
      // Security: Record failed login attempt
      RateLimiter.recordFailedLogin(event.request.email);
      print('[SECURITY] Login failed: ${e.toString()}');
      emit(LoginError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(LogoutLoading());
    try {
      // ⭐ CLEAR FCM TOKEN FROM BACKEND BEFORE LOGOUT
      print('[LoginBloc] 🗑️ Clearing FCM token from backend...');
      await FCMService().clearToken();

      final response = await _repository.logout();

      // Security: Clear all secure data
      await SecureStorage.clearAll();

      // Clear token and user_id from cache and global variables
      await CasheNetwork.deletecasheItem(key: "token");
      await CasheNetwork.deletecasheItem(key: "user_id");
      token = '';
      userId = '';

      // Clear saved route
      await RoutePersistenceService.clearSavedRoute();

      // ⚠️ Clear version tracking (for force update feature)
      await VersionService.clearVersion();

      // 🔔 Clear notification cache on logout
      await NotificationCacheService().clearAllNotifications();
      print('[LoginBloc] 🔔 Notification cache cleared');

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[LoginBloc] 🔒 Logout successful - All secure data cleared');
      print('[LoginBloc] Response: $response');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      final message = response['message']?.toString() ?? 'Logged out successfully';
      emit(LogoutSuccess(message));
    } catch (e) {
      print('[LoginBloc] Logout error: ${e.toString()}');

      // If token is invalid or user already logged out, still clear local data
      // This is not an error - the user is already logged out on the server
      if (e.toString().contains('Invalid token') ||
          e.toString().contains('already logged out') ||
          e.toString().contains('401')) {

        // Clear FCM token even on error
        await FCMService().clearToken();

        // Security: Clear all secure data
        await SecureStorage.clearAll();

        // Clear token and user_id from cache and global variables
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = '';
        userId = '';

        // Clear saved route
        await RoutePersistenceService.clearSavedRoute();

        // 🔔 Clear notification cache
        await NotificationCacheService().clearAllNotifications();

        print('[LoginBloc] 🔒 Token was invalid/expired - Cleared all secure data');
        emit(LogoutSuccess('Logged out successfully'));
      } else {
        // For other errors, still try to clear everything but show error
        await FCMService().clearToken();

        // Security: Clear all secure data
        await SecureStorage.clearAll();

        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = '';
        userId = '';

        // Clear saved route
        await RoutePersistenceService.clearSavedRoute();

        // 🔔 Clear notification cache
        await NotificationCacheService().clearAllNotifications();

        emit(LogoutError(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}
