import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real/feature/auth/data/models/verify_email_request.dart';
import 'package:real/feature/auth/data/models/resend_verification_request.dart';
import 'package:real/feature/auth/data/repositories/auth_repository.dart';
import 'verification_event.dart';
import 'verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final AuthRepository _repository;

  VerificationBloc({required AuthRepository repository})
      : _repository = repository,
        super(VerificationInitial()) {
    on<VerifyEmailEvent>(_onVerifyEmail);
    on<ResendVerificationCodeEvent>(_onResendCode);
  }

  Future<void> _onVerifyEmail(
    VerifyEmailEvent event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final request = VerifyEmailRequest(
        email: event.email,
        code: event.code,
      );

      final response = await _repository.verifyEmailCode(request);

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[VerificationBloc] Verification Response: ${response.toString()}');
      print('[VerificationBloc] Success: ${response.success}');
      print('[VerificationBloc] Message: ${response.message}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.success) {
        emit(VerificationSuccess(response));
      } else {
        // Handle error responses from API
        emit(VerificationError(
          response.message,
          remainingAttempts: response.remainingAttempts,
        ));
      }
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[VerificationBloc] Verification Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      emit(VerificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onResendCode(
    ResendVerificationCodeEvent event,
    Emitter<VerificationState> emit,
  ) async {
    emit(ResendCodeLoading());
    try {
      final request = ResendVerificationRequest(email: event.email);
      final response = await _repository.resendVerificationCode(request);

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[VerificationBloc] Resend Code Response: ${response.toString()}');
      print('[VerificationBloc] Success: ${response.success}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.success) {
        emit(ResendCodeSuccess(response));
      } else {
        emit(ResendCodeError(response.message));
      }
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[VerificationBloc] Resend Code Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      emit(ResendCodeError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
