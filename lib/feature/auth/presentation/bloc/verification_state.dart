import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/verify_email_response.dart';
import 'package:real/feature/auth/data/models/resend_verification_response.dart';

abstract class VerificationState extends Equatable {
  const VerificationState();

  @override
  List<Object?> get props => [];
}

class VerificationInitial extends VerificationState {}

class VerificationLoading extends VerificationState {}

class VerificationSuccess extends VerificationState {
  final VerifyEmailResponse response;

  const VerificationSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class VerificationError extends VerificationState {
  final String message;
  final int? remainingAttempts;

  const VerificationError(this.message, {this.remainingAttempts});

  @override
  List<Object?> get props => [message, remainingAttempts];
}

class ResendCodeLoading extends VerificationState {}

class ResendCodeSuccess extends VerificationState {
  final ResendVerificationResponse response;

  const ResendCodeSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class ResendCodeError extends VerificationState {
  final String message;

  const ResendCodeError(this.message);

  @override
  List<Object?> get props => [message];
}
