import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/core/utils/constant.dart';

class SaleWebServices {
  late Dio dio;

  // IMPORTANT: For physical devices, replace this with your computer's IP address
  static const String physicalDeviceIP = 'localhost';

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

  SaleWebServices() {
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
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<Map<String, dynamic>> getSales({
    int page = 1,
    int limit = 20,
    String? saleType,
    String? companyId,
    String? compoundId,
    String? unitId,
    bool activeOnly = true,
  }) async {
    try {
      // Get token from storage
      final authToken = token ?? '';

      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        'active_only': activeOnly.toString(),
      };

      // Add optional parameters
      if (saleType != null && saleType.isNotEmpty) {
        queryParams['sale_type'] = saleType;
      }
      if (companyId != null && companyId.isNotEmpty) {
        queryParams['company_id'] = companyId;
      }
      if (compoundId != null && compoundId.isNotEmpty) {
        queryParams['compound_id'] = compoundId;
      }
      if (unitId != null && unitId.isNotEmpty) {
        queryParams['unit_id'] = unitId;
      }

      print('[SALE API] Fetching sales - Query params: $queryParams');
      print('[SALE API] URL: $baseUrl/sales');

      final response = await dio.get(
        '/sales',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[SALE API] Status Code: ${response.statusCode}');
      print('[SALE API] Response: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load sales: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('[SALE API] DioException: ${e.toString()}');
      print('[SALE API] Response: ${e.response?.data}');
      throw Exception('Failed to fetch sales: ${e.message}');
    } catch (e) {
      print('[SALE API] Error: $e');
      throw Exception('Failed to fetch sales: $e');
    }
  }

  /// Get sales for a specific company
  Future<Map<String, dynamic>> getSalesByCompany(String companyId, {int page = 1, int limit = 20}) async {
    return getSales(companyId: companyId, page: page, limit: limit);
  }

  /// Get sales for a specific compound
  Future<Map<String, dynamic>> getSalesByCompound(String compoundId, {int page = 1, int limit = 20}) async {
    return getSales(compoundId: compoundId, page: page, limit: limit);
  }

  /// Get sales for a specific unit
  Future<Map<String, dynamic>> getSalesByUnit(String unitId, {int page = 1, int limit = 20}) async {
    return getSales(unitId: unitId, page: page, limit: limit);
  }
}
