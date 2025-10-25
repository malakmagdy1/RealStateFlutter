import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  UserEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserEvent extends UserEvent {
  FetchUserEvent();
}

class RefreshUserEvent extends UserEvent {
  RefreshUserEvent();
}
