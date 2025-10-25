import 'package:equatable/equatable.dart';

class RegisterResponse extends Equatable {
  final String message;
  final String userId;
  final bool emailSent;
  final String? verificationUrl;

  RegisterResponse({
    required this.message,
    required this.userId,
    required this.emailSent,
    this.verificationUrl,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested 'data' object structure
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return RegisterResponse(
      message: json['message'] ?? '',
      userId: data['user_id']?.toString() ?? '',
      emailSent: data['email_sent'] ?? false,
      verificationUrl: data['verification_url'],
    );
  }

  @override
  List<Object?> get props => [message, userId, emailSent, verificationUrl];

  @override
  String toString() {
    return 'RegisterResponse{message: $message, userId: $userId, emailSent: $emailSent}';
  }
}
