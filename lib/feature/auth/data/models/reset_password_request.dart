class ResetPasswordRequest {
  final String email;
  final String resetToken;
  final String password;
  final String passwordConfirmation;

  ResetPasswordRequest({
    required this.email,
    required this.resetToken,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}
