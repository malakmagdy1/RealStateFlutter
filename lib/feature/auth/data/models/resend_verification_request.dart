import 'package:equatable/equatable.dart';

class ResendVerificationRequest extends Equatable {
  final String email;

  const ResendVerificationRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }

  @override
  List<Object?> get props => [email];

  @override
  String toString() {
    return 'ResendVerificationRequest{email: $email}';
  }
}
