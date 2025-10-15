import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/update_phone_response.dart';

abstract class UpdatePhoneState extends Equatable {
  const UpdatePhoneState();

  @override
  List<Object?> get props => [];
}

class UpdatePhoneInitial extends UpdatePhoneState {
  const UpdatePhoneInitial();
}

class UpdatePhoneLoading extends UpdatePhoneState {
  const UpdatePhoneLoading();
}

class UpdatePhoneSuccess extends UpdatePhoneState {
  final UpdatePhoneResponse response;

  const UpdatePhoneSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UpdatePhoneError extends UpdatePhoneState {
  final String message;

  const UpdatePhoneError(this.message);

  @override
  List<Object?> get props => [message];
}
