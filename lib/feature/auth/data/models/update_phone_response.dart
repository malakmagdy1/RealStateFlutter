import 'package:equatable/equatable.dart';

class UpdatePhoneResponse extends Equatable {
  final String message;
  final bool success;
  final String phone;

  const UpdatePhoneResponse({
    required this.message,
    required this.success,
    required this.phone,
  });

  factory UpdatePhoneResponse.fromJson(Map<String, dynamic> json) {
    return UpdatePhoneResponse(
      message: json['message']?.toString() ?? '',
      success: json['success'] == true || json['success'] == 1,
      phone: json['phone']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [message, success, phone];

  @override
  String toString() {
    return 'UpdatePhoneResponse{message: $message, success: $success, phone: $phone}';
  }
}
