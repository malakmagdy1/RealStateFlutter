import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/services/fcm_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _repository;

  LoginBloc({required AuthRepository repository})
      : _repository = repository,
        super(const LoginInitial()) {
    on<LoginSubmitEvent>(_onLoginSubmit);
    on<LogoutEvent>(_onLogout);
  }

  // Expose repository for Google sign-in
  AuthRepository get repository => _repository;

  Future<void> _onLoginSubmit(
    LoginSubmitEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());
    try {
      final response = await _repository.login(event.request);
      await CasheNetwork.insertToCashe(key: "token", value:response.token??'');

      // Save user ID for profile API
      if (response.user.id != null) {
        await CasheNetwork.insertToCashe(
          key: "user_id",
          value: response.user.id.toString()
        );
      }

      // IMPORTANT: Update global token variable
      token = response.token ?? '';
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[LoginBloc] Token saved to cache AND global variable');
      print('[LoginBloc] Token: $token');
      print('[LoginBloc] User ID: ${response.user.id}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // ⭐ SEND FCM TOKEN TO BACKEND AFTER SUCCESSFUL LOGIN
      final fcmToken = FCMService().fcmToken;
      if (fcmToken != null) {
        print('[LoginBloc] 📤 Sending FCM token to backend...');
        await FCMService().sendTokenToBackend(fcmToken);
      } else {
        print('[LoginBloc] ⚠️ FCM token not available');
      }

      emit(LoginSuccess(response));
    } catch (e) {
      emit(LoginError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LogoutLoading());
    try {
      // ⭐ CLEAR FCM TOKEN FROM BACKEND BEFORE LOGOUT
      print('[LoginBloc] 🗑️ Clearing FCM token from backend...');
      await FCMService().clearToken();

      final response = await _repository.logout();

      // Clear token and user_id from cache and global variable
      await CasheNetwork.deletecasheItem(key: "token");
      await CasheNetwork.deletecasheItem(key: "user_id");
      token = '';

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[LoginBloc] Logout successful - Token, User ID, and FCM token cleared');
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

        // Clear token and user_id from cache and global variable
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = '';

        print('[LoginBloc] Token was invalid/expired - Cleared local token, user ID, and FCM token');
        emit(const LogoutSuccess('Logged out successfully'));
      } else {
        // For other errors, still try to clear everything but show error
        await FCMService().clearToken();
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = '';
        emit(LogoutError(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}
