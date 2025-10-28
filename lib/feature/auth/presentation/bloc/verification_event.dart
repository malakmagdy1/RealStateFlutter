import 'package:equatable/equatable.dart';

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

class VerifyEmailEvent extends VerificationEvent {
  final String email;
  final String code;

  const VerifyEmailEvent({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class ResendVerificationCodeEvent extends VerificationEvent {
  final String email;

  const ResendVerificationCodeEvent({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}
