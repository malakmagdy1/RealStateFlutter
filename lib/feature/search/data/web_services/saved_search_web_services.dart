import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/saved_search_model.dart';

class SavedSearchWebServices {
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

  /// Get all saved searches for the current user
  Future<SavedSearchResponse> getAllSavedSearches({required String token}) async {
    try {
      final uri = Uri.parse('$baseUrl/saved-searches');

      print('[SAVED SEARCH] Getting all saved searches');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('[SAVED SEARCH] Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[SAVED SEARCH] Found ${jsonData['data']?.length ?? 0} saved searches');

        return SavedSearchResponse.fromJson(jsonData);
      } else {
        print('[SAVED SEARCH] Error: ${response.body}');
        throw Exception('Failed to get saved searches: ${response.statusCode}');
      }
    } catch (e) {
      print('[SAVED SEARCH] Exception: $e');
      throw Exception('Get saved searches failed: $e');
    }
  }

  /// Get a specific saved search by ID
  Future<SavedSearchResponse> getSavedSearchById({
    required String id,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/saved-searches/$id');

      print('[SAVED SEARCH] Getting saved search with ID: $id');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('[SAVED SEARCH] Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[SAVED SEARCH] Retrieved saved search: ${jsonData['data']['name']}');

        return SavedSearchResponse.fromJson(jsonData);
      } else {
        print('[SAVED SEARCH] Error: ${response.body}');
        throw Exception('Failed to get saved search: ${response.statusCode}');
      }
    } catch (e) {
      print('[SAVED SEARCH] Exception: $e');
      throw Exception('Get saved search failed: $e');
    }
  }

  /// Create a new saved search
  Future<SavedSearchResponse> createSavedSearch({
    required CreateSavedSearchRequest request,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/saved-searches');

      print('[SAVED SEARCH] Creating new saved search: ${request.name}');
      print('[SAVED SEARCH] Body: ${json.encode(request.toJson())}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('[SAVED SEARCH] Status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('[SAVED SEARCH] Saved search created successfully');

        return SavedSearchResponse.fromJson(jsonData);
      } else {
        print('[SAVED SEARCH] Error: ${response.body}');
        throw Exception('Failed to create saved search: ${response.statusCode}');
      }
    } catch (e) {
      print('[SAVED SEARCH] Exception: $e');
      throw Exception('Create saved search failed: $e');
    }
  }

  /// Update an existing saved search
  Future<SavedSearchResponse> updateSavedSearch({
    required String id,
    required UpdateSavedSearchRequest request,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/saved-searches/$id');

      print('[SAVED SEARCH] Updating saved search ID: $id');
      print('[SAVED SEARCH] Body: ${json.encode(request.toJson())}');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('[SAVED SEARCH] Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[SAVED SEARCH] Saved search updated successfully');

        return SavedSearchResponse.fromJson(jsonData);
      } else {
        print('[SAVED SEARCH] Error: ${response.body}');
        throw Exception('Failed to update saved search: ${response.statusCode}');
      }
    } catch (e) {
      print('[SAVED SEARCH] Exception: $e');
      throw Exception('Update saved search failed: $e');
    }
  }

  /// Delete a saved search
  Future<SavedSearchResponse> deleteSavedSearch({
    required String id,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/saved-searches/$id');

      print('[SAVED SEARCH] Deleting saved search ID: $id');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('[SAVED SEARCH] Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[SAVED SEARCH] Saved search deleted successfully');

        return SavedSearchResponse.fromJson(jsonData);
      } else {
        print('[SAVED SEARCH] Error: ${response.body}');
        throw Exception('Failed to delete saved search: ${response.statusCode}');
      }
    } catch (e) {
      print('[SAVED SEARCH] Exception: $e');
      throw Exception('Delete saved search failed: $e');
    }
  }
}
