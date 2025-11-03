import 'package:equatable/equatable.dart';

class ForgotPasswordStep1Response extends Equatable {
  final bool success;
  final String message;
  final String? email;
  final int? expiresInMinutes;

  const ForgotPasswordStep1Response({
    required this.success,
    required this.message,
    this.email,
    this.expiresInMinutes,
  });

  factory ForgotPasswordStep1Response.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordStep1Response(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      email: json['data']?['email']?.toString(),
      expiresInMinutes: json['data']?['expires_in_minutes'],
    );
  }

  @override
  List<Object?> get props => [success, message, email, expiresInMinutes];

  @override
  String toString() {
    return 'ForgotPasswordStep1Response{success: $success, message: $message, email: $email, expiresInMinutes: $expiresInMinutes}';
  }
}
