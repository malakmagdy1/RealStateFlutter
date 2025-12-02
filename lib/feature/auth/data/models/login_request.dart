class LoginRequest {
  final String email;
  final String password;
  final String loginMethod;

  LoginRequest({
    required this.email,
    required this.password,
    this.loginMethod = 'manual',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'login_method': loginMethod,
    };
  }
}
