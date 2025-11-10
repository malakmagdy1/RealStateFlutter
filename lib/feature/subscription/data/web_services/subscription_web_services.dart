import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:real/core/utils/constant.dart';
import 'package:real/core/network/auth_interceptor.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_model.dart';
import '../models/subscription_status_model.dart';

class SubscriptionWebServices {
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

  SubscriptionWebServices() {
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

  // Get all subscription plans (no auth required)
  Future<List<SubscriptionPlanModel>> getAllPlans() async {
    try {
      print('========================================');
      print('[API] Fetching all subscription plans');

      Response response = await dio.get('/subscription-plans');

      print('[API] Plans Response Status: ${response.statusCode}');
      print('[API] Plans Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'] as List?;
        if (data != null) {
          return data.map((json) => SubscriptionPlanModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      } else if (response.data is List) {
        return (response.data as List).map((json) => SubscriptionPlanModel.fromJson(json as Map<String, dynamic>)).toList();
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      print('========================================');
      print('[API] Get Plans DioException: $e');
      print('[API] Status Code: ${e.response?.statusCode}');
      print('========================================');
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Get Plans Error: $e');
      print('========================================');
      throw Exception('Failed to fetch plans: $e');
    }
  }

  // Get single subscription plan (no auth required)
  Future<SubscriptionPlanModel> getPlan(int planId) async {
    try {
      print('========================================');
      print('[API] Fetching plan with ID: $planId');

      Response response = await dio.get('/subscription-plans/$planId');

      print('[API] Plan Response Status: ${response.statusCode}');
      print('[API] Plan Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return SubscriptionPlanModel.fromJson(data);
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      print('========================================');
      print('[API] Get Plan DioException: $e');
      print('========================================');
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Get Plan Error: $e');
      print('========================================');
      throw Exception('Failed to fetch plan: $e');
    }
  }

  // Get current active subscription (requires auth)
  Future<SubscriptionModel?> getCurrentSubscription() async {
    try {
      final authToken = token ?? '';

      print('========================================');
      print('[API] Fetching current subscription');
      print('[API] Token: $authToken');

      Response response = await dio.get(
        '/subscription/current',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      print('[API] Current Subscription Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        if (data.isEmpty || data['id'] == null) return null;
        return SubscriptionModel.fromJson(data);
      }

      return null;
    } on DioException catch (e) {
      print('========================================');
      print('[API] Get Current Subscription DioException: $e');
      print('========================================');
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Get Current Subscription Error: $e');
      print('========================================');
      throw Exception('Failed to fetch current subscription: $e');
    }
  }

  // Get subscription status (requires auth)
  Future<SubscriptionStatusModel> getSubscriptionStatus() async {
    try {
      final authToken = token ?? '';

      print('========================================');
      print('[API] Fetching subscription status');

      Response response = await dio.get(
        '/subscription/status',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      print('[API] Status Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return SubscriptionStatusModel.fromJson(data);
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      print('========================================');
      print('[API] Get Status DioException: $e');
      print('========================================');
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Get Status Error: $e');
      print('========================================');
      throw Exception('Failed to fetch status: $e');
    }
  }

  // Subscribe to a plan (requires auth)
  Future<SubscriptionModel> subscribe({
    required int subscriptionPlanId,
    required String billingCycle,
    bool autoRenew = true,
  }) async {
    try {
      final authToken = token ?? '';

      print('========================================');
      print('[API] Subscribing to plan');
      print('[API] Plan ID: $subscriptionPlanId');
      print('[API] Billing: $billingCycle');

      Response response = await dio.post(
        '/subscription/subscribe',
        data: {
          'subscription_plan_id': subscriptionPlanId,
          'billing_cycle': billingCycle,
          'auto_renew': autoRenew,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      print('[API] Subscribe Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return SubscriptionModel.fromJson(data);
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      print('========================================');
      print('[API] Subscribe DioException: $e');
      print('========================================');
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Subscribe Error: $e');
      print('========================================');
      throw Exception('Failed to subscribe: $e');
    }
  }

  // Cancel subscription (requires auth)
  Future<Map<String, dynamic>> cancelSubscription({String? reason}) async {
    try {
      final authToken = token ?? '';

      print('========================================');
      print('[API] Cancelling subscription');
      print('[API] Reason: $reason');

      Response response = await dio.post(
        '/subscription/cancel',
        data: reason != null ? {'reason': reason} : null,
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      print('[API] Cancel Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }

      return {'status': true, 'message': 'Subscription cancelled'};
    } on DioException catch (e) {
      print('========================================');
      print('[API] Cancel DioException: $e');
      print('========================================');
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Cancel Error: $e');
      print('========================================');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  // Get subscription history (requires auth)
  Future<List<SubscriptionModel>> getSubscriptionHistory() async {
    try {
      final authToken = token ?? '';

      print('========================================');
      print('[API] Fetching subscription history');

      Response response = await dio.get(
        '/subscription/history',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      print('[API] History Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'] as List?;
        if (data != null) {
          return data.map((json) => SubscriptionModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      } else if (response.data is List) {
        return (response.data as List).map((json) => SubscriptionModel.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('========================================');
      print('[API] Get History DioException: $e');
      print('========================================');
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Get History Error: $e');
      print('========================================');
      throw Exception('Failed to fetch history: $e');
    }
  }

  // Assign free plan (requires auth)
  Future<SubscriptionModel> assignFreePlan() async {
    try {
      final authToken = token ?? '';

      print('========================================');
      print('[API] Assigning free plan');

      Response response = await dio.post(
        '/subscription/free-plan',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      print('[API] Free Plan Response: ${response.data}');
      print('========================================');

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return SubscriptionModel.fromJson(data);
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      print('========================================');
      print('[API] Assign Free Plan DioException: $e');
      print('========================================');
      throw _handleError(e);
    } catch (e) {
      print('========================================');
      print('[API] Assign Free Plan Error: $e');
      print('========================================');
      throw Exception('Failed to assign free plan: $e');
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final errorData = error.response?.data as Map<String, dynamic>;
      if (errorData['message'] != null) {
        return errorData['message'];
      }
      if (errorData['error'] != null) {
        return errorData['error'];
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
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
