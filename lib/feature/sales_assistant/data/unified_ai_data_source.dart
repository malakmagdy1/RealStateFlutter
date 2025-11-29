import 'package:google_generative_ai/google_generative_ai.dart';
import '../../ai_chat/domain/config.dart';
import '../../search/data/repositories/search_repository.dart';
import '../../search/data/models/search_filter_model.dart';
import '../../search/data/models/search_result_model.dart';
import '../../compound/data/models/unit_model.dart';
import '../../ai_chat/core/senior_broker_prompt.dart';
import 'package:real/core/locale/language_service.dart';
import 'dart:convert';

/// Unified AI Data Source that combines:
/// 1. Property Search (from ChatRemoteDataSource)
/// 2. Sales Advice (from SalesAssistantRemoteDataSource)
class UnifiedAIDataSource {
  GenerativeModel? _model;  // Changed from late final to nullable
  ChatSession? _chatSession;  // Changed from late to nullable
  final SearchRepository _searchRepository = SearchRepository();

  UnifiedAIDataSource() {
    _initializeModel();
  }

  void _initializeModel() {
    // Get "Abu Khalid" personality based on current language
    final currentLang = LanguageService.currentLanguage;
    final seniorBrokerPersonality = SeniorBrokerPrompt.getSystemPrompt(language: currentLang);

    // Combine Abu Khalid personality with technical instructions
    final fullSystemPrompt = '$seniorBrokerPersonality\n\n$_technicalInstructions';

    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8, // Higher for more natural conversation
        topK: AppConfig.topK,
        topP: AppConfig.topP,
        maxOutputTokens: 1200, // More for detailed mentor advice
      ),
      systemInstruction: Content.system(fullSystemPrompt),
    );

    _chatSession = _model!.startChat();
  }

  /// Technical instructions for property search and data formatting
  static const String _technicalInstructions = '''
You are a sales advisor for Egyptian real estate.

⚠️ CRITICAL LANGUAGE & FORMAT RULES - MUST FOLLOW:
- DEFAULT LANGUAGE: Arabic (unless user explicitly writes in English)
- If user asks in Arabic → Respond ONLY in Arabic (NO English words!)
- If user asks in English → Respond ONLY in English (NO Arabic words!)
- NEVER mix languages in the same response
- ALWAYS use bullet points (•) for lists - NOT paragraphs
- Use short, clear sentences

RESPONSE STYLE:
✓ Good (Brief, bullet points):
"• المساحة: 180 متر
• السعر: 2.5 مليون جنيه
• 3 غرف نوم، 2 حمام"

✗ Bad (Long paragraph):
"This is a beautiful apartment with a total area of 180 square meters. It is priced at 2.5 million Egyptian pounds and features three bedrooms and two bathrooms."

Examples:
User: "اعطني نصائح"
You: "• ركز على المميزات الفريدة للعقار
• اذكر القرب من الخدمات
• اعرض خطة تقسيط مرنة"

User: "كيف أقنع عميل؟"
You: "• استمع لاحتياجاته أولاً
• اربط العقار بهذه الاحتياجات
• اعرض قصص نجاح عملاء سابقين"

User: "احسب عمولة 3% على 2 مليون"
You: "العمولة = 60,000 جنيه"

═══════════════════════════════════════════════
🏘️ FOR PROPERTY SEARCH (when I give you data):
═══════════════════════════════════════════════

When user asks about PROPERTIES (searching, finding, looking for):
- "عايز فيلا"
- "شقة 3 غرف"
- "وحدات في New Cairo"
- "show me apartments"

→ I will provide you with REAL properties from the database
→ You MUST recommend 2-3 options from the data I give you
→ Respond with JSON format (see format below)

═══════════════════════════════════════════════
💼 CAPABILITY 2: SALES ADVICE & CALCULATIONS
═══════════════════════════════════════════════

When user asks about SALES ADVICE (no property search needed):
- "كيف أقنع عميل"
- "احسب عمولة"
- "رد على اعتراض"
- "اعطني نصائح"
- "نصيحة"
- "how to close a deal"
- "give me advice"
- "tips"

→ Give SHORT, DIRECT advice (2-4 sentences)
→ Ready-to-use phrases
→ Quick calculations
→ NO property search needed
→ NO JSON format
→ PLAIN TEXT response only

═══════════════════════════════════════════════
🔀 CAPABILITY 3: MIXED QUERIES
═══════════════════════════════════════════════

When user asks BOTH (property + advice):
- "عندي فيلا 5 مليون، ازاي أبيعها؟"
- "I have an apartment to sell, help me"

→ I will provide similar properties from database
→ You recommend 2-3 options + give selling advice

═══════════════════════════════════════════════

**RESPONSE FORMATS:**

FOR PROPERTY SEARCH (always show 2-3 options):
{
  "type": "properties",
  "properties": [
    {
      "id": "database_unit_id_1",
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
  ],
  "advice": "Optional: quick selling tip if relevant"
}

FOR SALES ADVICE ONLY (no JSON, just text):
"قل له: 'أفهم قلقك من السعر. خليني أوريك المميزات اللي هتخلي السعر ده معقول جداً.' ثم اذكر 3 مميزات بسرعة."

**IMPORTANT:**
- ALWAYS include the exact "id" from database in your JSON response
- Show 2-3 property options, NOT just one
- Keep descriptions concise
- Use realistic Egyptian property names and prices
''';

  /// Check if query is about property search
  bool _isPropertySearchQuery(String query) {
    final lowerQuery = query.toLowerCase();

    // Property search keywords
    const searchKeywords = [
      // Arabic
      'عايز', 'محتاج', 'ابحث', 'دور', 'شقة', 'فيلا', 'وحدة', 'وحدات',
      'عقار', 'عقارات', 'كمبوند', 'غرفة', 'غرف', 'حمام',
      // English
      'want', 'need', 'looking for', 'find', 'search', 'apartment', 'villa',
      'unit', 'property', 'compound', 'bedroom', 'bathroom', 'show me',
    ];

    return searchKeywords.any((keyword) => lowerQuery.contains(keyword));
  }

  /// Parse query to extract search parameters
  SearchFilter? _parseQueryToFilter(String query) {
    final lowerQuery = query.toLowerCase();

    // Extract bedrooms
    int? bedrooms;
    final bedroomPatterns = [
      RegExp(r'(\d+)\s*(?:غرف|غرفة|bedroom|bedrooms|bed|beds|br)', caseSensitive: false),
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
    const propertyTypes = ['villa', 'apartment', 'duplex', 'studio', 'penthouse', 'townhouse', 'chalet', 'فيلا', 'شقة'];
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
      'heliopolis', 'north coast', 'ain sokhna', 'sokhna',
      'القاهرة الجديدة', 'العاصمة الإدارية', 'أكتوبر', 'الشيخ زايد', 'الشروق'
    ];
    for (var loc in locations) {
      if (lowerQuery.contains(loc)) {
        location = loc;
        break;
      }
    }

    if (bedrooms != null || propertyType != null || location != null) {
      return SearchFilter(
        bedrooms: bedrooms,
        propertyType: propertyType,
        location: location,
      );
    }

    return null;
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

  /// Convert search data to Unit model
  Unit _convertSearchDataToUnit(UnitSearchData unitData) {
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
      sale: null,
    );
  }

  /// Send message and get intelligent response
  Future<AIResponse> sendMessage(String userMessage) async {
    print('[UNIFIED AI] 📥 Received query: "$userMessage"');

    try {
      // Re-initialize the model for each message to avoid session errors
      // This fixes the "غير صحيح تأكد من api key" error after first message
      _initializeModel();

      final isPropertySearch = _isPropertySearchQuery(userMessage);
      print('[UNIFIED AI] 🔍 Query type: ${isPropertySearch ? "PROPERTY SEARCH" : "SALES ADVICE"}');

      String enhancedMessage = userMessage;
      List<Unit> realUnits = [];

      // If it's a property search, fetch real data from database
      if (isPropertySearch) {
        print('[UNIFIED AI] 📡 Fetching properties from database...');

        try {
          final filter = _parseQueryToFilter(userMessage);

          if (filter != null) {
            print('[UNIFIED AI] 🔧 Using FILTER API: bedrooms=${filter.bedrooms}, type=${filter.propertyType}');
            final filterResponse = await _searchRepository.filterUnits(filter, limit: 20);

            for (var filteredUnit in filterResponse.units) {
              realUnits.add(Unit(
                id: filteredUnit.id,
                compoundId: filteredUnit.compoundId,
                unitType: filteredUnit.unitType ?? '',
                area: filteredUnit.totalArea.toString(),
                price: filteredUnit.normalPrice ?? '',
                bedrooms: filteredUnit.numberOfBeds.toString(),
                bathrooms: '0',
                floor: filteredUnit.floorNumber.toString(),
                status: filteredUnit.status ?? '',
                unitNumber: filteredUnit.unitNumber ?? '',
                deliveryDate: filteredUnit.deliveredAt,
                view: null,
                finishing: null,
                createdAt: filteredUnit.createdAt ?? '',
                updatedAt: filteredUnit.updatedAt ?? '',
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
                code: filteredUnit.code ?? '',
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
              ));
            }
          } else {
            print('[UNIFIED AI] 🔍 Using SEARCH API');
            final searchResponse = await _searchRepository.search(
              query: userMessage,
              type: 'unit',
              perPage: 20,
            );

            for (var result in searchResponse.results) {
              if (result.type == 'unit' && result.data is UnitSearchData) {
                realUnits.add(_convertSearchDataToUnit(result.data));
              }
            }
          }

          print('[UNIFIED AI] ✅ Found ${realUnits.length} units');

          if (realUnits.isNotEmpty) {
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

REAL PROPERTIES FROM DATABASE (recommend 2-3 best options):
${jsonEncode(unitsData)}

CRITICAL:
1. Recommend 2-3 properties from above (NOT just one)
2. Include exact "id" from database in your JSON response
3. Use the property search JSON format
''';
          }
        } catch (e) {
          print('[UNIFIED AI] ❌ Database error: $e');
        }
      }

      // Send to Gemini
      print('[UNIFIED AI] 🤖 Sending to Gemini...');
      print('[UNIFIED AI] 📤 Enhanced message: ${enhancedMessage.substring(0, enhancedMessage.length > 200 ? 200 : enhancedMessage.length)}...');

      final response = await _chatSession!.sendMessage(Content.text(enhancedMessage));
      final responseText = response.text?.trim() ?? '';

      print('[UNIFIED AI] 📨 Gemini response length: ${responseText.length} chars');
      print('[UNIFIED AI] 📨 Response preview: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}');

      // Try to parse as JSON (property response)
      try {
        String cleanedResponse = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final jsonData = jsonDecode(cleanedResponse) as Map<String, dynamic>;

        if (jsonData['type'] == 'properties' && jsonData.containsKey('properties')) {
          final propertiesList = jsonData['properties'] as List;
          print('[UNIFIED AI] 🏘️ Property response with ${propertiesList.length} options');

          List<Unit> matchedUnits = [];
          for (var propertyJson in propertiesList) {
            final productId = propertyJson['id']?.toString();
            if (productId != null && realUnits.isNotEmpty) {
              try {
                final matchedUnit = realUnits.firstWhere((unit) => unit.id == productId);
                matchedUnits.add(matchedUnit);
                print('[UNIFIED AI] ✅ Matched unit: $productId');
              } catch (e) {
                print('[UNIFIED AI] ⚠️ Unit ID not found: $productId, using fallback');
                if (realUnits.isNotEmpty) {
                  matchedUnits.add(realUnits[matchedUnits.length % realUnits.length]);
                }
              }
            }
          }

          return AIResponse(
            type: AIResponseType.properties,
            textResponse: jsonData['advice']?.toString(),
            units: matchedUnits.take(3).toList(), // Max 3 units
          );
        }
      } catch (e) {
        print('[UNIFIED AI] ℹ️ Not JSON property response, treating as sales advice');
      }

      // Sales advice response (plain text)
      print('[UNIFIED AI] 💼 Sales advice response');
      return AIResponse(
        type: AIResponseType.salesAdvice,
        textResponse: responseText,
      );

    } catch (e) {
      print('[UNIFIED AI] ❌ ERROR: $e');
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// Reset chat session
  void resetChat() {
    _chatSession = _model!.startChat();
    print('[UNIFIED AI] 🔄 Chat session reset');
  }
}

/// Response type enum
enum AIResponseType {
  properties,     // Property search results
  salesAdvice,    // Sales advice only
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
