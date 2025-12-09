import 'package:shared_preferences/shared_preferences.dart';
import 'package:real/core/security/secure_storage.dart';
import '../domain/chat_message.dart';
import '../../compound/data/models/unit_model.dart';
import 'ai_api_service.dart';

/// Handles communication with the AI backend API
class ChatRemoteDataSource {
  final AIApiService _apiService = AIApiService();
  String? _currentConversationId;
  bool _isInitialized = false;

  ChatRemoteDataSource() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final token = await SecureStorage.getToken();
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('language') ?? 'ar';

      await _apiService.initialize(token: token, language: language);
      _isInitialized = true;
      print('[ChatRemoteDataSource] Initialized successfully');
    } catch (e) {
      print('[ChatRemoteDataSource] Initialization error: $e');
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initialize();
    }
  }

  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  void setLanguage(String language) {
    _apiService.setLanguage(language);
  }

  String? get currentConversationId => _currentConversationId;

  void setConversationId(String? id) {
    _currentConversationId = id;
    print('[ChatRemoteDataSource] Conversation ID set to: $id');
  }

  /// Send a message to the AI and get a response
  Future<ChatMessage> sendMessage(String userMessage) async {
    await ensureInitialized();

    try {
      print('[ChatRemoteDataSource] Sending message to API...');

      final response = await _apiService.chat(
        message: userMessage,
        conversationId: _currentConversationId,
      );

      print('[ChatRemoteDataSource] Response received');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        if (data['conversation_id'] != null) {
          _currentConversationId = data['conversation_id'].toString();
        }

        final aiMessage = data['message'] as String? ?? 'No response';

        Unit? unit;
        try {
          if (data['properties'] != null && data['properties'] is List) {
            final properties = data['properties'] as List;
            if (properties.isNotEmpty) {
              unit = _parsePropertyToUnit(properties.first as Map<String, dynamic>);
            }
          } else if (data['unit'] != null) {
            unit = Unit.fromJson(data['unit'] as Map<String, dynamic>);
          }
        } catch (e) {
          print('[ChatRemoteDataSource] Could not parse unit data: $e');
        }

        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: aiMessage,
          isUser: false,
          timestamp: DateTime.now(),
          unit: unit,
        );
      } else {
        final errorMsg = response['message'] ?? 'Unknown error occurred';
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('[ChatRemoteDataSource] Error: $e');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Unit? _parsePropertyToUnit(Map<String, dynamic> property) {
    try {
      return Unit(
        id: property['id']?.toString() ?? '',
        compoundId: property['compound_id']?.toString() ?? '',
        unitType: property['unit_type'] ?? property['type'],
        area: property['area']?.toString() ?? '0',
        price: property['price']?.toString() ?? '0',
        bedrooms: property['bedrooms']?.toString() ?? '0',
        bathrooms: property['bathrooms']?.toString() ?? '0',
        floor: property['floor']?.toString() ?? '0',
        status: property['status'],
        unitNumber: property['unit_number'] ?? property['name'],
        deliveryDate: property['delivery_date'],
        view: property['view'],
        finishing: property['finishing'],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        images: property['images'] is List
            ? (property['images'] as List).map((e) => e.toString()).toList()
            : [],
        buildingName: property['building_name'],
        gardenArea: property['garden_area']?.toString(),
        roofArea: property['roof_area']?.toString(),
        usageType: property['usage_type'],
        salesNumber: property['sales_number']?.toString(),
        companyLogo: property['company_logo'],
        companyName: property['company_name'],
        companyId: property['company_id']?.toString(),
        compoundName: property['compound_name'] ?? property['location'],
        code: property['code'],
        originalPrice: property['original_price']?.toString(),
        discountedPrice: property['discounted_price']?.toString(),
        discountPercentage: property['discount_percentage']?.toString(),
        available: property['available'] == true || property['available'] == 1,
        isSold: property['is_sold'] == true || property['is_sold'] == 1,
        totalPrice: property['total_price']?.toString(),
        normalPrice: property['normal_price']?.toString(),
        builtUpArea: property['built_up_area']?.toString(),
        landArea: property['land_area']?.toString(),
        favoriteId: null,
        notes: property['notes'],
        noteId: null,
        isUpdated: null,
        lastChangedAt: null,
        changeType: null,
        changedFields: null,
        hasActiveSale: property['has_active_sale'] == true,
        sale: null,
      );
    } catch (e) {
      print('[ChatRemoteDataSource] Error parsing property to unit: $e');
      return null;
    }
  }

  Future<List<Unit>> getRecommendations({
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    int? bedrooms,
    String? unitType,
    String? location,
    int? compoundId,
    int limit = 10,
  }) async {
    await ensureInitialized();

    try {
      final preferences = <String, dynamic>{};
      if (minPrice != null) preferences['min_price'] = minPrice;
      if (maxPrice != null) preferences['max_price'] = maxPrice;
      if (minArea != null) preferences['min_area'] = minArea;
      if (maxArea != null) preferences['max_area'] = maxArea;
      if (bedrooms != null) preferences['bedrooms'] = bedrooms;
      if (unitType != null) preferences['unit_type'] = unitType;
      if (location != null) preferences['location'] = location;
      if (compoundId != null) preferences['compound_id'] = compoundId;

      final response = await _apiService.getRecommendations(
        preferences: preferences,
        limit: limit,
      );

      if (response['success'] == true && response['data'] != null) {
        final units = <Unit>[];
        final data = response['data'];

        if (data['recommendations'] != null && data['recommendations'] is List) {
          for (var item in data['recommendations']) {
            final unit = _parsePropertyToUnit(item as Map<String, dynamic>);
            if (unit != null) units.add(unit);
          }
        }

        return units;
      }

      return [];
    } catch (e) {
      print('[ChatRemoteDataSource] Get recommendations error: $e');
      rethrow;
    }
  }

  Future<String> compareProperties(List<int> unitIds) async {
    await ensureInitialized();

    try {
      final response = await _apiService.compareProperties(unitIds: unitIds);

      if (response['success'] == true && response['data'] != null) {
        return response['data']['comparison'] ?? response['data']['message'] ?? '';
      }

      return 'Could not compare properties';
    } catch (e) {
      print('[ChatRemoteDataSource] Compare properties error: $e');
      rethrow;
    }
  }

  Future<String> askQuestion({
    required String question,
    int? unitId,
    int? compoundId,
  }) async {
    await ensureInitialized();

    try {
      final response = await _apiService.askQuestion(
        question: question,
        unitId: unitId,
        compoundId: compoundId,
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data']['answer'] ?? response['data']['message'] ?? '';
      }

      return 'Could not get answer';
    } catch (e) {
      print('[ChatRemoteDataSource] Ask question error: $e');
      rethrow;
    }
  }

  Future<String> generateDescription({
    int? unitId,
    Map<String, dynamic>? propertyData,
    String style = 'formal',
  }) async {
    await ensureInitialized();

    try {
      final response = await _apiService.generateDescription(
        unitId: unitId,
        propertyData: propertyData,
        style: style,
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data']['description'] ?? '';
      }

      return 'Could not generate description';
    } catch (e) {
      print('[ChatRemoteDataSource] Generate description error: $e');
      rethrow;
    }
  }

  Future<String> getMarketInsights({
    int? compoundId,
    String? location,
  }) async {
    await ensureInitialized();

    try {
      final response = await _apiService.getMarketInsights(
        compoundId: compoundId,
        location: location,
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data']['insights'] ?? response['data']['message'] ?? '';
      }

      return 'Could not get market insights';
    } catch (e) {
      print('[ChatRemoteDataSource] Get market insights error: $e');
      rethrow;
    }
  }

  void resetChat() {
    _currentConversationId = null;
    print('[ChatRemoteDataSource] Chat session reset');
  }

  void dispose() {}
}
