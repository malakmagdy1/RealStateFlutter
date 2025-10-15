import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import 'package:real/core/utils/constant.dart';
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

      // IMPORTANT: Update global token variable
      token = response.token ?? '';
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[LoginBloc] Token saved to cache AND global variable');
      print('[LoginBloc] Token: $token');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

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
      final response = await _repository.logout();

      // Clear token from cache and global variable
      await CasheNetwork.deletecasheItem(key: "token");
      token = '';

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[LoginBloc] Logout successful - Token cleared');
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

        // Clear token from cache and global variable
        await CasheNetwork.deletecasheItem(key: "token");
        token = '';

        print('[LoginBloc] Token was invalid/expired - Cleared local token');
        emit(const LogoutSuccess('Logged out successfully'));
      } else {
        // For other errors, still try to clear token but show error
        await CasheNetwork.deletecasheItem(key: "token");
        token = '';
        emit(LogoutError(e.toString().replaceAll('Exception: ', '')));
      }
    }
  }
}
