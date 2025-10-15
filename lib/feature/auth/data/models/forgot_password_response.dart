import 'package:equatable/equatable.dart';

class ForgotPasswordResponse extends Equatable {
  final String message;

  const ForgotPasswordResponse({
    required this.message,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: json['message']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [message];

  @override
  String toString() {
    return 'ForgotPasswordResponse{message: $message}';
  }
}
