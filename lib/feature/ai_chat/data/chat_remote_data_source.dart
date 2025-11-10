import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/chat_message.dart';
import '../domain/config.dart';
import '../domain/real_estate_product.dart';
import '../../search/data/repositories/search_repository.dart';
import '../../search/data/models/search_result_model.dart';
import '../../compound/data/models/unit_model.dart';

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

  /// Convert Unit model to RealEstateProduct
  RealEstateProduct _convertUnitToProduct(Unit unit) {
    return RealEstateProduct(
      type: 'unit',
      id: int.tryParse(unit.id),
      name: unit.unitNumber?.isNotEmpty == true ? unit.unitNumber! : unit.usageType ?? 'Unit',
      location: unit.compoundName ?? 'Unknown Location',
      propertyType: unit.usageType ?? unit.unitType ?? 'Unit',
      price: _formatPrice(unit),
      area: unit.area,
      bedrooms: unit.bedrooms,
      bathrooms: unit.bathrooms,
      features: _extractFeatures(unit),
      description: '${unit.usageType ?? 'Unit'} in ${unit.compoundName ?? 'compound'}',
      originalUnit: unit, // Pass the original Unit object
    );
  }

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

  List<String> _extractFeatures(Unit unit) {
    List<String> features = [];
    if (unit.status != null && unit.status!.toLowerCase() == 'available') {
      features.add('Available');
    }
    if (unit.deliveryDate != null && unit.deliveryDate!.isNotEmpty) {
      features.add('Delivery: ${unit.deliveryDate}');
    }
    if (unit.companyName != null && unit.companyName!.isNotEmpty) {
      features.add('By ${unit.companyName}');
    }
    return features;
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
3. For ANY other topic, respond: "I can only help with real estate and property questions. Please ask me about properties, units, or compounds."
4. When user asks about properties, I will provide you with real property data from the database
5. Analyze the real data and recommend the best matches based on user requirements
6. When describing properties, ALWAYS respond with valid JSON in this EXACT format:

For SINGLE property:
{
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
- Always respond with ONLY the JSON object, no additional text
- Ensure all JSON is valid and properly formatted
- Use realistic Egyptian prices
- Include relevant features based on property type
- Keep descriptions concise and appealing
''';

  /// Send a message to the AI and get a response
  Future<ChatMessage> sendMessage(String userMessage) async {
    try {
      // Fetch real properties from database based on user query
      List<Unit> realUnits = [];
      try {
        print('[AI CHAT] Fetching real properties from database...');
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

        print('[AI CHAT] Found ${realUnits.length} units from database');
      } catch (e) {
        print('[AI CHAT] Error fetching units: $e');
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

        enhancedMessage = '''
User Query: $userMessage

Available Properties from Database:
${jsonEncode(unitsData)}

Please analyze these REAL properties and recommend the best matches for the user's requirements.
Return only the properties from this list that match the user's needs.
''';
      }

      // Send message to Gemini with real data context
      final response = await _chatSession.sendMessage(
        Content.text(enhancedMessage),
      );

      final responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Try to parse as JSON for property data
      try {
        // Clean the response - remove markdown code blocks if present
        String cleanedResponse = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final jsonData = jsonDecode(cleanedResponse) as Map<String, dynamic>;

        // Check if it's a list of properties
        if (jsonData.containsKey('properties')) {
          final propertiesList = (jsonData['properties'] as List)
              .map((p) {
                final productJson = p as Map<String, dynamic>;
                // Try to match with real unit by ID
                Unit? matchedUnit;
                if (productJson['id'] != null && realUnits.isNotEmpty) {
                  final productId = productJson['id'].toString();
                  matchedUnit = realUnits.firstWhere(
                    (unit) => unit.id == productId,
                    orElse: () => realUnits.first,
                  );
                }
                // Convert matched unit or use JSON data
                return matchedUnit != null
                    ? _convertUnitToProduct(matchedUnit)
                    : RealEstateProduct.fromJson(productJson);
              })
              .toList();

          // Return message with first property but include full list for rendering
          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: _generateMultiplePropertiesMessage(propertiesList),
            isUser: false,
            timestamp: DateTime.now(),
            product: propertiesList.isNotEmpty ? propertiesList.first : null,
          );
        } else {
          // Single property
          Unit? matchedUnit;
          if (jsonData['id'] != null && realUnits.isNotEmpty) {
            final productId = jsonData['id'].toString();
            matchedUnit = realUnits.firstWhere(
              (unit) => unit.id == productId,
              orElse: () => realUnits.first,
            );
          }

          final product = matchedUnit != null
              ? _convertUnitToProduct(matchedUnit)
              : RealEstateProduct.fromJson(jsonData);

          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: _generatePropertyMessage(product),
            isUser: false,
            timestamp: DateTime.now(),
            product: product,
          );
        }
      } catch (e) {
        // Not JSON, return as regular text message
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// Generate a user-friendly message from product data
  String _generatePropertyMessage(RealEstateProduct product) {
    final buffer = StringBuffer();
    buffer.writeln('Here\'s a ${product.propertyType} I found for you:');
    buffer.writeln();
    buffer.writeln('📍 Location: ${product.location}');
    buffer.writeln('💰 Price: ${product.price} EGP');
    if (product.area != null) buffer.writeln('📏 Area: ${product.area} sqm');
    if (product.bedrooms != null) buffer.writeln('🛏️ Bedrooms: ${product.bedrooms}');
    if (product.bathrooms != null) buffer.writeln('🚿 Bathrooms: ${product.bathrooms}');

    if (product.features.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('✨ Features:');
      for (var feature in product.features.take(3)) {
        buffer.writeln('  • $feature');
      }
    }

    return buffer.toString();
  }

  /// Generate message for multiple properties
  String _generateMultiplePropertiesMessage(List<RealEstateProduct> properties) {
    if (properties.isEmpty) {
      return 'I couldn\'t find any properties matching your criteria.';
    }

    final buffer = StringBuffer();
    buffer.writeln('I found ${properties.length} ${properties.length == 1 ? 'property' : 'properties'} for you:');
    buffer.writeln();

    for (int i = 0; i < properties.length; i++) {
      final product = properties[i];
      buffer.writeln('${i + 1}');
      buffer.writeln('${product.name}');
      buffer.writeln('📍 ${product.location} • 💰 ${product.price} EGP');
      if (i < properties.length - 1) buffer.writeln();
    }

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
