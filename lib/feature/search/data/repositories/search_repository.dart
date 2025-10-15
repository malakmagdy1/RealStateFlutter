import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/filter_units_response.dart';
import '../models/search_filter_model.dart';
import '../models/search_result_model.dart';

class SearchRepository {
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
      // Build query parameters
      final Map<String, String> queryParams = {'search': query};

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
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('[SEARCH] Status code: ${response.statusCode}');
      print('[SEARCH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[SEARCH] Response data: $jsonData');
        print(
          '[SEARCH] Total results: ${jsonData['total_results'] ?? jsonData['total']}',
        );

        return SearchResponse.fromJson(jsonData);
      } else {
        print('[SEARCH] Error: ${response.body}');
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to search: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[SEARCH] Exception: $e');
      throw Exception('Search failed: $e');
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
      // Convert filter to query parameters
      final queryParams = filter.toQueryParameters();

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
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
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
      // Convert filter to JSON body
      final body = filter.toJson();

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
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30),
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
