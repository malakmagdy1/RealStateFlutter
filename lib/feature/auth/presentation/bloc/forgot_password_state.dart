import 'package:equatable/equatable.dart';
import '../../data/models/forgot_password_response.dart';

abstract class ForgotPasswordState extends Equatable {
  ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  ForgotPasswordLoading();
}

class ForgotPasswordSuccess extends ForgotPasswordState {
  final ForgotPasswordResponse response;

  ForgotPasswordSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;

  ForgotPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}
