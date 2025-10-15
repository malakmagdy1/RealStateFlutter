import 'package:equatable/equatable.dart';
import '../../data/models/forgot_password_request.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordSubmitEvent extends ForgotPasswordEvent {
  final ForgotPasswordRequest request;

  const ForgotPasswordSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}
