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

      Response response = await dio.post(
        '/update-name.php',
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      print('Update Name Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return UpdateNameResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Update Name DioException: ${e.toString()}');
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
      print('Update Name Error: ${e.toString()}');
      throw Exception('Update name failed: $e');
    }
  }

  Future<UpdatePhoneResponse> updatePhone(UpdatePhoneRequest request) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      Response response = await dio.post(
        '/update-phone.php',
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      print('Update Phone Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return UpdatePhoneResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Update Phone DioException: ${e.toString()}');
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
      print('Update Phone Error: ${e.toString()}');
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
}
