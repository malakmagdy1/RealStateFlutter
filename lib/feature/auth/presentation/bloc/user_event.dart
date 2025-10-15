import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserEvent extends UserEvent {
  const FetchUserEvent();
}

class RefreshUserEvent extends UserEvent {
  const RefreshUserEvent();
}
