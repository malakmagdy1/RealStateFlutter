import 'package:equatable/equatable.dart';
import '../../data/models/forgot_password_request.dart';

abstract class ForgotPasswordEvent extends Equatable {
  ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordSubmitEvent extends ForgotPasswordEvent {
  final ForgotPasswordRequest request;

  ForgotPasswordSubmitEvent(this.request);

  @override
  List<Object?> get props => [request];
}
