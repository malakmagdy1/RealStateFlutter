import 'package:equatable/equatable.dart';

import '../../data/models/register_request.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterSubmitEvent extends RegisterEvent {
  final RegisterRequest request;

  const RegisterSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}
