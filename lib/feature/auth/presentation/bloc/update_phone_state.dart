import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/update_phone_response.dart';

abstract class UpdatePhoneState extends Equatable {
  UpdatePhoneState();

  @override
  List<Object?> get props => [];
}

class UpdatePhoneInitial extends UpdatePhoneState {
  UpdatePhoneInitial();
}

class UpdatePhoneLoading extends UpdatePhoneState {
  UpdatePhoneLoading();
}

class UpdatePhoneSuccess extends UpdatePhoneState {
  final UpdatePhoneResponse response;

  UpdatePhoneSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UpdatePhoneError extends UpdatePhoneState {
  final String message;

  UpdatePhoneError(this.message);

  @override
  List<Object?> get props => [message];
}
