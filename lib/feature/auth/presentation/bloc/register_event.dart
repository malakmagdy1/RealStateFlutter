import 'package:equatable/equatable.dart';

import '../../data/models/register_request.dart';

abstract class RegisterEvent extends Equatable {
  RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterSubmitEvent extends RegisterEvent {
  final RegisterRequest request;

  RegisterSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}
