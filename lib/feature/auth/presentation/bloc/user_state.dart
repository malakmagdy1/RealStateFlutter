import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class UserState extends Equatable {
  UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  UserInitial();
}

class UserLoading extends UserState {
  UserLoading();
}

class UserSuccess extends UserState {
  final UserModel user;

  UserSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;

  UserError(this.message);

  @override
  List<Object?> get props => [message];
}
