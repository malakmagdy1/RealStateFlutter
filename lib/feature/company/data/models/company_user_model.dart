import 'package:equatable/equatable.dart';

// Company user model for sales people
class CompanyUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;

  CompanyUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory CompanyUser.fromJson(Map<String, dynamic> json) {
    return CompanyUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }

  bool get isSales => role.toLowerCase() == 'sales';
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        phone,
      ];

  @override
  String toString() {
    return 'CompanyUser{id: $id, name: $name, email: $email, role: $role, phone: $phone}';
  }
}
