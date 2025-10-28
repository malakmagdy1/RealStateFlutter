import 'package:equatable/equatable.dart';
import 'package:real/feature/auth/data/models/user_model.dart';

class VerifyEmailResponse extends Equatable {
  final bool success;
  final String message;
  final String messageAr;
  final UserModel? user;
  final int? remainingAttempts;

  const VerifyEmailResponse({
    required this.success,
    required this.message,
    required this.messageAr,
    this.user,
    this.remainingAttempts,
  });

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested 'data' object structure
    final data = json['data'] as Map<String, dynamic>?;

    return VerifyEmailResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messageAr: json['message_ar'] ?? '',
      user: data != null && data['user'] != null
          ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
          : null,
      remainingAttempts: data?['remaining_attempts'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'message_ar': messageAr,
      if (user != null) 'data': {'user': user!.toJson()},
      if (remainingAttempts != null)
        'data': {'remaining_attempts': remainingAttempts},
    };
  }

  @override
  List<Object?> get props => [success, message, messageAr, user, remainingAttempts];

  @override
  String toString() {
    return 'VerifyEmailResponse{success: $success, message: $message, user: $user, remainingAttempts: $remainingAttempts}';
  }
}
