class ForgotPasswordRequest {
  final String? email;
  final String newPassword;

  ForgotPasswordRequest({this.email, required this.newPassword});

  Map<String, dynamic> toJson() {
    final json = {'new_password': newPassword};

    // Only add email if it's provided (for forgot password flow)
    if (email != null && email!.isNotEmpty) {
      json['email'] = email!;
    }

    return json;
  }
}
