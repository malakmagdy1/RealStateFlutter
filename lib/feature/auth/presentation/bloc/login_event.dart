import 'package:equatable/equatable.dart';
import '../../data/models/login_request.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitEvent extends LoginEvent {
  final LoginRequest request;

  const LoginSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class LogoutEvent extends LoginEvent {
  const LogoutEvent();

  @override
  List<Object?> get props => [];
}
