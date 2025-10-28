import 'package:equatable/equatable.dart';

class VerifyEmailRequest extends Equatable {
  final String email;
  final String code;

  const VerifyEmailRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }

  @override
  List<Object?> get props => [email, code];

  @override
  String toString() {
    return 'VerifyEmailRequest{email: $email, code: $code}';
  }
}
