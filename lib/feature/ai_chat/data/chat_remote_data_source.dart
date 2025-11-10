import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/chat_message.dart';
import '../domain/config.dart';
import '../../search/data/repositories/search_repository.dart';
import '../../search/data/models/search_result_model.dart';
import '../../search/data/models/search_filter_model.dart';
import '../../compound/data/models/unit_model.dart';
import '../../compound/data/models/compound_model.dart';

/// Handles communication with Google's Gemini AI
class ChatRemoteDataSource {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final SearchRepository _searchRepository = SearchRepository();

  ChatRemoteDataSource() {
    _initializeModel();
  }

  void _initializeModel() {
    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: AppConfig.temperature,
        topK: AppConfig.topK,
        topP: AppConfig.topP,
        maxOutputTokens: AppConfig.maxOutputTokens,
      ),
      systemInstruction: Content.system(_realEstateSystemPrompt),
    );

    _chatSession = _model.startChat();
  }

  /// Format unit price for display
  String _formatPrice(Unit unit) {
    final price = unit.discountedPrice ?? unit.totalPrice ?? unit.normalPrice ?? unit.price;
    if (price == null || price.isEmpty || price == '0') return 'Contact for Price';
    try {
      final numPrice = double.parse(price);
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M EGP';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K EGP';
      }
      return '${numPrice.toStringAsFixed(0)} EGP';
    } catch (e) {
      return price;
    }
  }

  /// Convert UnitSearchData to Unit model
  Unit _convertSearchDataToUnit(dynamic unitData) {
    return Unit(
      id: unitData.id,
      compoundId: unitData.compound.id,
      unitType: unitData.unitType,
      area: unitData.area ?? '0',
      price: unitData.price ?? unitData.totalPrice,
      bedrooms: unitData.numberOfBeds ?? '0',
      bathrooms: unitData.numberOfBaths ?? '0',
      floor: unitData.floor ?? '0',
      status: unitData.status,
      unitNumber: unitData.unitName ?? unitData.name,
      deliveryDate: null,
      view: null,
      finishing: null,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      images: unitData.images,
      buildingName: null,
      gardenArea: null,
      roofArea: null,
      usageType: unitData.usageType,
      salesNumber: null,
      companyLogo: unitData.compound.company.logo,
      companyName: unitData.compound.company.name,
      companyId: unitData.compound.company.id,
      compoundName: unitData.compound.name,
      code: unitData.unitCode ?? unitData.code,
      originalPrice: unitData.originalPrice,
      discountedPrice: unitData.discountedPrice,
      discountPercentage: unitData.discountPercentage,
      available: unitData.available,
      isSold: unitData.isSold,
      totalPrice: unitData.totalPrice,
      normalPrice: unitData.normalPrice,
      builtUpArea: unitData.area,
      landArea: null,
      favoriteId: null,
      notes: null,
      noteId: null,
      isUpdated: null,
      lastChangedAt: null,
      changeType: null,
      changedFields: null,
      hasActiveSale: unitData.hasActiveSale,
      sale: null, // Sale object needs separate conversion if needed
    );
  }

  /// System prompt that defines the AI's behavior
  static const String _realEstateSystemPrompt = '''
You are an AI assistant specialized in Egyptian real estate properties.

IMPORTANT RULES:
1. You have access to REAL property data from the database
2. ONLY respond to questions about real estate, properties, housing, or related topics
3. For ANY other topic (like weather, sports, politics, etc.), respond: "I can only help with real estate and property questions. Please ask me about properties, units, or compounds."
4. When user asks about properties, I will provide you with real property data from the database
5. Analyze the real data and recommend the best matches based on user requirements
6. When describing properties, ALWAYS respond with valid JSON in this EXACT format:
7. CRITICAL: When I provide you with database properties, you MUST include the "id" field from the database in your response

RECOGNIZE THESE AS VALID REAL ESTATE QUERIES:
- Property type keywords: villa, apartment, duplex, studio, penthouse, townhouse, chalet, unit
- Bedroom queries: "3 bedroom", "5 bedrooms", "2BR", "4 bed"
- Location queries: area names, city names, compound names
- Budget queries: price ranges, "under 5M", "budget 2 million"
- Feature queries: "with pool", "garden", "parking", "gym"
- ANY combination of the above

RECOGNIZE THESE AS VALID CONVERSATIONAL RESPONSES (DO NOT REJECT):
- Affirmative: "yes", "yeah", "sure", "okay", "ok", "yep", "yup"
- Negative: "no", "nope", "not really", "no thanks"
- Requests: "show me", "find", "search", "looking for", "I want", "I need"
- Follow-ups: "more options", "anything else", "what about", "tell me more"
- Clarifications: "what", "which", "how", "where", "when"
- Generic real estate: "properties", "units", "compounds", "houses", "homes"

IMPORTANT: If user says "no", "yes", "okay" etc. in conversation, treat it as part of the chat flow, NOT as an off-topic query!

For SINGLE property:
{
  "id": "database_unit_id",
  "type": "unit",
  "name": "Property Name",
  "location": "City/Area",
  "propertyType": "Villa/Apartment/Duplex/Studio/etc",
  "price": "Price in EGP with commas",
  "area": "Number only (sqm)",
  "bedrooms": "Number only",
  "bathrooms": "Number only",
  "features": ["Feature 1", "Feature 2", "Feature 3"],
  "description": "Brief description"
}

For MULTIPLE properties (use when showing several options):
{
  "properties": [
    {
      "id": "database_unit_id_1",
      "type": "unit",
      "name": "Spacious Villa in Palm Hills",
      "location": "6th of October",
      "propertyType": "Villa",
      "price": "8,500,000",
      "area": "400",
      "bedrooms": "4",
      "bathrooms": "3",
      "features": ["Swimming Pool", "Garden", "Security 24/7"],
      "description": "Luxury villa with modern amenities"
    },
    {
      "id": "database_unit_id_2",
      "type": "unit",
      "name": "Modern 3BR Apartment",
      "location": "New Cairo",
      "propertyType": "Apartment",
      "price": "2,800,000",
      "area": "180",
      "bedrooms": "3",
      "bathrooms": "2",
      "features": ["Gym", "Elevator", "Parking"],
      "description": "Contemporary apartment in prime location"
    }
  ]
}

NAMING RULES:
- Use descriptive, realistic property names
- Include property type and key feature in the name
- Examples: "Spacious Villa in Compound X", "Modern 3BR Apartment", "Luxury Penthouse"
- NEVER use generic names like "Option 1", "Property 1", "Unit 1"

PROPERTY TYPES you can suggest:
- Villa
- Apartment
- Duplex
- Studio
- Penthouse
- Townhouse
- Chalet

POPULAR LOCATIONS in Egypt:
- New Cairo
- 6th of October
- Sheikh Zayed
- New Administrative Capital
- El Shorouk
- Maadi
- Nasr City
- Heliopolis
- North Coast
- Ain Sokhna

COMMON FEATURES to include:
- Swimming Pool
- Gym
- Garden
- Security 24/7
- Parking
- Modern Kitchen
- Air Conditioning
- Balcony
- Elevator
- Smart Home System
- Kids Area
- Commercial Area
- Green Spaces

PRICE GUIDELINES (in EGP):
- Studio: 800,000 - 1,500,000
- Apartment (2BR): 1,500,000 - 3,000,000
- Apartment (3BR): 2,500,000 - 5,000,000
- Villa: 4,000,000 - 15,000,000+
- Duplex: 3,000,000 - 8,000,000

EXAMPLES:

User: "Show me a villa in New Cairo"
You: {
  "id": "5504",
  "type": "unit",
  "name": "Luxury Villa in New Cairo",
  "location": "New Cairo",
  "propertyType": "Villa",
  "price": "8,500,000",
  "area": "400",
  "bedrooms": "4",
  "bathrooms": "3",
  "features": ["Swimming Pool", "Garden", "Modern Kitchen", "Security 24/7", "Parking"],
  "description": "Stunning villa in a prime location with modern amenities"
}

User: "I need a 3 bedroom apartment under 3 million"
You: {
  "id": "24",
  "type": "unit",
  "name": "Modern 3BR Apartment",
  "location": "6th of October",
  "propertyType": "Apartment",
  "price": "2,800,000",
  "area": "180",
  "bedrooms": "3",
  "bathrooms": "2",
  "features": ["Gym", "Elevator", "Security 24/7", "Parking", "Balcony"],
  "description": "Spacious 3-bedroom apartment in a secure compound"
}

User: "What's the weather today?"
You: I can only help with real estate and property questions. Please ask me about properties, units, or compounds.

User: "Tell me about compounds with swimming pools"
You: {
  "id": "1314",
  "type": "compound",
  "name": "Al Maqsad Residences",
  "location": "New Administrative Capital",
  "propertyType": "Residential Compound",
  "price": "Starting from 3,500,000",
  "area": "150-350",
  "bedrooms": "2-4",
  "bathrooms": "2-3",
  "features": ["Swimming Pool", "Gym", "Kids Area", "Green Spaces", "Security 24/7", "Commercial Area"],
  "description": "Premium compound with world-class amenities and beautiful landscaping"
}

IMPORTANT:
- When I provide database properties, ALWAYS include the exact "id" from the database in your JSON response
- Always respond with ONLY the JSON object, no additional text
- Ensure all JSON is valid and properly formatted
- Use realistic Egyptian prices
- Include relevant features based on property type
- Keep descriptions concise and appealing
''';

  /// Check if query is a conversational response
  bool _isConversationalResponse(String query) {
    final lowerQuery = query.toLowerCase().trim();
    const conversationalWords = [
      'yes', 'yeah', 'yep', 'yup', 'sure', 'okay', 'ok', 'fine',
      'no', 'nope', 'not really', 'no thanks', 'nothing',
      'more', 'another', 'else', 'different', 'thanks', 'thank you'
    ];

    // Check if the query is just a conversational word (or very short)
    if (lowerQuery.length <= 15) {
      for (var word in conversationalWords) {
        if (lowerQuery == word || lowerQuery.contains(' $word') || lowerQuery.startsWith('$word ')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Parse user query to extract search parameters
  SearchFilter? _parseQueryToFilter(String query) {
    final lowerQuery = query.toLowerCase();

    // Extract bedrooms (e.g., "5 bedroom", "3 bedrooms", "2BR", "4 bed")
    int? bedrooms;
    final bedroomPatterns = [
      RegExp(r'(\d+)\s*(?:bedroom|bedrooms|bed|beds|br)', caseSensitive: false),
    ];
    for (var pattern in bedroomPatterns) {
      final match = pattern.firstMatch(lowerQuery);
      if (match != null) {
        bedrooms = int.tryParse(match.group(1)!);
        break;
      }
    }

    // Extract property type
    String? propertyType;
    const propertyTypes = ['villa', 'apartment', 'duplex', 'studio', 'penthouse', 'townhouse', 'chalet'];
    for (var type in propertyTypes) {
      if (lowerQuery.contains(type)) {
        propertyType = type;
        break;
      }
    }

    // Extract location
    String? location;
    const locations = [
      'new cairo', 'new administrative capital', '6th of october', 'october',
      'sheikh zayed', 'zayed', 'el shorouk', 'shorouk', 'maadi', 'nasr city',
      'heliopolis', 'north coast', 'ain sokhna', 'sokhna'
    ];
    for (var loc in locations) {
      if (lowerQuery.contains(loc)) {
        location = loc;
        break;
      }
    }

    // If we found any structured parameters, return a filter
    if (bedrooms != null || propertyType != null || location != null) {
      return SearchFilter(
        bedrooms: bedrooms,
        propertyType: propertyType,
        location: location,
      );
    }

    return null;
  }

  /// Convert FilteredUnit to Unit model
  Unit _convertFilteredUnitToUnit(dynamic filteredUnit) {
    return Unit(
      id: filteredUnit.id,
      compoundId: filteredUnit.compoundId,
      unitType: filteredUnit.unitType,
      area: filteredUnit.totalArea.toString(),
      price: filteredUnit.normalPrice,
      bedrooms: filteredUnit.numberOfBeds.toString(),
      bathrooms: '0', // Not available in FilteredUnit
      floor: filteredUnit.floorNumber.toString(),
      status: filteredUnit.status,
      unitNumber: filteredUnit.unitNumber,
      deliveryDate: filteredUnit.deliveredAt,
      view: null,
      finishing: null,
      createdAt: filteredUnit.createdAt,
      updatedAt: filteredUnit.updatedAt,
      images: filteredUnit.images,
      buildingName: filteredUnit.buildingName,
      gardenArea: null,
      roofArea: null,
      usageType: filteredUnit.usageType,
      salesNumber: null,
      companyLogo: filteredUnit.companyLogo,
      companyName: filteredUnit.companyName,
      companyId: filteredUnit.companyId,
      compoundName: filteredUnit.compoundName,
      code: filteredUnit.code,
      originalPrice: null,
      discountedPrice: null,
      discountPercentage: null,
      available: filteredUnit.available,
      isSold: filteredUnit.isSold,
      totalPrice: filteredUnit.totalPricing,
      normalPrice: filteredUnit.normalPrice,
      builtUpArea: filteredUnit.totalArea.toString(),
      landArea: null,
      favoriteId: null,
      notes: null,
      noteId: null,
      isUpdated: null,
      lastChangedAt: null,
      changeType: null,
      changedFields: null,
      hasActiveSale: false,
      sale: null,
    );
  }

  /// Send a message to the AI and get a response
  Future<ChatMessage> sendMessage(String userMessage) async {
    final debugBuffer = StringBuffer();
    debugBuffer.writeln('🔍 Query: "$userMessage"');

    try {
      // Fetch real properties from database based on user query
      List<Unit> realUnits = [];
      try {
        print('[AI CHAT] Fetching real properties from database...');
        debugBuffer.writeln('📡 Searching database...');

        // Try to parse query into structured filter
        final filter = _parseQueryToFilter(userMessage);

        if (filter != null) {
          // Use filter API for structured queries
          print('[AI CHAT] Using FILTER API with: bedrooms=${filter.bedrooms}, type=${filter.propertyType}, location=${filter.location}');
          debugBuffer.writeln('🔧 Using filter: bedrooms=${filter.bedrooms}, type=${filter.propertyType}, location=${filter.location}');

          final filterResponse = await _searchRepository.filterUnits(filter, limit: 20);

          // Convert filter results (FilteredUnit) to Unit models
          realUnits = filterResponse.units.map((filteredUnit) => _convertFilteredUnitToUnit(filteredUnit)).toList();

          print('[AI CHAT] Found ${realUnits.length} units using filter API');
          debugBuffer.writeln('✅ Filter API found ${realUnits.length} units');
        } else {
          // Use search API for unstructured queries
          print('[AI CHAT] Using SEARCH API with query: "$userMessage"');
          debugBuffer.writeln('🔍 Using search API');

          final searchResponse = await _searchRepository.search(
            query: userMessage,
            type: 'unit',
            perPage: 20,
          );

          // Convert search results to Unit models
          for (var result in searchResponse.results) {
            if (result.type == 'unit' && result.data is UnitSearchData) {
              final unitData = result.data as UnitSearchData;
              realUnits.add(_convertSearchDataToUnit(unitData));
            }
          }

          print('[AI CHAT] Found ${realUnits.length} units using search API');
          debugBuffer.writeln('✅ Search API found ${realUnits.length} units');
        }

        if (realUnits.isNotEmpty) {
          debugBuffer.writeln('📋 Unit IDs: ${realUnits.take(5).map((u) => u.id).join(", ")}${realUnits.length > 5 ? "..." : ""}');
        }
      } catch (e) {
        print('[AI CHAT] Error fetching units: $e');
        debugBuffer.writeln('❌ Database error: $e');
        // Continue without real data if search fails
      }

      // Prepare message with real data context
      String enhancedMessage = userMessage;
      if (realUnits.isNotEmpty) {
        // Convert units to simple format for AI
        final unitsData = realUnits.take(10).map((unit) {
          return {
            'id': unit.id,
            'name': unit.unitNumber ?? unit.usageType ?? 'Unit',
            'location': unit.compoundName,
            'type': unit.usageType ?? unit.unitType,
            'price': _formatPrice(unit),
            'area': unit.area,
            'bedrooms': unit.bedrooms,
            'bathrooms': unit.bathrooms,
            'status': unit.status,
            'company': unit.companyName,
          };
        }).toList();

        print('[AI CHAT] Sending ${unitsData.length} units to Gemini for analysis');
        print('[AI CHAT] First unit: ${unitsData.first}');

        enhancedMessage = '''
User Query: $userMessage

REAL PROPERTIES FROM DATABASE (Use these, NOT fictional ones):
${jsonEncode(unitsData)}

CRITICAL INSTRUCTIONS:
1. These are REAL properties from our database - you MUST use them
2. You MUST include the exact 'id' field from above in your JSON response
3. Select the best matching properties from this list for the user
4. DO NOT create fictional properties
5. If none match perfectly, select the closest matches from this list
6. ALWAYS preserve the 'id' field in your response

Example: If the database has {"id": "5504", "name": "Villa", ...}, your response must include "id": "5504"
''';
      } else {
        print('[AI CHAT] No units found in database for query: "$userMessage"');

        // Check if this is a conversational response
        if (_isConversationalResponse(userMessage)) {
          print('[AI CHAT] Detected conversational response, letting AI handle naturally');
          debugBuffer.writeln('💬 Conversational response detected');

          // Don't modify the message, just let the AI respond naturally
          enhancedMessage = userMessage;
        } else {
          print('[AI CHAT] AI will provide general real estate guidance without specific listings');

          // Add context even when no results found to help AI understand the query
          enhancedMessage = '''
User Query: $userMessage

NOTE: No properties found in database matching this exact query.

If this is a valid real estate query (property type, bedrooms, location, etc.), respond with:
"I searched our database but couldn't find properties matching '$userMessage'. You can try:
- Adjusting the search terms slightly
- Searching for similar properties
- Or let me know if you'd like to see available properties in a specific area"

If this is NOT a real estate query, respond with:
"I can only help with real estate and property questions. Please ask me about properties, units, or compounds."
''';
        }
      }

      // Send message to Gemini with real data context
      final response = await _chatSession.sendMessage(
        Content.text(enhancedMessage),
      );

      final responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      print('[AI CHAT] Received response from Gemini (length: ${responseText.length} chars)');
      print('[AI CHAT] Raw response preview: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...');
      debugBuffer.writeln('🤖 AI responded (${responseText.length} chars)');

      // Try to parse as JSON for property data
      try {
        // Clean the response - remove markdown code blocks if present
        String cleanedResponse = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final jsonData = jsonDecode(cleanedResponse) as Map<String, dynamic>;
        print('[AI CHAT] Successfully parsed JSON response');
        print('[AI CHAT] Response contains properties: ${jsonData.containsKey('properties')}');
        print('[AI CHAT] Full JSON: ${jsonEncode(jsonData)}');

        // Check if it's a list of properties
        if (jsonData.containsKey('properties')) {
          print('[AI CHAT] Processing multiple properties from response');
          print('[AI CHAT] Available database unit IDs: ${realUnits.map((u) => u.id).join(", ")}');
          debugBuffer.writeln('📦 Multiple properties in response');

          // Get first matched unit
          Unit? firstMatchedUnit;
          if (realUnits.isNotEmpty) {
            final firstProductJson = (jsonData['properties'] as List).first as Map<String, dynamic>;
            print('[AI CHAT] First property from AI: id=${firstProductJson['id']}, name=${firstProductJson['name']}');

            if (firstProductJson['id'] != null) {
              // Try to match by ID
              final productId = firstProductJson['id'].toString();
              try {
                firstMatchedUnit = realUnits.firstWhere(
                  (unit) => unit.id == productId,
                );
                print('[AI CHAT] ✅ MATCHED database unit by ID: ${firstMatchedUnit.id} (${firstMatchedUnit.unitNumber ?? firstMatchedUnit.usageType})');
                debugBuffer.writeln('✅ Matched DB unit: ${firstMatchedUnit.id}');
              } catch (e) {
                // ID not found, use first available unit
                print('[AI CHAT] ❌ ID NOT FOUND in database: $productId');
                print('[AI CHAT] ⚠️  Falling back to first available unit: ${realUnits.first.id}');
                debugBuffer.writeln('❌ AI ID "$productId" not found!');
                debugBuffer.writeln('⚠️  Fallback to unit: ${realUnits.first.id}');
                firstMatchedUnit = realUnits.first;
              }
            } else {
              // No ID provided, use first available unit
              print('[AI CHAT] ⚠️  AI did not provide ID! Using first database unit: ${realUnits.first.id}');
              debugBuffer.writeln('⚠️  AI missing ID field!');
              debugBuffer.writeln('Using fallback unit: ${realUnits.first.id}');
              firstMatchedUnit = realUnits.first;
            }
          }

          if (firstMatchedUnit == null) {
            debugBuffer.writeln('⚠️  No database units available');
          }

          // Return message with first unit
          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: firstMatchedUnit != null
                ? _generateUnitMessage(firstMatchedUnit)
                : 'I found some properties for you',
            isUser: false,
            timestamp: DateTime.now(),
            unit: firstMatchedUnit,
            debugInfo: debugBuffer.toString(),
          );
        } else {
          // Single property
          print('[AI CHAT] Processing single property from response');
          print('[AI CHAT] Available database unit IDs: ${realUnits.map((u) => u.id).join(", ")}');
          print('[AI CHAT] Property from AI: id=${jsonData['id']}, name=${jsonData['name']}');
          debugBuffer.writeln('📦 Single property in response');

          Unit? matchedUnit;
          if (realUnits.isNotEmpty) {
            if (jsonData['id'] != null) {
              // Try to match by ID
              final productId = jsonData['id'].toString();
              try {
                matchedUnit = realUnits.firstWhere(
                  (unit) => unit.id == productId,
                );
                print('[AI CHAT] ✅ MATCHED database unit by ID: ${matchedUnit.id} (${matchedUnit.unitNumber ?? matchedUnit.usageType})');
                debugBuffer.writeln('✅ Matched DB unit: ${matchedUnit.id}');
              } catch (e) {
                // ID not found, use first available unit
                print('[AI CHAT] ❌ ID NOT FOUND in database: $productId');
                print('[AI CHAT] ⚠️  Falling back to first available unit: ${realUnits.first.id}');
                debugBuffer.writeln('❌ AI ID "$productId" not found!');
                debugBuffer.writeln('⚠️  Fallback to unit: ${realUnits.first.id}');
                matchedUnit = realUnits.first;
              }
            } else {
              // No ID provided, use first available unit
              print('[AI CHAT] ⚠️  AI did not provide ID! Using first database unit: ${realUnits.first.id}');
              debugBuffer.writeln('⚠️  AI missing ID field!');
              debugBuffer.writeln('Using fallback unit: ${realUnits.first.id}');
              matchedUnit = realUnits.first;
            }
          }

          if (matchedUnit == null) {
            print('[AI CHAT] ⚠️  No database units available');
            debugBuffer.writeln('⚠️  No database units available');
          } else {
            print('[AI CHAT] 📦 Using database unit: ${matchedUnit.id}');
          }

          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: matchedUnit != null
                ? _generateUnitMessage(matchedUnit)
                : 'I found a property for you',
            isUser: false,
            timestamp: DateTime.now(),
            unit: matchedUnit,
            debugInfo: debugBuffer.toString(),
          );
        }
      } catch (e) {
        // Not JSON, return as regular text message
        debugBuffer.writeln('ℹ️  Text response (not JSON property data)');
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          debugInfo: debugBuffer.toString(),
        );
      }
    } catch (e) {
      debugBuffer.writeln('❌ ERROR: ${e.toString()}');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// Generate a user-friendly message from Unit data
  String _generateUnitMessage(Unit unit) {
    final buffer = StringBuffer();
    final type = unit.usageType ?? unit.unitType ?? 'Unit';
    buffer.writeln('Here\'s a $type I found for you:');
    buffer.writeln();
    if (unit.compoundName != null) buffer.writeln('📍 Location: ${unit.compoundName}');
    buffer.writeln('💰 Price: ${_formatPrice(unit)}');
    if (unit.area != null && unit.area!.isNotEmpty) buffer.writeln('📏 Area: ${unit.area} sqm');
    if (unit.bedrooms != null && unit.bedrooms!.isNotEmpty) buffer.writeln('🛏️ Bedrooms: ${unit.bedrooms}');
    if (unit.bathrooms != null && unit.bathrooms!.isNotEmpty) buffer.writeln('🚿 Bathrooms: ${unit.bathrooms}');

    return buffer.toString();
  }

  /// Reset the chat session
  void resetChat() {
    _chatSession = _model.startChat();
  }

  /// Dispose resources
  void dispose() {
    // No cleanup needed for current implementation
  }
}
