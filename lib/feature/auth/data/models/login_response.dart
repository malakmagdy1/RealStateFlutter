import 'package:equatable/equatable.dart';
import 'user_model.dart';

class LoginResponse extends Equatable {
  final String message;
  final UserModel user;
  final String? token;

  LoginResponse({
    required this.message,
    required this.user,
    this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested 'data' object structure
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return LoginResponse(
      message: json['message']?.toString() ?? '',
      user: UserModel.fromJson(data['user'] ?? {}),
      token: data['token']?.toString(),
    );
  }

  @override
  List<Object?> get props => [message, user, token];

  @override
  String toString() {
    return 'LoginResponse{message: $message, user: ${user.name}, token: $token}';
  }
}
