import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:real/feature/auth/data/models/user_model.dart';
import 'package:real/feature/auth/data/models/register_request.dart';
import 'package:real/feature/auth/data/models/register_response.dart';
import 'package:real/feature/auth/data/models/login_request.dart';
import 'package:real/feature/auth/data/models/login_response.dart';
import 'package:real/feature/auth/data/models/forgot_password_request.dart';
import 'package:real/feature/auth/data/models/forgot_password_response.dart';
import 'package:real/feature/auth/data/models/update_name_request.dart';
import 'package:real/feature/auth/data/models/update_name_response.dart';
import 'package:real/feature/auth/data/models/update_phone_request.dart';
import 'package:real/feature/auth/data/models/update_phone_response.dart';

class AuthRepository {
  final AuthWebServices _authWebServices;

  AuthRepository({AuthWebServices? authWebServices})
      : _authWebServices = authWebServices ?? AuthWebServices();

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _authWebServices.register(request);
      return response;
    } catch (e) {
      print('Repository Register Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _authWebServices.login(request);
      return response;
    } catch (e) {
      print('Repository Login Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<LoginResponse> googleLogin({
    required String googleId,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    try {
      final response = await _authWebServices.googleLogin(
        googleId: googleId,
        email: email,
        name: name,
        photoUrl: photoUrl,
      );
      return response;
    } catch (e) {
      print('Repository Google Login Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await _authWebServices.verifyEmail(token);
      return response;
    } catch (e) {
      print('Repository Verify Email Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _authWebServices.forgotPassword(request);
      return response;
    } catch (e) {
      print('Repository Forgot Password Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<UpdateNameResponse> updateName(UpdateNameRequest request) async {
    try {
      final response = await _authWebServices.updateName(request);
      return response;
    } catch (e) {
      print('Repository Update Name Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<UpdatePhoneResponse> updatePhone(UpdatePhoneRequest request) async {
    try {
      final response = await _authWebServices.updatePhone(request);
      return response;
    } catch (e) {
      print('Repository Update Phone Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<UserModel> getUserByToken() async {
    try {
      final response = await _authWebServices.getUserByToken();
      return response;
    } catch (e) {
      print('Repository Get User Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _authWebServices.logout();
      return response;
    } catch (e) {
      print('Repository Logout Error: ${e.toString()}');
      rethrow;
    }
  }
}
