import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/chat_message.dart';
import '../domain/config.dart';
import '../domain/real_estate_product.dart';

/// Handles communication with Google's Gemini AI
class ChatRemoteDataSource {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

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

  /// System prompt that defines the AI's behavior
  static const String _realEstateSystemPrompt = '''
You are an AI assistant specialized in Egyptian real estate properties.

IMPORTANT RULES:
1. ONLY respond to questions about real estate, properties, housing, or related topics
2. For ANY other topic, respond: "I can only help with real estate and property questions. Please ask me about properties, units, or compounds."
3. When describing properties, ALWAYS respond with valid JSON in this EXACT format:

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
      // Send message to Gemini
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
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
              .map((p) => RealEstateProduct.fromJson(p as Map<String, dynamic>))
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
          final product = RealEstateProduct.fromJson(jsonData);

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
