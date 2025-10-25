import 'package:equatable/equatable.dart';

class Sales extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? image;
  final String isVerified;
  final String createdAt;

  Sales({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.image,
    required this.isVerified,
    required this.createdAt,
  });

  factory Sales.fromJson(Map<String, dynamic> json) {
    return Sales(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      image: json['image']?.toString(),
      isVerified: json['is_verified']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'image': image,
      'is_verified': isVerified,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        image,
        isVerified,
        createdAt,
      ];

  @override
  String toString() {
    return 'Sales{id: $id, name: $name, phone: $phone}';
  }
}
