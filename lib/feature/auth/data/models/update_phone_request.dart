class UpdatePhoneRequest {
  final String phone;

  UpdatePhoneRequest({
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}
