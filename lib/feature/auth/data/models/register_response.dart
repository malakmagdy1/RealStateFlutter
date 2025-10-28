import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/user_model.dart';

class RegisterResponse extends Equatable {
  final String message;
  final String? token;
  final UserModel? user;
  final bool emailSent;
  final String? verificationUrl;
  final int? expiresInMinutes;

  RegisterResponse({
    required this.message,
    this.token,
    this.user,
    this.emailSent = false,
    this.verificationUrl,
    this.expiresInMinutes,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested 'data' object structure
    final data = json['data'] as Map<String, dynamic>?;

    // Parse user from data.user
    UserModel? user;
    if (data != null && data['user'] != null) {
      user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }

    // Parse verification info
    final verification = data?['verification'] as Map<String, dynamic>?;

    return RegisterResponse(
      message: json['message'] ?? '',
      token: data?['token']?.toString(),
      user: user,
      emailSent: verification?['email_sent'] ?? false,
      verificationUrl: data?['verification_url']?.toString(),
      expiresInMinutes: verification?['expires_in_minutes'] as int?,
    );
  }

  @override
  List<Object?> get props => [message, token, user, emailSent, verificationUrl, expiresInMinutes];

  @override
  String toString() {
    return 'RegisterResponse{message: $message, token: $token, user: $user, emailSent: $emailSent}';
  }
}
