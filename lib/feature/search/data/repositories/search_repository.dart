import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/filter_units_response.dart';
import '../models/search_filter_model.dart';
import '../models/search_result_model.dart';
import 'package:real/core/utils/constant.dart' as constants;
import 'package:real/core/locale/language_service.dart';

class SearchRepository {
  // IMPORTANT: For physical devices, replace this with your computer's IP address
  static String physicalDeviceIP = 'localhost';

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

  /// Unified search and filter API - combines search and filter functionality
  ///
  /// Parameters:
  /// - [query]: The search term (optional)
  /// - [filter]: Filter parameters
  /// - [page]: Page number (default: 1)
  /// - [limit]: Items per page (default: 20)
  Future<FilterUnitsResponse> searchAndFilter({
    String? query,
    SearchFilter? filter,
    String? token,
    int page = 1,
    int limit = 1000,
  }) async {
    try {
      // Use provided token parameter, or fall back to global token
      final authToken = token ?? constants.token ?? '';
      final currentLang = LanguageService.currentLanguage;

      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'lang': currentLang,
        'page': page,
        'limit': limit,
      };

      // Add search query if provided
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }

      // Add filter parameters if provided
      if (filter != null) {
        final filterParams = filter.toQueryParameters();
        queryParams.addAll(filterParams);
      }

      // Build URL with query parameters (convert to string)
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      final uri = Uri.parse(
        '$baseUrl/search-and-filter',
      ).replace(queryParameters: stringParams);

      print('===========================================');
      print('[UNIFIED API] Endpoint: GET /api/search-and-filter');
      print('[UNIFIED API] Full URL: $uri');
      print('[UNIFIED API] Search Query: ${query ?? "none"}');
      print('[UNIFIED API] Language: $currentLang');
      print('[UNIFIED API] Pagination: Page $page, Limit $limit per page');
      if (filter != null) {
        print('[UNIFIED API] Filter Details:');
        print('[UNIFIED API]   - Location: ${filter.location}');
        print('[UNIFIED API]   - Property Type: ${filter.propertyType}');
        print('[UNIFIED API]   - Min Price: ${filter.minPrice}');
        print('[UNIFIED API]   - Max Price: ${filter.maxPrice}');
        print('[UNIFIED API]   - Bedrooms: ${filter.bedrooms}');
        print('[UNIFIED API]   - Min Area: ${filter.minArea}');
        print('[UNIFIED API]   - Max Area: ${filter.maxArea}');
        print('[UNIFIED API]   - Active Filters: ${filter.activeFiltersCount}');
      }
      print('[UNIFIED API] All Query Parameters: $queryParams');
      print('===========================================');

      // Make API request
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('[UNIFIED API] Status code: ${response.statusCode}');
      final bodyPreview = response.body.length > 1000
          ? '${response.body.substring(0, 1000)}... [truncated]'
          : response.body;
      print('[UNIFIED API] Response body: $bodyPreview');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[UNIFIED API] Response data parsed successfully');
        print(
          '[UNIFIED API] Units found: ${jsonData['units']?.length ?? 0}',
        );

        return FilterUnitsResponse.fromJson(jsonData);
      } else {
        print('[UNIFIED API] Error: ${response.body}');
        try {
          final errorData = json.decode(response.body);

          // Check for subscription requirement
          if (errorData['subscription_required'] == true) {
            print('[UNIFIED API] Subscription required error detected');
          }

          // Use localized error message based on current language
          final errorMessage = currentLang == 'en'
              ? (errorData['message_en'] ?? errorData['message'] ?? 'Failed to search and filter: ${response.statusCode}')
              : (errorData['message'] ?? errorData['message_en'] ?? 'Failed to search and filter: ${response.statusCode}');

          print('[UNIFIED API] Error message to display: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && e.toString().contains('Exception:')) {
            rethrow; // Re-throw our custom exception
          }
          throw Exception('Failed to search and filter: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[UNIFIED API] Exception: $e');
      throw Exception('Search and filter failed: $e');
    }
  }

  /// Search for companies, compounds, and units (DEPRECATED - use searchAndFilter instead)
  ///
  /// Parameters:
  /// - [query]: The search term
  /// - [type]: Optional filter - 'company', 'compound', or 'unit'
  /// - [perPage]: Number of results per page (default: 20)
  /// - [filter]: Optional filter parameters
  @deprecated
  Future<SearchResponse> search({
    required String query,
    String? type,
    int perPage = 1000,
    SearchFilter? filter,
  }) async {
    try {
      // Get current language
      final currentLang = LanguageService.currentLanguage;

      // Build query parameters
      final Map<String, String> queryParams = {
        'search': query,
        'lang': currentLang,
      };

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      if (perPage > 0) {
        queryParams['per_page'] = perPage.toString();
      }

      // Add filter parameters if provided
      if (filter != null) {
        final filterParams = filter.toQueryParameters();
        queryParams.addAll(
          filterParams.map((key, value) => MapEntry(key, value.toString())),
        );
      }

      // Build URL with query parameters
      final uri = Uri.parse(
        '$baseUrl/search',
      ).replace(queryParameters: queryParams);

      print('===========================================');
      print('[SEARCH API] Endpoint: GET /api/search');
      print('[SEARCH API] Full URL: $uri');
      print('[SEARCH API] Query: "$query"');
      print('[SEARCH API] Type: $type');
      print('[SEARCH API] Per Page: $perPage');
      print('[SEARCH API] Language: $currentLang');
      print('[SEARCH API] Has Filter: ${filter != null}');
      if (filter != null) {
        print('[SEARCH API] Filter Details:');
        print('[SEARCH API]   - Location: ${filter.location}');
        print('[SEARCH API]   - Property Type: ${filter.propertyType}');
        print('[SEARCH API]   - Min Price: ${filter.minPrice}');
        print('[SEARCH API]   - Max Price: ${filter.maxPrice}');
        print('[SEARCH API]   - Bedrooms: ${filter.bedrooms}');
        print('[SEARCH API]   - Min Area: ${filter.minArea}');
        print('[SEARCH API]   - Max Area: ${filter.maxArea}');
        print('[SEARCH API]   - Active Filters Count: ${filter.activeFiltersCount}');
        print('[SEARCH API] Query Parameters: $queryParams');
      }
      print('===========================================');

      // Make API request
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (constants.token != null && constants.token!.isNotEmpty)
                'Authorization': 'Bearer ${constants.token}',
            },
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('[SEARCH] Status code: ${response.statusCode}');
      // Only log first 1000 chars to avoid console overflow
      final bodyPreview = response.body.length > 1000
          ? '${response.body.substring(0, 1000)}... [truncated ${response.body.length} total chars]'
          : response.body;
      print('[SEARCH] Response body: $bodyPreview');

      if (response.statusCode == 200) {
        try {
          // Sanitize response body by removing control characters
          // but preserve valid whitespace (space, tab, newline, carriage return)
          final sanitizedBody = response.body.replaceAllMapped(
            RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'),
            (match) => '', // Remove invalid control characters
          );

          final jsonData = json.decode(sanitizedBody);
          print('[SEARCH] Response parsed successfully');
          print(
            '[SEARCH] Total results: ${jsonData['total_results'] ?? jsonData['total']}',
          );

          return SearchResponse.fromJson(jsonData);
        } catch (e) {
          print('[SEARCH] JSON parsing error: $e');
          print('[SEARCH] Response length: ${response.body.length} characters');

          // Find the error location in the response
          if (e is FormatException && e.offset != null) {
            final errorOffset = e.offset!;
            final start = errorOffset > 50 ? errorOffset - 50 : 0;
            final end = errorOffset + 50 < response.body.length
                ? errorOffset + 50
                : response.body.length;
            final snippet = response.body.substring(start, end);
            print('[SEARCH] Error near position $errorOffset: "$snippet"');
          }

          throw Exception('Backend returned invalid JSON. Please check Laravel backend logs. Error: $e');
        }
      } else {
        print('[SEARCH] Error: ${response.body}');
        try {
          final errorData = json.decode(response.body);

          // Check for subscription requirement
          if (errorData['subscription_required'] == true) {
            print('[SEARCH] Subscription required error detected');
          }

          // Use localized error message based on current language
          final errorMessage = currentLang == 'en'
              ? (errorData['message_en'] ?? errorData['message'] ?? 'Failed to search: ${response.statusCode}')
              : (errorData['message'] ?? errorData['message_en'] ?? 'Failed to search: ${response.statusCode}');

          print('[SEARCH] Error message to display: $errorMessage');
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && e.toString().contains('Exception:')) {
            rethrow; // Re-throw our custom exception
          }
          throw Exception('Failed to search: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[SEARCH] Exception: $e');
      rethrow;
    }
  }

  /// Get all companies
  Future<SearchResponse> getAllCompanies({int perPage = 1000}) async {
    return search(query: '', type: 'company', perPage: perPage);
  }

  /// Get all compounds
  Future<SearchResponse> getAllCompounds({int perPage = 1000}) async {
    return search(query: '', type: 'compound', perPage: perPage);
  }

  /// Get all units
  Future<SearchResponse> getAllUnits({int perPage = 1000}) async {
    return search(query: '', type: 'unit', perPage: perPage);
  }

  /// Search only companies
  Future<SearchResponse> searchCompanies({
    required String query,
    int perPage = 1000,
  }) async {
    return search(query: query, type: 'company', perPage: perPage);
  }

  /// Search only compounds
  Future<SearchResponse> searchCompounds({
    required String query,
    int perPage = 1000,
  }) async {
    return search(query: query, type: 'compound', perPage: perPage);
  }

  /// Search only units
  Future<SearchResponse> searchUnits({
    required String query,
    int perPage = 1000,
  }) async {
    return search(query: query, type: 'unit', perPage: perPage);
  }

  /// Filter units using unified search-and-filter API (replaces old filter-units endpoint)
  Future<FilterUnitsResponse> filterUnits(
    SearchFilter filter, {
    String? token,
    int page = 1,
    int limit = 1000,
  }) async {
    // Use the new unified API
    return searchAndFilter(
      filter: filter,
      token: token,
      page: page,
      limit: limit,
    );
  }

  /// Filter units using unified search-and-filter API (replaces old filter-units POST endpoint)
  Future<FilterUnitsResponse> filterUnitsAdvanced(
    SearchFilter filter, {
    String? token,
  }) async {
    // Use the new unified API
    return searchAndFilter(
      filter: filter,
      token: token,
    );
  }
}
