import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/core/utils/constant.dart';
import 'package:real/core/network/auth_interceptor.dart';

class FavoritesWebServices {
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

  FavoritesWebServices() {
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

  /// Get all favorites for the authenticated user
  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[FAVORITES API] Getting favorites with token: ${authToken.substring(0, 20)}...');
      print('[FAVORITES API] User ID: $currentUserId');

      Map<String, dynamic> queryParams = {};
      if (currentUserId.isNotEmpty) {
        queryParams['user_id'] = currentUserId;
      }

      Response response = await dio.get(
        '/favorites',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[FAVORITES API] Get favorites response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[FAVORITES API] Error getting favorites: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[FAVORITES API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to get favorites: $e');
    }
  }

  /// Add a unit to favorites
  Future<Map<String, dynamic>> addToFavorites(int unitId) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[FAVORITES API] Adding unit $unitId to favorites');
      print('[FAVORITES API] User ID: $currentUserId');

      Map<String, dynamic> requestData = {'unit_id': unitId};
      if (currentUserId.isNotEmpty) {
        requestData['user_id'] = int.parse(currentUserId);
      }

      Response response = await dio.post(
        '/favorites',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[FAVORITES API] Add to favorites response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[FAVORITES API] Error adding to favorites: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[FAVORITES API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Remove a unit from favorites
  Future<Map<String, dynamic>> removeFromFavorites(int unitId) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[FAVORITES API] Removing unit $unitId from favorites');
      print('[FAVORITES API] User ID: $currentUserId');

      Map<String, dynamic> requestData = {'unit_id': unitId};
      if (currentUserId.isNotEmpty) {
        requestData['user_id'] = int.parse(currentUserId);
      }

      Response response = await dio.delete(
        '/favorites',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[FAVORITES API] Remove from favorites response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[FAVORITES API] Error removing from favorites: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[FAVORITES API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Add a compound to favorites
  Future<Map<String, dynamic>> addCompoundToFavorites(int compoundId) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[FAVORITES API] Adding compound $compoundId to favorites');
      print('[FAVORITES API] User ID: $currentUserId');

      Map<String, dynamic> requestData = {'compound_id': compoundId};
      if (currentUserId.isNotEmpty) {
        requestData['user_id'] = int.parse(currentUserId);
      }

      Response response = await dio.post(
        '/favorites',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[FAVORITES API] Add compound to favorites response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[FAVORITES API] Error adding compound to favorites: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[FAVORITES API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to add compound to favorites: $e');
    }
  }

  /// Remove a compound from favorites
  Future<Map<String, dynamic>> removeCompoundFromFavorites(int compoundId) async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[FAVORITES API] Removing compound $compoundId from favorites');
      print('[FAVORITES API] User ID: $currentUserId');

      Map<String, dynamic> requestData = {'compound_id': compoundId};
      if (currentUserId.isNotEmpty) {
        requestData['user_id'] = int.parse(currentUserId);
      }

      Response response = await dio.delete(
        '/favorites',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[FAVORITES API] Remove compound from favorites response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[FAVORITES API] Error removing compound from favorites: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[FAVORITES API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to remove compound from favorites: $e');
    }
  }

  /// Check if a unit is in favorites
  Future<bool> isFavorite(int unitId) async {
    try {
      final authToken = token ?? '';

      Response response = await dio.get(
        '/favorites/check/$unitId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return data['is_favorite'] as bool? ?? false;
    } on DioException catch (e) {
      print('[FAVORITES API] Error checking favorite: ${e.toString()}');
      return false;
    } catch (e) {
      print('[FAVORITES API] Unexpected error: ${e.toString()}');
      return false;
    }
  }

  /// Clear all favorites
  Future<Map<String, dynamic>> clearAllFavorites() async {
    try {
      final authToken = token ?? '';
      final currentUserId = userId ?? '';
      print('[FAVORITES API] Clearing all favorites');
      print('[FAVORITES API] User ID: $currentUserId');

      Map<String, dynamic> queryParams = {};
      if (currentUserId.isNotEmpty) {
        queryParams['user_id'] = currentUserId;
      }

      Response response = await dio.delete(
        '/favorites',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      print('[FAVORITES API] Clear favorites response: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[FAVORITES API] Error clearing favorites: ${e.toString()}');
      throw _handleError(e);
    } catch (e) {
      print('[FAVORITES API] Unexpected error: ${e.toString()}');
      throw Exception('Failed to clear favorites: $e');
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
          return 'Favorite not found.';
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
