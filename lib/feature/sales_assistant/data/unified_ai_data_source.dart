import '../../ai_chat/data/ai_api_service.dart';
import '../../compound/data/models/unit_model.dart';
import 'package:real/core/locale/language_service.dart';
import 'package:real/core/security/secure_storage.dart';

/// Unified AI Data Source that uses the backend API
/// Supports chat, property search, sales advice, and comparisons
class UnifiedAIDataSource {
  final AIApiService _apiService = AIApiService();
  String? _currentConversationId;
  bool _isInitialized = false;

  UnifiedAIDataSource() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final token = await SecureStorage.getToken();
      final language = LanguageService.currentLanguage;

      await _apiService.initialize(token: token, language: language);
      _isInitialized = true;
      print('[UnifiedAIDataSource] Initialized successfully');
    } catch (e) {
      print('[UnifiedAIDataSource] Initialization error: $e');
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initialize();
    }
  }

  /// Send message and get intelligent response
  Future<AIResponse> sendMessage(String userMessage) async {
    await ensureInitialized();

    print('[UnifiedAIDataSource] Sending message: "$userMessage"');

    try {
      final response = await _apiService.chat(
        message: userMessage,
        conversationId: _currentConversationId,
        language: LanguageService.currentLanguage,
      );

      print('[UnifiedAIDataSource] Raw API response keys: ${response.keys.toList()}');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        print('[UnifiedAIDataSource] Data keys: ${data.keys.toList()}');

        if (data['conversation_id'] != null) {
          _currentConversationId = data['conversation_id'].toString();
        }

        final aiMessage = data['message'] as String? ?? '';
        final intent = data['intent'] as String?;
        final totalFound = data['total_found'] as int?;
        print('[UnifiedAIDataSource] Received response - intent: $intent, totalFound: $totalFound');
        print('[UnifiedAIDataSource] AI Message: ${aiMessage.substring(0, aiMessage.length > 100 ? 100 : aiMessage.length)}...');

        List<Unit>? units;

        // Support both 'units' (new format) and 'properties' (old format)
        final unitsList = data['units'] ?? data['properties'];
        print('[UnifiedAIDataSource] unitsList type: ${unitsList.runtimeType}, is List: ${unitsList is List}, is null: ${unitsList == null}');
        if (unitsList != null && unitsList is List) {
          print('[UnifiedAIDataSource] unitsList length: ${unitsList.length}');
          units = [];
          for (int i = 0; i < unitsList.length; i++) {
            final property = unitsList[i];
            print('[UnifiedAIDataSource] Parsing unit $i: ${property.runtimeType}');
            if (property is Map<String, dynamic>) {
              print('[UnifiedAIDataSource] Unit $i keys: ${property.keys.toList()}');
              final unit = _parsePropertyToUnit(property);
              if (unit != null) {
                units.add(unit);
                print('[UnifiedAIDataSource] Unit $i parsed successfully: id=${unit.id}');
              } else {
                print('[UnifiedAIDataSource] Unit $i parsing returned null');
              }
            } else {
              print('[UnifiedAIDataSource] Unit $i is not a Map: ${property.runtimeType}');
            }
          }
          print('[UnifiedAIDataSource] Parsed ${units.length} units from response');
        } else {
          print('[UnifiedAIDataSource] No units/properties found in response');
        }

        final hasUnits = units != null && units.isNotEmpty;

        // Determine response type based on intent or presence of units
        AIResponseType responseType;
        if (intent == 'recommend' || intent == 'search' || hasUnits) {
          responseType = AIResponseType.properties;
        } else {
          responseType = AIResponseType.salesAdvice;
        }

        return AIResponse(
          type: responseType,
          textResponse: aiMessage,
          units: units,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to get response');
      }
    } catch (e) {
      print('[UnifiedAIDataSource] Error: $e');
      rethrow;
    }
  }

  Unit? _parsePropertyToUnit(Map<String, dynamic> property) {
    try {
      print('[UnifiedAIDataSource] _parsePropertyToUnit starting...');
      print('[UnifiedAIDataSource] Property data: $property');

      // Handle images - support both 'images' array and single 'image' field
      List<String> images = [];
      if (property['images'] is List) {
        images = (property['images'] as List).map((e) => e.toString()).toList();
      } else if (property['image'] != null && property['image'].toString().isNotEmpty) {
        images = [property['image'].toString()];
      }
      print('[UnifiedAIDataSource] Images parsed: ${images.length}');

      // Parse price - support 'price', 'normal_price', 'price_formatted'
      final price = property['price']?.toString() ??
          property['normal_price']?.toString() ??
          '0';
      print('[UnifiedAIDataSource] Price parsed: $price');

      // Parse unit name - support 'name', 'unit_name', 'unit_number'
      final unitName = property['name'] ??
          property['unit_name'] ??
          property['unit_number'] ??
          'Unit';
      print('[UnifiedAIDataSource] Unit name parsed: $unitName');

      // Parse status - provide default if not available
      final status = property['status']?.toString() ?? 'available';
      print('[UnifiedAIDataSource] Status parsed: $status');

      print('[UnifiedAIDataSource] Parsing unit: id=${property['id']}, name=$unitName, price=$price, status=$status');

      return Unit(
        id: property['id']?.toString() ?? '',
        compoundId: property['compound_id']?.toString() ?? '',
        unitType: property['unit_type']?.toString() ?? property['type']?.toString() ?? 'Unit',
        area: property['area']?.toString() ?? property['built_up_area']?.toString() ?? '0',
        price: price,
        bedrooms: property['bedrooms']?.toString() ?? '0',
        bathrooms: property['bathrooms']?.toString() ?? '0',
        floor: property['floor']?.toString() ?? property['floor_number']?.toString() ?? '0',
        status: status,
        unitNumber: unitName,
        deliveryDate: property['delivery_date'],
        view: property['view'],
        finishing: property['finishing'] ?? property['finishing_type'],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        images: images,
        buildingName: property['building_name'],
        gardenArea: property['garden_area']?.toString(),
        roofArea: property['roof_area']?.toString(),
        usageType: property['usage_type'],
        salesNumber: property['sales_number']?.toString(),
        companyLogo: property['company_logo'],
        companyName: property['company_name'],
        companyId: property['company_id']?.toString(),
        compoundName: property['compound_name'] ?? property['location'],
        compoundLocation: property['location'],
        code: property['code'],
        originalPrice: property['original_price']?.toString(),
        discountedPrice: property['discounted_price']?.toString(),
        discountPercentage: property['discount_percentage']?.toString(),
        available: property['available'] == true || property['available'] == 1,
        isSold: property['is_sold'] == true || property['is_sold'] == 1,
        totalPrice: property['total_price']?.toString(),
        normalPrice: property['normal_price']?.toString() ?? price,
        builtUpArea: property['built_up_area']?.toString() ?? property['area']?.toString(),
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
    } catch (e, stackTrace) {
      print('[UnifiedAIDataSource] Error parsing property: $e');
      print('[UnifiedAIDataSource] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get property recommendations
  Future<List<Unit>> getRecommendations({
    Map<String, dynamic>? preferences,
    int limit = 10,
  }) async {
    await ensureInitialized();

    try {
      final response = await _apiService.getRecommendations(
        preferences: preferences,
        limit: limit,
      );

      if (response['success'] == true && response['data'] != null) {
        final units = <Unit>[];
        final data = response['data'];

        // Support both 'units' (new format), 'recommendations' and 'properties' (old format)
        final unitsList = data['units'] ?? data['recommendations'] ?? data['properties'];
        if (unitsList != null && unitsList is List) {
          for (var item in unitsList) {
            final unit = _parsePropertyToUnit(item as Map<String, dynamic>);
            if (unit != null) units.add(unit);
          }
          print('[UnifiedAIDataSource] Parsed ${units.length} recommendations');
        }

        return units;
      }

      return [];
    } catch (e) {
      print('[UnifiedAIDataSource] Recommendations error: $e');
      rethrow;
    }
  }

  /// Compare multiple properties
  Future<String> compareProperties(List<int> unitIds) async {
    await ensureInitialized();

    try {
      final response = await _apiService.compareProperties(unitIds: unitIds);

      if (response['success'] == true && response['data'] != null) {
        return response['data']['comparison'] ?? response['data']['message'] ?? '';
      }

      return 'Could not compare properties';
    } catch (e) {
      print('[UnifiedAIDataSource] Compare error: $e');
      rethrow;
    }
  }

  /// Ask question about a property
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
      print('[UnifiedAIDataSource] Ask question error: $e');
      rethrow;
    }
  }

  /// Generate property description
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
      print('[UnifiedAIDataSource] Generate description error: $e');
      rethrow;
    }
  }

  /// Get market insights
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
      print('[UnifiedAIDataSource] Market insights error: $e');
      rethrow;
    }
  }

  /// Reset chat session
  void resetChat() {
    _currentConversationId = null;
    print('[UnifiedAIDataSource] Chat session reset');
  }

  /// Get current conversation ID
  String? get currentConversationId => _currentConversationId;
}

/// Response type enum
enum AIResponseType {
  properties,
  salesAdvice,
}

/// AI Response model
class AIResponse {
  final AIResponseType type;
  final String? textResponse;
  final List<Unit>? units;

  AIResponse({
    required this.type,
    this.textResponse,
    this.units,
  });
}
