import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/core/utils/constant.dart';
import 'package:real/core/network/auth_interceptor.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/forgot_password_request.dart';
import '../models/forgot_password_response.dart';
import '../models/forgot_password_step1_request.dart';
import '../models/forgot_password_step1_response.dart';
import '../models/verify_reset_code_request.dart';
import '../models/verify_reset_code_response.dart';
import '../models/reset_password_request.dart';
import '../models/reset_password_response.dart';
import '../models/update_name_request.dart';
import '../models/update_name_response.dart';
import '../models/update_phone_request.dart';
import '../models/update_phone_response.dart';
import '../models/user_model.dart';
import '../models/verify_email_request.dart';
import '../models/verify_email_response.dart';
import '../models/resend_verification_request.dart';
import '../models/resend_verification_response.dart';

class AuthWebServices {
  late Dio dio;

  // IMPORTANT: For physical devices, replace this with your computer's IP address
  // Find your IP: Windows (ipconfig), Mac/Linux (ifconfig)
  // Example: '192.168.1.100' or '192.168.0.105'
  // Use 'localhost' for emulators (auto-uses 10.0.2.2 for Android emulator)
  static String physicalDeviceIP = 'localhost';

  // API Authentication Token (optional for register/login, required for authenticated endpoints)
  static String bearerToken = 'NDQ6MTc2MDE2NjAyNA==';

  // Automatically detect the correct base URL based on platform
  static String get baseUrl {
    String apiPath = '/api';

    if (kIsWeb) {
      // Web (Chrome, Firefox, etc.) - use 127.0.0.1:8001
      return 'https://aqar.bdcbiz.com$apiPath';
    } else if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 to access host machine's localhost
      // For physical Android device, use your computer's IP
      if (physicalDeviceIP != 'localhost') {
        return 'http://$physicalDeviceIP:8001$apiPath';
      }
      return 'https://aqar.bdcbiz.com$apiPath';
    } else if (Platform.isIOS) {
      // iOS Simulator can use localhost
      // For physical iOS device, use your computer's IP
      if (physicalDeviceIP != 'localhost') {
        return 'http://$physicalDeviceIP:8001$apiPath';
      }
      return 'https://aqar.bdcbiz.com$apiPath';
    } else {
      // Desktop (Windows, macOS, Linux) - use 127.0.0.1:8001
      return 'https://aqar.bdcbiz.com$apiPath';
    }
  }

  AuthWebServices() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: Duration(seconds: 60),
      receiveTimeout: Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Uncomment if your register/login endpoints require auth
        // 'Authorization': 'Bearer $bearerToken',
      },
    );

    dio = Dio(options);

    // Add auth interceptor to handle token expiration (401 errors)
    dio.interceptors.add(AuthInterceptor(dio));

    // Add interceptor for logging
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      Response response = await dio.post('/register', data: request.toJson());
      print('Register Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return RegisterResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Register DioException: ${e.toString()}');
      // Handle registration-specific errors
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
        if (errorData['errors'] != null) {
          // Handle validation errors
          final errors = errorData['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values
              .map((e) => e is List ? e.join(', ') : e.toString())
              .join('\n');
          throw Exception(errorMessages);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('Register Error: ${e.toString()}');
      throw Exception('Registration failed: $e');
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      Response response = await dio.post('/login', data: request.toJson());
      print('Login Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Login DioException: ${e.toString()}');
      // Handle login-specific errors
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('Login Error: ${e.toString()}');
      throw Exception('Login failed: $e');
    }
  }

  Future<LoginResponse> googleLogin({
    required String googleId,
    required String email,
    required String name,
    String? photoUrl,
    required String idToken,
  }) async {
    try {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('Google Login - Sending to backend:');
      print('Google ID: $googleId');
      print('Email: $email');
      print('Name: $name');
      print('ID Token length: ${idToken.length}');

      // Use /login endpoint with login_method: google
      Response response = await dio.post('/login', data: {
        'email': email,
        'password': googleId, // Use Google ID as password for Google sign-in
        'login_method': 'google',
        'google_id': googleId,
        'name': name,
        'photo_url': photoUrl,
        'id_token': idToken, // Send ID token for backend verification
      });

      print('Google Login Response: ${response.data.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.data is Map<String, dynamic>) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('Google Login DioException: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('Google Login Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      throw Exception('Google login failed: $e');
    }
  }

  Future<LoginResponse> appleLogin({
    required String appleId,
    required String email,
    required String name,
    required String identityToken,
    required String authorizationCode,
  }) async {
    try {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('Apple Login - Sending to backend:');
      print('Apple ID: $appleId');
      print('Email: $email');
      print('Name: $name');
      print('Identity Token length: ${identityToken.length}');

      // Use /login endpoint with login_method: apple
      Response response = await dio.post('/login', data: {
        'email': email,
        'password': appleId, // Use Apple ID as password for Apple sign-in
        'login_method': 'apple',
        'apple_id': appleId,
        'name': name,
        'identity_token': identityToken,
        'authorization_code': authorizationCode,
      });

      print('Apple Login Response: ${response.data.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.data is Map<String, dynamic>) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('Apple Login DioException: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('Apple Login Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      throw Exception('Apple login failed: $e');
    }
  }

  Future<VerifyEmailResponse> verifyEmailCode(VerifyEmailRequest request) async {
    try {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Verifying email with code');
      print('[API] Email: ${request.email}');
      print('[API] Code: ${request.code}');

      Response response = await dio.post('/verify-email', data: request.toJson());

      print('[API] Verify Email Response Status: ${response.statusCode}');
      print('[API] Verify Email Response: ${response.data.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.data is Map<String, dynamic>) {
        return VerifyEmailResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Verify Email DioException: ${e.toString()}');
      print('[API] Status Code: ${e.response?.statusCode}');
      print('[API] Response Data: ${e.response?.data}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      // Handle verification-specific errors
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;

        // Return error response for handling in UI
        return VerifyEmailResponse.fromJson(errorData);
      }
      throw _handleError(e);
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Verify Email Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      throw Exception('Email verification failed: $e');
    }
  }

  Future<ResendVerificationResponse> resendVerificationCode(
      ResendVerificationRequest request) async {
    try {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Resending verification code');
      print('[API] Email: ${request.email}');

      Response response = await dio.post(
        '/resend-verification-code',
        data: request.toJson(),
      );

      print('[API] Resend Code Response Status: ${response.statusCode}');
      print('[API] Resend Code Response: ${response.data.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.data is Map<String, dynamic>) {
        return ResendVerificationResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Resend Code DioException: ${e.toString()}');
      print('[API] Status Code: ${e.response?.statusCode}');
      print('[API] Response Data: ${e.response?.data}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Resend Code Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      throw Exception('Resend verification code failed: $e');
    }
  }

  // ============================================================
  // FORGOT PASSWORD - 3 STEP FLOW
  // ============================================================

  // Step 1: Request Password Reset (Send 6-digit code to email)
  Future<ForgotPasswordStep1Response> requestPasswordReset(ForgotPasswordStep1Request request) async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📧 Step 1: Requesting password reset for ${request.email}');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/forgot-password',
        data: request.toJson(),
      );
      print('✅ Password reset code sent successfully');
      print('Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.data is Map<String, dynamic>) {
        return ForgotPasswordStep1Response.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Request Password Reset DioException: ${e.toString()}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Request Password Reset Error: ${e.toString()}');
      throw Exception('Failed to request password reset: $e');
    }
  }

  // Step 2: Verify 6-Digit Reset Code
  Future<VerifyResetCodeResponse> verifyResetCode(VerifyResetCodeRequest request) async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🔐 Step 2: Verifying reset code for ${request.email}');
      print('Code: ${request.code}');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/verify-reset-code',
        data: request.toJson(),
      );
      print('✅ Reset code verified successfully');
      print('Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.data is Map<String, dynamic>) {
        return VerifyResetCodeResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Verify Reset Code DioException: ${e.toString()}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Verify Reset Code Error: ${e.toString()}');
      throw Exception('Failed to verify reset code: $e');
    }
  }

  // Step 3: Reset Password with Token
  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🔑 Step 3: Resetting password for ${request.email}');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/reset-password',
        data: request.toJson(),
      );
      print('✅ Password reset successfully');
      print('Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.data is Map<String, dynamic>) {
        return ResetPasswordResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Reset Password DioException: ${e.toString()}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Reset Password Error: ${e.toString()}');
      throw Exception('Failed to reset password: $e');
    }
  }

  // Old forgot password method (kept for backward compatibility)
  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      Response response = await dio.post(
        '/forgot-password.php',
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      print('Forgot Password Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return ForgotPasswordResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Forgot Password DioException: ${e.toString()}');
      // Handle forgot password-specific errors
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('Forgot Password Error: ${e.toString()}');
      throw Exception('Forgot password failed: $e');
    }
  }

  Future<UpdateNameResponse> updateName(UpdateNameRequest request) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('📝 Updating user name');
      print('New name: ${request.name}');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.put(
        '/profile/name',
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Update Name Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return UpdateNameResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Update Name DioException: ${e.toString()}');
      print('❌ Response: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Update Name Error: ${e.toString()}');
      throw Exception('Update name failed: $e');
    }
  }

  Future<UpdatePhoneResponse> updatePhone(UpdatePhoneRequest request) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('📱 Updating user phone');
      print('New phone: ${request.phone}');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.put(
        '/profile/phone',
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Update Phone Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return UpdatePhoneResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Update Phone DioException: ${e.toString()}');
      print('❌ Response: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Update Phone Error: ${e.toString()}');
      throw Exception('Update phone failed: $e');
    }
  }

  Future<UserModel> getUserByToken() async {
    try {
      // Get token and user_id from storage
      final authToken = token ?? '';
      final userId = CasheNetwork.getCasheData(key: "user_id");

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Fetching user with token: $authToken');
      print('[API] Token length: ${authToken.length}');
      print('[API] User ID: $userId');
      print('[API] Using /profile endpoint');

      // Use /profile endpoint with Bearer token and user_id
      Response response = await dio.get(
        '/profile',
        queryParameters: {
          if (userId.isNotEmpty) 'user_id': userId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[API] Get User Response Status: ${response.statusCode}');
      print('[API] Get User Response: ${response.data.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.data is Map<String, dynamic>) {
        // Handle nested 'data' object structure
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return UserModel.fromJson(data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Get User DioException: ${e.toString()}');
      print('[API] Status Code: ${e.response?.statusCode}');
      print('[API] Response Data: ${e.response?.data}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Get User Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Logging out with token: $authToken');
      print('[API] Sending POST to /logout');

      Response response = await dio.post(
        '/logout',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[API] Logout Response Status: ${response.statusCode}');
      print('[API] Logout Response: ${response.data.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'status': true, 'message': 'Logged out successfully'};
      }
    } on DioException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Logout DioException: ${e.toString()}');
      print('[API] Status Code: ${e.response?.statusCode}');
      print('[API] Response Data: ${e.response?.data}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Logout Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      throw Exception('Logout failed: $e');
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(String filePath, {List<int>? fileBytes}) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Uploading profile image');
      print('[API] File path: $filePath');
      print('[API] Has bytes: ${fileBytes != null}');
      print('[API] Bytes length: ${fileBytes?.length ?? 0}');
      print('[API] Token: $authToken');

      // Create FormData
      FormData formData;

      if (fileBytes != null) {
        // For web platform - use bytes with proper content type
        // Determine content type based on file extension or default to jpeg
        String contentType = 'image/jpeg';
        String filename = 'profile_image.jpg';

        if (filePath.toLowerCase().contains('.png')) {
          contentType = 'image/png';
          filename = 'profile_image.png';
        } else if (filePath.toLowerCase().contains('.gif')) {
          contentType = 'image/gif';
          filename = 'profile_image.gif';
        } else if (filePath.toLowerCase().contains('.webp')) {
          contentType = 'image/webp';
          filename = 'profile_image.webp';
        }

        print('[API] Using content type: $contentType');
        print('[API] Using filename: $filename');

        formData = FormData.fromMap({
          'image': MultipartFile.fromBytes(
            fileBytes,
            filename: filename,
            contentType: DioMediaType.parse(contentType),
          ),
        });
      } else {
        // For mobile platforms - use file path
        formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            filePath,
            filename: 'profile_image.jpg',
          ),
        });
      }

      Response response = await dio.post(
        '/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
            // Don't set Content-Type manually - Dio will set it with proper boundary
          },
        ),
      );

      print('[API] Upload Image Response Status: ${response.statusCode}');
      print('[API] Upload Image Response: ${response.data.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'Profile image uploaded successfully'};
      }
    } on DioException catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Upload Image DioException: ${e.toString()}');
      print('[API] Status Code: ${e.response?.statusCode}');
      print('[API] Response Data: ${e.response?.data}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');

      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      print('[API] Upload Image Error: ${e.toString()}');
      print('\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 404) {
          return 'API endpoint not found. Please check the URL.';
        }
        if (error.response?.statusCode == 422) {
          // Validation errors
          final errorData = error.response?.data;
          if (errorData is Map && errorData['message'] != null) {
            return errorData['message'];
          }
          return 'Validation error. Please check your input.';
        }
        return 'Server error: ${error.response?.statusCode}';

      case DioExceptionType.connectionError:
        return 'Connection error. Make sure the server is running and accessible.';

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      default:
        return 'An unexpected error occurred: ${error.message}';
    }
  }

  // ============================================================================
  // DEVICE MANAGEMENT METHODS
  // ============================================================================

  /// Login with device information
  Future<LoginResponse> loginWithDevice(LoginRequest request, Map<String, String> deviceInfo) async {
    try {
      // Merge login data with device info
      final Map<String, dynamic> loginData = {
        ...request.toJson(),
        ...deviceInfo,
      };

      print('═══════════════════════════════════════════════════════');
      print('🔐 Login with Device Info');
      print('Email: ${request.email}');
      print('Device ID: ${deviceInfo['device_id']}');
      print('Device Name: ${deviceInfo['device_name']}');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post('/login', data: loginData);
      print('✅ Login successful');
      print('Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return LoginResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Login DioException: ${e.toString()}');

      // Check for device limit error (status code 403 or 429)
      if (e.response?.statusCode == 403 || e.response?.statusCode == 429) {
        final errorData = e.response?.data as Map<String, dynamic>?;

        // Check if this is a device limit error
        if (errorData != null &&
            (errorData['message']?.toString().contains('Device limit') == true ||
             errorData['message']?.toString().contains('maximum number of devices') == true)) {

          print('🚫 Device limit reached - parsing devices from response');

          // Parse devices from response data
          List<Map<String, dynamic>> devicesList = [];
          if (errorData['data'] != null && errorData['data']['devices'] != null) {
            devicesList = List<Map<String, dynamic>>.from(errorData['data']['devices']);
          } else if (errorData['devices'] != null) {
            devicesList = List<Map<String, dynamic>>.from(errorData['devices']);
          }

          print('Found ${devicesList.length} devices in error response');

          // Throw special exception with devices data
          throw DeviceLimitException(
            message: errorData['message'] ?? 'Device limit exceeded',
            devices: devicesList,
          );
        }
      }

      // Handle other login errors
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      if (e is DeviceLimitException) rethrow;
      print('❌ Login Error: ${e.toString()}');
      throw Exception('Login failed: $e');
    }
  }

  /// Get list of user's registered devices
  Future<List<Map<String, dynamic>>> getUserDevices() async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('📱 Fetching User Devices');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.get(
        '/devices',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ User Devices Response: ${response.data.toString()}');

      // Handle response structure: {success: true, data: {devices: [...], device_limit: 5, ...}}
      if (response.data is Map<String, dynamic> &&
          response.data['success'] == true &&
          response.data['data'] != null &&
          response.data['data']['devices'] != null) {
        final devices = List<Map<String, dynamic>>.from(response.data['data']['devices']);
        print('📊 Found ${devices.length} devices');
        print('═══════════════════════════════════════════════════════');
        return devices;
      }

      print('⚠️ No devices found in response');
      print('═══════════════════════════════════════════════════════');
      return [];
    } on DioException catch (e) {
      print('❌ Get Devices DioException: ${e.toString()}');
      print('❌ Response: ${e.response?.data}');
      print('═══════════════════════════════════════════════════════');
      throw _handleError(e);
    } catch (e) {
      print('❌ Get Devices Error: ${e.toString()}');
      print('═══════════════════════════════════════════════════════');
      throw Exception('Failed to get devices: $e');
    }
  }

  /// Remove a specific device by device_id (requires authentication)
  Future<void> removeDevice(String deviceId) async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('🗑️  Removing Device: $deviceId');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.delete(
        '/devices/$deviceId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Device removed successfully');
      print('✅ Response: ${response.data.toString()}');
      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        final remainingSlots = response.data['data']['remaining_slots'];
        print('✅ Remaining slots: $remainingSlots');
      }
      print('═══════════════════════════════════════════════════════');
    } on DioException catch (e) {
      print('❌ Remove Device DioException: ${e.toString()}');
      print('❌ Response: ${e.response?.data}');
      print('═══════════════════════════════════════════════════════');
      throw _handleError(e);
    } catch (e) {
      print('❌ Remove Device Error: ${e.toString()}');
      print('═══════════════════════════════════════════════════════');
      throw Exception('Failed to remove device: $e');
    }
  }

  /// Delete user account
  Future<Map<String, dynamic>> deleteAccount({String? reason}) async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('🗑️ Requesting Account Deletion');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.delete(
        '/delete-account',
        data: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Account deletion request submitted');
      print('Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'Account deletion request submitted'};
      }
    } on DioException catch (e) {
      print('❌ Delete Account DioException: ${e.toString()}');
      print('❌ Response: ${e.response?.data}');
      print('═══════════════════════════════════════════════════════');

      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Delete Account Error: ${e.toString()}');
      print('═══════════════════════════════════════════════════════');
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Get subscription tier information
  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('💎 Fetching Subscription Info');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.get(
        '/devices',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Subscription Info Response: ${response.data.toString()}');

      // Parse subscription info from the devices response
      // Response structure: {success: true, data: {devices: [...], device_limit: 5, devices_used: 5, remaining_slots: 0, subscription_type: "plus"}}
      if (response.data is Map<String, dynamic> &&
          response.data['success'] == true &&
          response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;

        final subscriptionInfo = {
          'tier_name': data['subscription_type'] ?? 'Free',
          'max_devices': data['device_limit'] ?? 3,
          'current_devices': data['devices_used'] ?? 0,
          'remaining_slots': data['remaining_slots'] ?? 0,
        };

        print('📊 Subscription: ${subscriptionInfo['tier_name']}');
        print('📊 Devices: ${subscriptionInfo['current_devices']}/${subscriptionInfo['max_devices']}');
        print('📊 Remaining: ${subscriptionInfo['remaining_slots']}');
        print('═══════════════════════════════════════════════════════');

        return subscriptionInfo;
      }

      print('⚠️ Using default subscription info');
      print('═══════════════════════════════════════════════════════');
      return {
        'tier_name': 'Free',
        'max_devices': 3,
        'current_devices': 0,
        'remaining_slots': 3,
      };
    } on DioException catch (e) {
      print('❌ Get Subscription DioException: ${e.toString()}');
      print('❌ Response: ${e.response?.data}');
      print('═══════════════════════════════════════════════════════');
      throw _handleError(e);
    } catch (e) {
      print('❌ Get Subscription Error: ${e.toString()}');
      print('═══════════════════════════════════════════════════════');
      throw Exception('Failed to get subscription info: $e');
    }
  }

  // ============================================================================
  // FCM & NOTIFICATION METHODS
  // ============================================================================

  /// Store FCM token for push notifications
  Future<Map<String, dynamic>> storeFcmToken({
    required String fcmToken,
    String? locale,
  }) async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('📱 Storing FCM Token');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/fcm-token',
        data: {
          'fcm_token': fcmToken,
          if (locale != null) 'locale': locale,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ FCM Token stored successfully');
      print('Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'FCM token stored'};
      }
    } on DioException catch (e) {
      print('❌ Store FCM Token DioException: ${e.toString()}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Store FCM Token Error: ${e.toString()}');
      throw Exception('Failed to store FCM token: $e');
    }
  }

  /// Remove FCM token
  Future<Map<String, dynamic>> removeFcmToken() async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('🗑️ Removing FCM Token');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.delete(
        '/fcm-token',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ FCM Token removed successfully');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'FCM token removed'};
      }
    } on DioException catch (e) {
      print('❌ Remove FCM Token DioException: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Remove FCM Token Error: ${e.toString()}');
      throw Exception('Failed to remove FCM token: $e');
    }
  }

  /// Update user locale for notifications
  Future<Map<String, dynamic>> updateLocale(String locale) async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('🌐 Updating Locale to: $locale');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/update-locale',
        data: {'locale': locale},
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Locale updated successfully');
      print('Response: ${response.data.toString()}');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'Locale updated'};
      }
    } on DioException catch (e) {
      print('❌ Update Locale DioException: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Update Locale Error: ${e.toString()}');
      throw Exception('Failed to update locale: $e');
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('🔐 Changing Password');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/change-password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Password changed successfully');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'Password changed successfully'};
      }
    } on DioException catch (e) {
      print('❌ Change Password DioException: ${e.toString()}');
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data as Map<String, dynamic>;
        if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ Change Password Error: ${e.toString()}');
      throw Exception('Failed to change password: $e');
    }
  }

  /// Mark tutorial as seen
  Future<Map<String, dynamic>> markTutorialSeen() async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('📖 Marking Tutorial as Seen');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/tutorial/mark-seen',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Tutorial marked as seen');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'tutorial_seen': true};
      }
    } on DioException catch (e) {
      print('❌ Mark Tutorial Seen DioException: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Mark Tutorial Seen Error: ${e.toString()}');
      throw Exception('Failed to mark tutorial as seen: $e');
    }
  }

  /// Check device status
  Future<Map<String, dynamic>> checkDevice(String deviceId) async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('📱 Checking Device: $deviceId');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/devices/check',
        data: {'device_id': deviceId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Device check response: ${response.data}');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true};
      }
    } on DioException catch (e) {
      print('❌ Check Device DioException: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Check Device Error: ${e.toString()}');
      throw Exception('Failed to check device: $e');
    }
  }

  /// Remote logout a specific device
  Future<Map<String, dynamic>> remoteLogout(String deviceId) async {
    try {
      final authToken = token ?? '';

      print('═══════════════════════════════════════════════════════');
      print('🚪 Remote Logout Device: $deviceId');
      print('═══════════════════════════════════════════════════════');

      Response response = await dio.post(
        '/devices/remote-logout',
        data: {'device_id': deviceId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('✅ Device logged out remotely');
      print('═══════════════════════════════════════════════════════');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'Device logged out'};
      }
    } on DioException catch (e) {
      print('❌ Remote Logout DioException: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Remote Logout Error: ${e.toString()}');
      throw Exception('Failed to remote logout: $e');
    }
  }
}

/// Custom exception for device limit errors
class DeviceLimitException implements Exception {
  final String message;
  final List<Map<String, dynamic>> devices;

  DeviceLimitException({
    required this.message,
    required this.devices,
  });

  @override
  String toString() => message;
}
