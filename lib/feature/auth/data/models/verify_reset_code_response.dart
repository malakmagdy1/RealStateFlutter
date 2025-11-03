import 'package:equatable/equatable.dart';

class VerifyResetCodeResponse extends Equatable {
  final bool success;
  final String message;
  final String? resetToken;
  final String? email;

  const VerifyResetCodeResponse({
    required this.success,
    required this.message,
    this.resetToken,
    this.email,
  });

  factory VerifyResetCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResetCodeResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      resetToken: json['data']?['reset_token']?.toString(),
      email: json['data']?['email']?.toString(),
    );
  }

  @override
  List<Object?> get props => [success, message, resetToken, email];

  @override
  String toString() {
    return 'VerifyResetCodeResponse{success: $success, message: $message, resetToken: $resetToken, email: $email}';
  }
}
