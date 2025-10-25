import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/core/utils/constant.dart';
import 'package:real/core/locale/language_service.dart';
import '../models/company_response.dart';

class CompanyWebServices {
  late Dio dio;

  // IMPORTANT: For physical devices, replace this with your computer's IP address
  static String physicalDeviceIP = 'localhost';

  // API Authentication Token
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

  CompanyWebServices() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: Duration(seconds: 60),
      receiveTimeout: Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Token will be added per request from storage
      },
    );

    dio = Dio(options);

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

  Future<CompanyResponse> getCompanies() async {
    try {
      // Get token from storage
      final authToken = token ?? '';
      final currentLang = LanguageService.currentLanguage;

      Response response = await dio.get(
        '/companies',
        queryParameters: {
          'lang': currentLang,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      print('Get Companies Response: ${response.data.toString()}');

      if (response.data is Map<String, dynamic>) {
        return CompanyResponse.fromJson(response.data);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('Get Companies DioException: ${e.toString()}');
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
      print('Get Companies Error: ${e.toString()}');
      throw Exception('Failed to fetch companies: $e');
    }
  }

  Future<Map<String, dynamic>> getCompanyById(String companyId) async {
    try {
      // Get token from storage
      final authToken = token ?? '';
      final currentLang = LanguageService.currentLanguage;

      print('[COMPANY WEB SERVICES] Fetching company with ID: $companyId');

      Response response = await dio.get(
        '/companies/$companyId',
        queryParameters: {
          'lang': currentLang,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[COMPANY WEB SERVICES] Company Response: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        // Handle case where data is directly in response
        if (response.data['data'] != null) {
          final data = response.data['data'];
          // Handle if data is a List (take first item)
          if (data is List && data.isNotEmpty) {
            return data.first as Map<String, dynamic>;
          }
          // Handle if data is already a Map
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
        return response.data;
      } else if (response.data is List) {
        // Handle case where response is directly a List
        final dataList = response.data as List;
        if (dataList.isNotEmpty) {
          return dataList.first as Map<String, dynamic>;
        }
        throw Exception('No company found with ID: $companyId');
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('[COMPANY WEB SERVICES] Get Company DioException: ${e.toString()}');
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
      print('[COMPANY WEB SERVICES] Get Company Error: ${e.toString()}');
      throw Exception('Failed to fetch company: $e');
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
