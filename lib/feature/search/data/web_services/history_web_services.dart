import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/core/utils/constant.dart';
import 'package:real/core/network/auth_interceptor.dart';

class HistoryWebServices {
  late Dio dio;

  static String physicalDeviceIP = 'localhost';

  static String get baseUrl {
    String apiPath = '/api';

    if (kIsWeb) {
      return 'https://aqar.bdcbiz.com$apiPath';
    } else if (Platform.isAndroid) {
      if (physicalDeviceIP != 'localhost') {
        return 'http://$physicalDeviceIP:8001$apiPath';
      }
      return 'https://aqar.bdcbiz.com$apiPath';
    } else if (Platform.isIOS) {
      if (physicalDeviceIP != 'localhost') {
        return 'http://$physicalDeviceIP:8001$apiPath';
      }
      return 'https://aqar.bdcbiz.com$apiPath';
    } else {
      return 'https://aqar.bdcbiz.com$apiPath';
    }
  }

  HistoryWebServices() {
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: Duration(seconds: 60),
      receiveTimeout: Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio = Dio(options);
    dio.interceptors.add(AuthInterceptor(dio));
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  /// Get all history for the authenticated user
  Future<Map<String, dynamic>> getHistory({String? actionType, int? limit}) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[HISTORY API] Getting history with token: ${authToken.substring(0, 20)}...');
      print('[HISTORY API] User ID: $currentUserId');

      Map<String, dynamic> queryParams = {};
      if (currentUserId.isNotEmpty) queryParams['user_id'] = currentUserId;
      if (actionType != null) queryParams['action_type'] = actionType;
      if (limit != null) queryParams['limit'] = limit;

      Response response = await dio.get(
        '/history',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[HISTORY API] Get history response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[HISTORY API] Error getting history: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[HISTORY API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to get history: $e');
    }
  }

  /// Add an entry to history
  /// actionType: 'view_unit', 'search', 'view_compound', 'filter'
  Future<Map<String, dynamic>> addToHistory({
    required String actionType,
    int? unitId,
    int? compoundId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[HISTORY API] Adding history entry: $actionType');
      print('[HISTORY API] User ID: $currentUserId');

      Map<String, dynamic> data = {'action_type': actionType};
      if (currentUserId.isNotEmpty) data['user_id'] = int.parse(currentUserId);
      if (unitId != null) data['unit_id'] = unitId;
      if (compoundId != null) data['compound_id'] = compoundId;
      if (metadata != null) data['metadata'] = metadata;

      Response response = await dio.post(
        '/history',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[HISTORY API] Add to history response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[HISTORY API] Error adding to history: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[HISTORY API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to add to history: $e');
    }
  }

  /// Remove a specific history entry
  Future<Map<String, dynamic>> removeFromHistory(int historyId) async {
    try {
      final authToken = token ?? '';
      print('[HISTORY API] Removing history entry $historyId');

      Response response = await dio.delete(
        '/history/$historyId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[HISTORY API] Remove from history response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[HISTORY API] Error removing from history: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[HISTORY API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to remove from history: $e');
    }
  }

  /// Clear all history
  Future<Map<String, dynamic>> clearAllHistory() async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[HISTORY API] Clearing all history');
      print('[HISTORY API] User ID: $currentUserId');

      Map<String, dynamic> queryParams = {};
      if (currentUserId.isNotEmpty) {
        queryParams['user_id'] = currentUserId;
      }

      Response response = await dio.delete(
        '/history-clear',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[HISTORY API] Clear history response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[HISTORY API] Error clearing history: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[HISTORY API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to clear history: $e');
    }
  }

  /// Get recently viewed units
  Future<Map<String, dynamic>> getRecentlyViewed({int limit = 10}) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';

      Map<String, dynamic> queryParams = {'limit': limit};
      if (currentUserId.isNotEmpty) queryParams['user_id'] = currentUserId;

      Response response = await dio.get(
        '/history/recently-viewed',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[HISTORY API] Error getting recently viewed: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[HISTORY API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to get recently viewed: $e');
    }
  }

  /// Get search history
  Future<Map<String, dynamic>> getSearchHistory({int limit = 10}) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';

      Map<String, dynamic> queryParams = {'limit': limit};
      if (currentUserId.isNotEmpty) queryParams['user_id'] = currentUserId;

      Response response = await dio.get(
        '/history/searches',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[HISTORY API] Error getting search history: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[HISTORY API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to get search history: $e');
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
          return 'History entry not found.';
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
