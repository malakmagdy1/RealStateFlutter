import 'dart:convert';
import 'package:http/http.dart' as http;


/// 🚀 UNIFIED AI DATA SOURCE
/// Handles all AI communication with Senior Broker personality
class UnifiedAIDataSource {
  final String _apiKey;
  final String _baseUrl;
  final List<Map<String, String>> _conversationHistory = [];
  
  UnifiedAIDataSource({
    String? apiKey,
    String? baseUrl,
  })  : _apiKey = apiKey ?? const String.fromEnvironment('OPENAI_API_KEY'),
        _baseUrl = baseUrl ?? 'https://api.openai.com/v1/chat/completions';

  /// Send message to AI with Senior Broker context
  Future<AIResponse> sendMessage(
    String userMessage, {
    List<Map<String, dynamic>>? availableUnits,
    MessageIntent? intent,
  }) async {
    final currentLang = LanguageService.currentLanguage;
    
    // Detect intent if not provided
    final detectedIntent = intent ?? _detectIntent(userMessage);
    
    // Build the conversation
    final messages = _buildMessages(
      userMessage: userMessage,
      language: currentLang,
      intent: detectedIntent,
      availableUnits: availableUnits,
    );

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview', // or gpt-3.5-turbo
          'messages': messages,
          'temperature': 0.8, // More creative/natural responses
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'] as String;
        
        // Add to conversation history
        _conversationHistory.add({'role': 'user', 'content': userMessage});
        _conversationHistory.add({'role': 'assistant', 'content': aiMessage});
        
        // Parse response for any units mentioned
        final extractedUnits = _extractUnitsFromResponse(aiMessage, availableUnits);
        
        return AIResponse(
          textResponse: aiMessage,
          type: extractedUnits != null && extractedUnits.isNotEmpty 
              ? AIResponseType.properties 
              : AIResponseType.salesAdvice,
          units: extractedUnits,
        );
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[UnifiedAIDataSource] ❌ Error: $e');
      rethrow;
    }
  }

  /// Send comparison request
  Future<AIResponse> sendComparison({
    required List<Map<String, dynamic>> items,
    String? additionalContext,
  }) async {
    final currentLang = LanguageService.currentLanguage;
    final comparisonPrompt = _buildComparisonPrompt(items, currentLang, additionalContext);
    
    return sendMessage(
      comparisonPrompt,
      intent: MessageIntent.comparison,
    );
  }

  /// Build messages array for API call
  List<Map<String, String>> _buildMessages({
    required String userMessage,
    required String language,
    required MessageIntent intent,
    List<Map<String, dynamic>>? availableUnits,
  }) {
    final messages = <Map<String, String>>[];
    
    // 1. System prompt (Senior Broker personality)
    messages.add({
      'role': 'system',
      'content': SeniorBrokerPrompt.getSystemPrompt(language: language),
    });
    
    // 2. Add context based on intent
    if (intent == MessageIntent.unitRecommendation && availableUnits != null) {
      messages.add({
        'role': 'system',
        'content': _buildUnitsContext(availableUnits, language),
      });
    }
    
    // 3. Add scenario-specific guidance if applicable
    final scenarioPrompt = _getScenarioPromptIfApplicable(userMessage, language);
    if (scenarioPrompt != null) {
      messages.add({
        'role': 'system',
        'content': scenarioPrompt,
      });
    }
    
    // 4. Add conversation history (last 10 messages for context)
    final historyToInclude = _conversationHistory.length > 10
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;
    
    for (final msg in historyToInclude) {
      messages.add(msg);
    }
    
    // 5. Add current user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });
    
    return messages;
  }

  /// Detect user intent from message
  MessageIntent _detectIntent(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Comparison keywords
    if (lowerMessage.contains('قارن') ||
        lowerMessage.contains('مقارنة') ||
        lowerMessage.contains('compare') ||
        lowerMessage.contains('versus') ||
        lowerMessage.contains('vs') ||
        lowerMessage.contains('الفرق بين') ||
        lowerMessage.contains('أيهما أفضل') ||
        lowerMessage.contains('which is better')) {
      return MessageIntent.comparison;
    }
    
    // Unit search keywords
    if (lowerMessage.contains('عايز') ||
        lowerMessage.contains('ابحث') ||
        lowerMessage.contains('وحدة') ||
        lowerMessage.contains('شقة') ||
        lowerMessage.contains('فيلا') ||
        lowerMessage.contains('بنتهاوس') ||
        lowerMessage.contains('looking for') ||
        lowerMessage.contains('search') ||
        lowerMessage.contains('find') ||
        lowerMessage.contains('apartment') ||
        lowerMessage.contains('villa') ||
        lowerMessage.contains('penthouse')) {
      return MessageIntent.unitRecommendation;
    }
    
    // Client handling keywords
    if (lowerMessage.contains('عميل') ||
        lowerMessage.contains('زبون') ||
        lowerMessage.contains('client') ||
        lowerMessage.contains('customer') ||
        lowerMessage.contains('اتعامل') ||
        lowerMessage.contains('handle') ||
        lowerMessage.contains('deal with')) {
      return MessageIntent.salesAdvice;
    }
    
    // Negotiation keywords
    if (lowerMessage.contains('تفاوض') ||
        lowerMessage.contains('سعر') ||
        lowerMessage.contains('خصم') ||
        lowerMessage.contains('negotiate') ||
        lowerMessage.contains('price') ||
        lowerMessage.contains('discount')) {
      return MessageIntent.negotiation;
    }
    
    // Investment keywords
    if (lowerMessage.contains('استثمار') ||
        lowerMessage.contains('عائد') ||
        lowerMessage.contains('investment') ||
        lowerMessage.contains('roi') ||
        lowerMessage.contains('return')) {
      return MessageIntent.investment;
    }
    
    return MessageIntent.general;
  }

  /// Get scenario prompt if message matches a known scenario
  String? _getScenarioPromptIfApplicable(String message, String language) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('عميل جديد') ||
        lowerMessage.contains('new client') ||
        lowerMessage.contains('أول مرة')) {
      return SeniorBrokerPrompt.getScenarioPrompt(
        scenario: BrokerScenario.newClientApproach,
        language: language,
      );
    }
    
    if (lowerMessage.contains('اعتراض') ||
        lowerMessage.contains('objection') ||
        lowerMessage.contains('بيرفض') ||
        lowerMessage.contains('مش مقتنع')) {
      return SeniorBrokerPrompt.getScenarioPrompt(
        scenario: BrokerScenario.handlingObjections,
        language: language,
      );
    }
    
    if (lowerMessage.contains('أقفل') ||
        lowerMessage.contains('close') ||
        lowerMessage.contains('إتمام') ||
        lowerMessage.contains('finish deal')) {
      return SeniorBrokerPrompt.getScenarioPrompt(
        scenario: BrokerScenario.closingDeal,
        language: language,
      );
    }
    
    return null;
  }

  /// Build context string for available units
  String _buildUnitsContext(List<Map<String, dynamic>> units, String language) {
    final isArabic = language == 'ar';
    final buffer = StringBuffer();
    
    if (isArabic) {
      buffer.writeln('📋 الوحدات المتاحة في قاعدة البيانات:');
    } else {
      buffer.writeln('📋 Available Units in Database:');
    }
    
    for (int i = 0; i < units.length && i < 20; i++) {
      final unit = units[i];
      buffer.writeln('${i + 1}. ${unit['name'] ?? 'Unit ${i + 1}'}');
      if (unit['price'] != null) buffer.writeln('   💰 ${unit['price']} EGP');
      if (unit['area'] != null) buffer.writeln('   📐 ${unit['area']} m²');
      if (unit['bedrooms'] != null) buffer.writeln('   🛏️ ${unit['bedrooms']} bedrooms');
      if (unit['location'] != null) buffer.writeln('   📍 ${unit['location']}');
      if (unit['compound_name'] != null) buffer.writeln('   🏘️ ${unit['compound_name']}');
      buffer.writeln();
    }
    
    if (isArabic) {
      buffer.writeln('استخدم هذه البيانات لتقديم توصيات مخصصة للعميل.');
    } else {
      buffer.writeln('Use this data to provide personalized recommendations.');
    }
    
    return buffer.toString();
  }

  /// Build comparison prompt
  String _buildComparisonPrompt(
    List<Map<String, dynamic>> items,
    String language,
    String? additionalContext,
  ) {
    final isArabic = language == 'ar';
    final buffer = StringBuffer();
    
    if (isArabic) {
      buffer.writeln('🎯 طلب مقارنة بين ${items.length} عقارات:');
      buffer.writeln();
      buffer.writeln('⚠️ مهم: قدم تحليل مفصل ورأيك المهني - لا ترد بـ JSON!');
      buffer.writeln();
    } else {
      buffer.writeln('🎯 Comparison Request for ${items.length} properties:');
      buffer.writeln();
      buffer.writeln('⚠️ Important: Provide detailed analysis and your professional opinion - NO JSON!');
      buffer.writeln();
    }
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('━━━━ ${isArabic ? "الخيار" : "Option"} ${i + 1} ━━━━');
      buffer.writeln('${isArabic ? "الاسم" : "Name"}: ${item['name'] ?? 'N/A'}');
      
      item.forEach((key, value) {
        if (key != 'name' && value != null) {
          buffer.writeln('$key: $value');
        }
      });
      buffer.writeln();
    }
    
    if (additionalContext != null) {
      buffer.writeln(additionalContext);
    }
    
    if (isArabic) {
      buffer.writeln();
      buffer.writeln('📋 المطلوب:');
      buffer.writeln('١. قارن الأسعار وسعر المتر');
      buffer.writeln('٢. قارن المواصفات والمميزات');
      buffer.writeln('٣. قارن المواقع والمناطق');
      buffer.writeln('٤. اذكر مزايا وعيوب كل خيار');
      buffer.writeln('٥. أعطِ توصيتك النهائية: أيهما أفضل ولماذا؟');
      buffer.writeln('٦. لمن يناسب كل خيار؟');
    } else {
      buffer.writeln();
      buffer.writeln('📋 Required:');
      buffer.writeln('1. Compare prices and price per sqm');
      buffer.writeln('2. Compare specifications and features');
      buffer.writeln('3. Compare locations and areas');
      buffer.writeln('4. List pros and cons of each option');
      buffer.writeln('5. Give your final recommendation: which is better and why?');
      buffer.writeln('6. Who is each option best suited for?');
    }
    
    return buffer.toString();
  }

  /// Extract units mentioned in AI response
  List<Map<String, dynamic>>? _extractUnitsFromResponse(
    String response,
    List<Map<String, dynamic>>? availableUnits,
  ) {
    if (availableUnits == null || availableUnits.isEmpty) return null;
    
    final mentionedUnits = <Map<String, dynamic>>[];
    
    for (final unit in availableUnits) {
      final unitName = unit['name']?.toString().toLowerCase() ?? '';
      if (response.toLowerCase().contains(unitName) && unitName.isNotEmpty) {
        mentionedUnits.add(unit);
      }
    }
    
    return mentionedUnits.isEmpty ? null : mentionedUnits;
  }

  /// Reset conversation history
  void resetChat() {
    _conversationHistory.clear();
    print('[UnifiedAIDataSource] ✅ Conversation history cleared');
  }

  /// Get conversation history
  List<Map<String, String>> get conversationHistory => List.from(_conversationHistory);
}

/// AI Response model
class AIResponse {
  final String? textResponse;
  final AIResponseType type;
  final List<Map<String, dynamic>>? units;
  
  AIResponse({
    this.textResponse,
    required this.type,
    this.units,
  });
}

/// AI Response types
enum AIResponseType {
  properties,
  salesAdvice,
}

/// Message intent types
enum MessageIntent {
  comparison,
  unitRecommendation,
  salesAdvice,
  negotiation,
  investment,
  general,
}
