class ForgotPasswordStep1Request {
  final String email;

  ForgotPasswordStep1Request({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
