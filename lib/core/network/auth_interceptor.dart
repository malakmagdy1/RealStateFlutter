import 'package:dio/dio.dart';
import 'package:real/core/network/token_manager.dart';
import 'package:real/core/utils/constant.dart';
import 'package:real/feature/auth/data/network/local_netwrok.dart';

/// Interceptor to handle authentication errors (401)
/// When a 401 error is detected, it clears the token and forces re-login
class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if the error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      print('[AuthInterceptor] 401 Unauthorized - Token expired or invalid');

      // Clear the token and userId from cache and global variables
      await CasheNetwork.deletecasheItem(key: "token");
      await CasheNetwork.deletecasheItem(key: "user_id");
      token = '';
      userId = '';

      print(
        '[AuthInterceptor] Token and User ID cleared - Notifying app to redirect to login',
      );

      // Notify the app about token expiration
      TokenManager().notifyTokenExpired();
    }

    // Pass the error to the next handler
    super.onError(err, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add the current token to every request
    if (token != null && token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('[AuthInterceptor] Added token to request: ${options.uri}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[AuthInterceptor] Response received: ${response.statusCode}');
    super.onResponse(response, handler);
  }
}
