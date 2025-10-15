import 'package:equatable/equatable.dart';
import '../../data/models/login_response.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final LoginResponse response;

  const LoginSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class LoginError extends LoginState {
  final String message;

  const LoginError(this.message);

  @override
  List<Object?> get props => [message];
}

class LogoutLoading extends LoginState {
  const LogoutLoading();
}

class LogoutSuccess extends LoginState {
  final String message;

  const LogoutSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LogoutError extends LoginState {
  final String message;

  const LogoutError(this.message);

  @override
  List<Object?> get props => [message];
}
