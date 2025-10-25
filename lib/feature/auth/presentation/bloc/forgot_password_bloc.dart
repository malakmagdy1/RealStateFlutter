import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository _repository;

  ForgotPasswordBloc({required AuthRepository repository})
      : _repository = repository,
        super(ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitEvent>(_onForgotPasswordSubmit);
  }

  Future<void> _onForgotPasswordSubmit(
    ForgotPasswordSubmitEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading());
    try {
      final response = await _repository.forgotPassword(event.request);
      emit(ForgotPasswordSuccess(response));
    } catch (e) {
      emit(ForgotPasswordError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
