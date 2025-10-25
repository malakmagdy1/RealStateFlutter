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

  /// Search for companies, compounds, and units
  ///
  /// Parameters:
  /// - [query]: The search term
  /// - [type]: Optional filter - 'company', 'compound', or 'unit'
  /// - [perPage]: Number of results per page (default: 20)
  /// - [filter]: Optional filter parameters
  Future<SearchResponse> search({
    required String query,
    String? type,
    int perPage = 20,
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

      print('[SEARCH] Fetching: $uri');

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
          final errorMessage =
              errorData['message'] ?? 'Failed to search: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to search: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[SEARCH] Exception: $e');
      rethrow;
    }
  }

  /// Get all companies
  Future<SearchResponse> getAllCompanies({int perPage = 50}) async {
    return search(query: '', type: 'company', perPage: perPage);
  }

  /// Get all compounds
  Future<SearchResponse> getAllCompounds({int perPage = 50}) async {
    return search(query: '', type: 'compound', perPage: perPage);
  }

  /// Get all units
  Future<SearchResponse> getAllUnits({int perPage = 50}) async {
    return search(query: '', type: 'unit', perPage: perPage);
  }

  /// Search only companies
  Future<SearchResponse> searchCompanies({
    required String query,
    int perPage = 20,
  }) async {
    return search(query: query, type: 'company', perPage: perPage);
  }

  /// Search only compounds
  Future<SearchResponse> searchCompounds({
    required String query,
    int perPage = 20,
  }) async {
    return search(query: query, type: 'compound', perPage: perPage);
  }

  /// Search only units
  Future<SearchResponse> searchUnits({
    required String query,
    int perPage = 20,
  }) async {
    return search(query: query, type: 'unit', perPage: perPage);
  }

  /// Filter units using dedicated filter API (GET - Basic)
  Future<FilterUnitsResponse> filterUnits(
    SearchFilter filter, {
    String? token,
  }) async {
    try {
      // Use provided token parameter, or fall back to global token
      final authToken = token ?? constants.token ?? '';
      final currentLang = LanguageService.currentLanguage;

      // Convert filter to query parameters
      final queryParams = filter.toQueryParameters();

      // Add language parameter
      queryParams['lang'] = currentLang;

      // Build URL with query parameters (convert to string)
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      final uri = Uri.parse(
        '$baseUrl/filter-units',
      ).replace(queryParameters: stringParams);

      print('[FILTER API GET] Fetching: $uri');
      print('[FILTER API GET] Query params: $queryParams');

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

      print('[FILTER API GET] Status code: ${response.statusCode}');
      print('[FILTER API GET] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[FILTER API GET] Response data: $jsonData');
        print(
          '[FILTER API GET] Units found: ${jsonData['data']?.length ?? jsonData['units']?.length ?? 0}',
        );

        return FilterUnitsResponse.fromJson(jsonData);
      } else {
        print('[FILTER API GET] Error: ${response.body}');
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ??
              'Failed to filter units: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to filter units: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[FILTER API GET] Exception: $e');
      throw Exception('Filter failed: $e');
    }
  }

  /// Filter units using dedicated filter API (POST - Advanced)
  Future<FilterUnitsResponse> filterUnitsAdvanced(
    SearchFilter filter, {
    String? token,
  }) async {
    try {
      // Use provided token parameter, or fall back to global token
      final authToken = token ?? constants.token ?? '';
      final currentLang = LanguageService.currentLanguage;

      // Convert filter to JSON body
      final body = filter.toJson();

      // Add language parameter to body
      body['lang'] = currentLang;

      final uri = Uri.parse('$baseUrl/filter-units');

      print('[FILTER API POST] Posting to: $uri');
      print('[FILTER API POST] Body: $body');

      // Make API request
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
            },
            body: json.encode(body),
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('[FILTER API POST] Status code: ${response.statusCode}');
      print('[FILTER API POST] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[FILTER API POST] Response data: $jsonData');
        print(
          '[FILTER API POST] Units found: ${jsonData['data']?.length ?? jsonData['units']?.length ?? 0}',
        );

        return FilterUnitsResponse.fromJson(jsonData);
      } else {
        print('[FILTER API POST] Error: ${response.body}');
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ??
              'Failed to filter units: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to filter units: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[FILTER API POST] Exception: $e');
      throw Exception('Filter failed: $e');
    }
  }
}
