import 'package:equatable/equatable.dart';
import '../../data/models/login_request.dart';

abstract class LoginEvent extends Equatable {
  LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitEvent extends LoginEvent {
  final LoginRequest request;

  LoginSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class LogoutEvent extends LoginEvent {
  LogoutEvent();

  @override
  List<Object?> get props => [];
}
