import 'package:equatable/equatable.dart';
import '../../data/models/register_response.dart';

abstract class RegisterState extends Equatable {
  RegisterState();

  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {
  RegisterInitial();
}

class RegisterLoading extends RegisterState {
  RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  final RegisterResponse response;

  RegisterSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class RegisterError extends RegisterState {
  final String message;

  RegisterError(this.message);

  @override
  List<Object?> get props => [message];
}
