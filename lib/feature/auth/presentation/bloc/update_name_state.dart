import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/update_name_response.dart';

abstract class UpdateNameState extends Equatable {
  const UpdateNameState();

  @override
  List<Object?> get props => [];
}

class UpdateNameInitial extends UpdateNameState {
  const UpdateNameInitial();
}

class UpdateNameLoading extends UpdateNameState {
  const UpdateNameLoading();
}

class UpdateNameSuccess extends UpdateNameState {
  final UpdateNameResponse response;

  const UpdateNameSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UpdateNameError extends UpdateNameState {
  final String message;

  const UpdateNameError(this.message);

  @override
  List<Object?> get props => [message];
}
