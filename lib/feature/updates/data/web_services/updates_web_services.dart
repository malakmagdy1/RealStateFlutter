import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UpdatesWebServices {
  late Dio dio;

  static String get baseUrl {
    if (kIsWeb) {
      return 'https://aqar.bdcbiz.com/api';
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'https://aqar.bdcbiz.com/api';
    }
    return 'https://aqar.bdcbiz.com/api';
  }

  UpdatesWebServices() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio = Dio(options);
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));
  }

  /// Get recent updates
  Future<List<Map<String, dynamic>>> getRecentUpdates({
    int hours = 24,
    String type = 'all',
    int limit = 10,
  }) async {
    try {
      print('[UPDATES API] Fetching updates: hours=$hours, type=$type, limit=$limit');

      Response response = await dio.get(
        '/updates/recent',
        queryParameters: {
          'hours': hours,
          'type': type,
          'limit': limit,
        },
      );

      print('[UPDATES API] Response status: ${response.statusCode}');

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final updates = List<Map<String, dynamic>>.from(data['data']);
        print('[UPDATES API] Loaded ${updates.length} updates');
        return updates;
      }
      return [];
    } on DioException catch (e) {
      print('[UPDATES API] DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('[UPDATES API] Response data: ${e.response?.data}');
      }
      return [];
    } catch (e) {
      print('[UPDATES API] Error: $e');
      return [];
    }
  }

  /// Get updates summary
  Future<Map<String, int>> getUpdatesSummary({int hours = 24}) async {
    try {
      Response response = await dio.get(
        '/updates/summary',
        queryParameters: {'hours': hours},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final summary = data['data'] as Map<String, dynamic>;
        return {
          'units': summary['units_count'] as int? ?? 0,
          'compounds': summary['compounds_count'] as int? ?? 0,
          'companies': summary['companies_count'] as int? ?? 0,
          'total': summary['total_count'] as int? ?? 0,
        };
      }
      return {};
    } catch (e) {
      print('[UPDATES API] Error getting summary: $e');
      return {};
    }
  }
}
