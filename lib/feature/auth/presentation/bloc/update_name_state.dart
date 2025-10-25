import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/update_name_response.dart';

abstract class UpdateNameState extends Equatable {
  UpdateNameState();

  @override
  List<Object?> get props => [];
}

class UpdateNameInitial extends UpdateNameState {
  UpdateNameInitial();
}

class UpdateNameLoading extends UpdateNameState {
  UpdateNameLoading();
}

class UpdateNameSuccess extends UpdateNameState {
  final UpdateNameResponse response;

  UpdateNameSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class UpdateNameError extends UpdateNameState {
  final String message;

  UpdateNameError(this.message);

  @override
  List<Object?> get props => [message];
}
