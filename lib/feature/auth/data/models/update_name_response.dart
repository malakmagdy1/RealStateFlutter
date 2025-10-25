import 'package:equatable/equatable.dart';

class UpdateNameResponse extends Equatable {
  final String message;
  final bool success;
  final String name;

  UpdateNameResponse({
    required this.message,
    required this.success,
    required this.name,
  });

  factory UpdateNameResponse.fromJson(Map<String, dynamic> json) {
    return UpdateNameResponse(
      message: json['message']?.toString() ?? '',
      success: json['success'] == true || json['success'] == 1,
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [message, success, name];

  @override
  String toString() {
    return 'UpdateNameResponse{message: $message, success: $success, name: $name}';
  }
}
