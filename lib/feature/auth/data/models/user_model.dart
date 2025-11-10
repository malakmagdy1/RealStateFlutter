class UserStats {
  final int savedSearchesCount;
  final int favoritesCount;

  UserStats({this.savedSearchesCount = 0, this.favoritesCount = 0});

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      savedSearchesCount:
          int.tryParse(json['saved_searches_count']?.toString() ?? '0') ?? 0,
      favoritesCount:
          int.tryParse(json['favorites_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saved_searches_count': savedSearchesCount,
      'favorites_count': favoritesCount,
    };
  }
}

class UserModel {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String password;
  final bool isVerified;
  final bool isBanned;
  final String? companyId;
  final UserStats? stats;
  final String? imageUrl;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.password,
    this.isVerified = false,
    this.isBanned = false,
    this.companyId,
    this.stats,
    this.imageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      password: json['password']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      companyId: json['company_id']?.toString(),
      isVerified:
          json['is_verified'] == true ||
          json['is_verified'] == 1 ||
          json['is_verified'] == '1' ||
          json['is_verified'] == 'true',
      isBanned:
          json['is_banned'] == true ||
          json['is_banned'] == 1 ||
          json['is_banned'] == '1' ||
          json['is_banned'] == 'true',
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'password': password,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_verified': isVerified,
      'is_banned': isBanned,
      if (companyId != null) 'company_id': companyId,
      if (stats != null) 'stats': stats!.toJson(),
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  @override
  String toString() {
    return 'UserModel{id: $id, name: $name, email: $email, phone: $phone, role: $role, isVerified: $isVerified, isBanned: $isBanned, companyId: $companyId}';
  }
}
