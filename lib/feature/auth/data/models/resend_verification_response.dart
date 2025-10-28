import 'package:equatable/equatable.dart';

class ResendVerificationResponse extends Equatable {
  final bool success;
  final String message;
  final String messageAr;
  final bool emailSent;
  final int? expiresInMinutes;

  const ResendVerificationResponse({
    required this.success,
    required this.message,
    required this.messageAr,
    this.emailSent = false,
    this.expiresInMinutes,
  });

  factory ResendVerificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return ResendVerificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messageAr: json['message_ar'] ?? '',
      emailSent: data?['email_sent'] ?? false,
      expiresInMinutes: data?['expires_in_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'message_ar': messageAr,
      'data': {
        'email_sent': emailSent,
        if (expiresInMinutes != null) 'expires_in_minutes': expiresInMinutes,
      },
    };
  }

  @override
  List<Object?> get props =>
      [success, message, messageAr, emailSent, expiresInMinutes];

  @override
  String toString() {
    return 'ResendVerificationResponse{success: $success, message: $message, emailSent: $emailSent}';
  }
}
