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
      final response = await _repository.login(event.request);
      await CasheNetwork.insertToCashe(key: "token", value:response.token??'');

      // Save user ID for profile API
      if (response.user.id != null) {
        await CasheNetwork.insertToCashe(
          key: "user_id",
          value: response.user.id.toString()
        );
      }

      // IMPORTANT: Update global token and userId variables
      token = response.token ?? '';
      userId = response.user.id?.toString() ?? '';
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[LoginBloc] Token and User ID saved to cache AND global variables');
      print('[LoginBloc] Token: $token');
      print('[LoginBloc] User ID: ${response.user.id}');
      print('[LoginBloc] Global userId: $userId');
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
    emit(LogoutLoading());
    try {
      // ⭐ CLEAR FCM TOKEN FROM BACKEND BEFORE LOGOUT
      print('[LoginBloc] 🗑️ Clearing FCM token from backend...');
      await FCMService().clearToken();

      final response = await _repository.logout();

      // Clear token and user_id from cache and global variables
      await CasheNetwork.deletecasheItem(key: "token");
      await CasheNetwork.deletecasheItem(key: "user_id");
      token = '';
      userId = '';

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

        // Clear token and user_id from cache and global variables
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = '';
        userId = '';

        print('[LoginBloc] Token was invalid/expired - Cleared local token, user ID, and FCM token');
        emit(LogoutSuccess('Logged out successfully'));
      } else {
        // For other errors, still try to clear everything but show error
        await FCMService().clearToken();
        await CasheNetwork.deletecasheItem(key: "token");
        await CasheNetwork.deletecasheItem(key: "user_id");
        token = '';
        userId = '';
        emit(LogoutError(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}
