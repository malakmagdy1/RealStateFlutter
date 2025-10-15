import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/update_phone_request.dart';

abstract class UpdatePhoneEvent extends Equatable {
  const UpdatePhoneEvent();

  @override
  List<Object?> get props => [];
}

class UpdatePhoneSubmitEvent extends UpdatePhoneEvent {
  final UpdatePhoneRequest request;

  const UpdatePhoneSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}
