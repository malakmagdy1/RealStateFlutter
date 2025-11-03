import 'package:equatable/equatable.dart';
import 'user_model.dart';

class ResetPasswordResponse extends Equatable {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;

  const ResetPasswordResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      user: json['data']?['user'] != null
          ? UserModel.fromJson(json['data']['user'])
          : null,
      token: json['data']?['token']?.toString(),
    );
  }

  @override
  List<Object?> get props => [success, message, user, token];

  @override
  String toString() {
    return 'ResetPasswordResponse{success: $success, message: $message, user: $user, token: $token}';
  }
}
