import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// AI API Service - Calls backend API (no Gemini key in Flutter)
class AIApiService {
  static const String _baseUrl = 'https://aqar.bdcbiz.com/api';
  static const Duration _timeout = Duration(seconds: 60);

  String? _token;
  String _language = 'ar';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Initialize the service
  Future<void> initialize({String? token, String? language}) async {
    _token = token;
    _language = language ?? 'ar';
    print('[AIApiService] Initialized with language: $_language');
  }

  /// Set auth token
  void setAuthToken(String token) {
    _token = token;
  }

  /// Set language
  void setLanguage(String language) {
    _language = language;
  }

  /// Chat with AI
  /// POST /api/ai/chat
  Future<Map<String, dynamic>> chat({
    required String message,
    String? conversationId,
    String? language,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/chat'),
            headers: _headers,
            body: jsonEncode({
              'message': message,
              'conversation_id': conversationId,
              'language': language ?? _language,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Chat failed');
      }
    } catch (e) {
      print('[AIApiService] Chat error: $e');
      rethrow;
    }
  }

  /// Get property recommendations
  /// POST /api/ai/recommendations
  Future<Map<String, dynamic>> getRecommendations({
    Map<String, dynamic>? preferences,
    int limit = 10,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/recommendations'),
            headers: _headers,
            body: jsonEncode({
              'preferences': preferences ?? {},
              'limit': limit,
              'language': _language,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Recommendations failed');
      }
    } catch (e) {
      print('[AIApiService] Recommendations error: $e');
      rethrow;
    }
  }

  /// Compare properties
  /// POST /api/ai/compare
  Future<Map<String, dynamic>> compareProperties({
    required List<int> unitIds,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/compare'),
            headers: _headers,
            body: jsonEncode({
              'unit_ids': unitIds,
              'language': _language,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Compare failed');
      }
    } catch (e) {
      print('[AIApiService] Compare error: $e');
      rethrow;
    }
  }

  /// Ask question about a property
  /// POST /api/ai/ask
  Future<Map<String, dynamic>> askQuestion({
    required String question,
    int? unitId,
    int? compoundId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/ask'),
            headers: _headers,
            body: jsonEncode({
              'question': question,
              'unit_id': unitId,
              'compound_id': compoundId,
              'language': _language,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Ask failed');
      }
    } catch (e) {
      print('[AIApiService] Ask error: $e');
      rethrow;
    }
  }

  /// Generate property description
  /// POST /api/ai/generate-description
  Future<Map<String, dynamic>> generateDescription({
    int? unitId,
    Map<String, dynamic>? propertyData,
    String style = 'formal',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/generate-description'),
            headers: _headers,
            body: jsonEncode({
              'unit_id': unitId,
              'property_data': propertyData,
              'style': style,
              'language': _language,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Generate description failed');
      }
    } catch (e) {
      print('[AIApiService] Generate description error: $e');
      rethrow;
    }
  }

  /// Get market insights
  /// POST /api/ai/market-insights
  Future<Map<String, dynamic>> getMarketInsights({
    int? compoundId,
    String? location,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/market-insights'),
            headers: _headers,
            body: jsonEncode({
              'compound_id': compoundId,
              'location': location,
              'language': _language,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Market insights failed');
      }
    } catch (e) {
      print('[AIApiService] Market insights error: $e');
      rethrow;
    }
  }

  /// Sales Assistant - Quick responses for phone calls
  /// POST /api/ai/sales-assistant
  Future<Map<String, dynamic>> salesAssistant({
    required String message,
    String? language,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/sales-assistant'),
            headers: _headers,
            body: jsonEncode({
              'message': message,
              'language': language ?? _language,
            }),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Sales assistant failed');
      }
    } catch (e) {
      print('[AIApiService] Sales assistant error: $e');
      rethrow;
    }
  }

  /// Get conversation history from server
  /// GET /api/ai/conversations/{id}
  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/ai/conversations/$conversationId'),
            headers: _headers,
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Get conversation failed');
      }
    } catch (e) {
      print('[AIApiService] Get conversation error: $e');
      rethrow;
    }
  }

  /// Delete conversation
  /// DELETE /api/ai/conversations/{id}
  Future<void> deleteConversation(String conversationId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/ai/conversations/$conversationId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Delete conversation failed');
      }
    } catch (e) {
      print('[AIApiService] Delete conversation error: $e');
      rethrow;
    }
  }
}
