import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/utils/constant.dart';
import '../models/compound_response.dart';

class CompoundWebServices {
  late Dio dio;

  // IMPORTANT: For physical devices, replace this with your computer's IP address
  static const String physicalDeviceIP = 'localhost';

  // API Authentication Token
  static const String bearerToken = 'NDQ6MTc2MDE2NjAyNA==';

  // Automatically detect the correct base URL based on platform
  static String get baseUrl {
    const String apiPath = '/api';

    if (kIsWeb) {
      // Web (Chrome, Firefox, etc.) - use 127.0.0.1:8001
      return 'http://127.0.0.1:8001$apiPath';
    } else if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 to access host machine's localhost
      // For physical Android device, use your computer's IP
      if (physicalDeviceIP != 'localhost') {
        return 'http://$physicalDeviceIP:8001$apiPath';
      }
      return 'http://10.0.2.2:8001$apiPath';
    } else if (Platform.isIOS) {
      // iOS Simulator can use localhost
      // For physical iOS device, use your computer's IP
      if (physicalDeviceIP != 'localhost') {
        return 'http://$physicalDeviceIP:8001$apiPath';
      }
      return 'http://127.0.0.1:8001$apiPath';
    } else {
      // Desktop (Windows, macOS, Linux) - use 127.0.0.1:8001
      return 'http://127.0.0.1:8001$apiPath';
    }
  }

  CompoundWebServices() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Token will be added per request from storage
      },
    );

    dio = Dio(options);

    // Add interceptor for logging
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<CompoundResponse> getCompounds({int page = 1, int limit = 20}) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      Response response = await dio.get(
        '/compounds',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      print('Get Compounds Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return CompoundResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Get Compounds DioException: ${e.toString()}');
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
      print('Get Compounds Error: ${e.toString()}');
      throw Exception('Failed to fetch compounds: $e');
    }
  }

  Future<CompoundResponse> getCompoundsByCompany({
    required String companyId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      Response response = await dio.get(
        '/compounds',
        queryParameters: {
          'company_id': companyId,
          'page': page,
          'limit': limit,
        },
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );
      print('Get Compounds by Company Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return CompoundResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Get Compounds by Company DioException: ${e.toString()}');
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
      print('Get Compounds by Company Error: ${e.toString()}');
      throw Exception('Failed to fetch compounds by company: $e');
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
