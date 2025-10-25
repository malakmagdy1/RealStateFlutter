import 'package:equatable/equatable.dart';
import '../../data/models/login_response.dart';

abstract class LoginState extends Equatable {
  LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  LoginInitial();
}

class LoginLoading extends LoginState {
  LoginLoading();
}

class LoginSuccess extends LoginState {
  final LoginResponse response;

  LoginSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class LoginError extends LoginState {
  final String message;

  LoginError(this.message);

  @override
  List<Object?> get props => [message];
}

class LogoutLoading extends LoginState {
  LogoutLoading();
}

class LogoutSuccess extends LoginState {
  final String message;

  LogoutSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LogoutError extends LoginState {
  final String message;

  LogoutError(this.message);

  @override
  List<Object?> get props => [message];
}
