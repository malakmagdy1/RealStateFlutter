import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:real/core/utils/constant.dart';
import '../models/share_model.dart';

class ShareService {
  // Automatically detect the correct base URL based on platform
  static String get baseUrl {
    const String apiPath = '/api';

    if (kIsWeb) {
      return 'http://127.0.0.1:8001$apiPath';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8001$apiPath';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:8001$apiPath';
    } else {
      return 'http://127.0.0.1:8001$apiPath';
    }
  }

  /// Get share link for a unit or compound
  ///
  /// Parameters:
  /// - [type]: 'unit' or 'compound'
  /// - [id]: ID of the unit or compound
  Future<ShareResponse> getShareLink({
    required String type,
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/share-link').replace(
        queryParameters: {
          'type': type,
          'id': id,
        },
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
        const Duration(seconds: 30),
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
