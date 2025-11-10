import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:real/core/utils/constant.dart';
import '../models/share_model.dart';

class ShareService {
  // Automatically detect the correct base URL based on platform
  static String get baseUrl {
    String apiPath = '/api';

    if (kIsWeb) {
      return 'https://aqar.bdcbiz.com$apiPath';
    } else if (Platform.isAndroid) {
      return 'https://aqar.bdcbiz.com$apiPath';
    } else if (Platform.isIOS) {
      return 'https://aqar.bdcbiz.com$apiPath';
    } else {
      return 'https://aqar.bdcbiz.com$apiPath';
    }
  }

  /// Get share link for a unit, compound, or company
  ///
  /// Parameters:
  /// - [type]: 'unit', 'compound', or 'company'
  /// - [id]: ID of the unit, compound, or company
  /// - [compoundIds]: List of compound IDs to include (for companies)
  /// - [unitIds]: List of unit IDs to include (for compounds/companies)
  /// - [hiddenFields]: List of field names to hide
  Future<ShareResponse> getShareLink({
    required String type,
    required String id,
    List<String>? compoundIds,
    List<String>? unitIds,
    List<String>? hiddenFields,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {
        'type': type,
        'id': id,
      };

      // Add compound IDs if provided (for company shares)
      if (compoundIds != null && compoundIds.isNotEmpty) {
        queryParams['compounds'] = compoundIds.join(',');
      }

      // Add unit IDs if provided
      if (unitIds != null && unitIds.isNotEmpty) {
        queryParams['units'] = unitIds.join(',');
      }

      // Add hidden fields if provided
      if (hiddenFields != null && hiddenFields.isNotEmpty) {
        queryParams['hide'] = hiddenFields.join(',');
      }

      final uri = Uri.parse('$baseUrl/share-link').replace(
        queryParameters: queryParams,
      );

      print('[SHARE] Fetching: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('[SHARE] Status code: ${response.statusCode}');
      print('[SHARE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ShareResponse.fromJson(jsonData);
      } else {
        print('[SHARE] Error: ${response.body}');
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to get share link';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[SHARE] Exception: $e');
      throw Exception('Failed to get share link: $e');
    }
  }
}
