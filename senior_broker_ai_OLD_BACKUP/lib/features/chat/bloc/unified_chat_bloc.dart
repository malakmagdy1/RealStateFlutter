import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/unified_chat_history_service.dart';
import '../../data/models/comparison_item.dart';
import '../../../sales_assistant/data/unified_ai_data_source.dart';
import 'unified_chat_event.dart';
import 'unified_chat_state.dart';
import 'package:real/core/locale/language_service.dart';

/// 🚀 ENHANCED UNIFIED CHAT BLOC
/// Senior Broker AI - يجمع كل الخبرات العقارية في مكان واحد
/// 
/// Features:
/// 1. 💬 Sales Advice - نصائح التعامل مع العملاء
/// 2. 🏠 Unit Recommendations - توصيات من قاعدة البيانات
/// 3. ⚖️ Property Comparison - مقارنة الوحدات
/// 4. 🗣️ Bilingual Support - عربي وإنجليزي
class UnifiedChatBloc extends Bloc<UnifiedChatEvent, UnifiedChatState> {
  final UnifiedAIDataSource _dataSource;
  final UnifiedChatHistoryService _historyService;
  
  // Cached database units for recommendations
  List<Map<String, dynamic>>? _cachedUnits;

  UnifiedChatBloc({
    UnifiedAIDataSource? dataSource,
    UnifiedChatHistoryService? historyService,
  })  : _dataSource = dataSource ?? UnifiedAIDataSource(),
        _historyService = historyService ?? UnifiedChatHistoryService(),
        super(const ChatInitial()) {
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<SendComparisonEvent>(_onSendComparison);
    on<ClearChatHistoryEvent>(_onClearChatHistory);
    on<LoadAvailableUnitsEvent>(_onLoadAvailableUnits);
    on<AskForAdviceEvent>(_onAskForAdvice);
  }

  /// Load chat history from local storage
  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    emit(const ChatHistoryLoading());

    try {
      final messages = await _historyService.loadUnifiedChatHistory();
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(
        message: _getLocalizedError('load_history', e),
      ));
    }
  }

  /// Load available units from backend for recommendations
  Future<void> _onLoadAvailableUnits(
    LoadAvailableUnitsEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    _cachedUnits = event.units;
    print('[UnifiedChatBloc] ✅ Loaded ${event.units.length} units for recommendations');
  }

  /// Main message handler
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    final currentLang = LanguageService.currentLanguage;
    print('[UnifiedChatBloc] 📨 Processing: "${event.message}" (lang: $currentLang)');

    final currentMessages = _getCurrentMessages();

    // Add user message
    final userMessage = UnifiedChatMessage(
      id: _generateId(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...currentMessages, userMessage];
    emit(ChatLoaded(messages: updatedMessages, isLoading: true));

    try {
      // Send to AI with available units context
      final aiResponse = await _dataSource.sendMessage(
        event.message,
        availableUnits: _cachedUnits,
      );

      print('[UnifiedChatBloc] ✅ Response type: ${aiResponse.type}');

      // Create AI message
      final aiMessage = UnifiedChatMessage(
        id: _generateId(),
        content: aiResponse.textResponse ?? _getDefaultResponse(aiResponse.type),
        isUser: false,
        timestamp: DateTime.now(),
        units: aiResponse.units,
        responseType: aiResponse.type,
      );

      final finalMessages = [...updatedMessages, aiMessage];
      await _historyService.saveUnifiedChatHistory(finalMessages);
      emit(ChatLoaded(messages: finalMessages, isLoading: false));

    } catch (e) {
      print('[UnifiedChatBloc] ❌ Error: $e');
      _handleError(e, updatedMessages, emit);
    }
  }

  /// Handle comparison requests
  Future<void> _onSendComparison(
    SendComparisonEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    if (event.items.isEmpty) return;

    print('[UnifiedChatBloc] 📊 Comparing ${event.items.length} items');

    final currentMessages = _getCurrentMessages();
    final currentLang = LanguageService.currentLanguage;

    // Build user-friendly comparison message
    final comparisonSummary = _buildComparisonSummary(event.items, currentLang);

    final userMessage = UnifiedChatMessage(
      id: _generateId(),
      content: comparisonSummary,
      isUser: true,
      timestamp: DateTime.now(),
      comparisonItems: event.items,
    );

    final updatedMessages = [...currentMessages, userMessage];
    emit(ChatLoaded(messages: updatedMessages, isLoading: true));

    try {
      // Convert ComparisonItem to Map for API
      final itemsAsMap = event.items.map((item) => {
        'name': item.name,
        'type': item.type,
        ...item.data,
      }).toList();

      final aiResponse = await _dataSource.sendComparison(
        items: itemsAsMap,
        additionalContext: event.additionalContext,
      );

      final aiMessage = UnifiedChatMessage(
        id: _generateId(),
        content: aiResponse.textResponse ?? _getComparisonDefault(currentLang),
        isUser: false,
        timestamp: DateTime.now(),
        responseType: AIResponseType.salesAdvice, // Comparisons are advice
      );

      final finalMessages = [...updatedMessages, aiMessage];
      await _historyService.saveUnifiedChatHistory(finalMessages);
      emit(ChatLoaded(messages: finalMessages, isLoading: false));

    } catch (e) {
      print('[UnifiedChatBloc] ❌ Comparison error: $e');
      _handleError(e, updatedMessages, emit);
    }
  }

  /// Quick advice requests (predefined scenarios)
  Future<void> _onAskForAdvice(
    AskForAdviceEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    final currentLang = LanguageService.currentLanguage;
    final isArabic = currentLang == 'ar';

    // Map advice type to natural question
    final adviceQuestions = {
      AdviceType.newClient: isArabic 
          ? 'إزاي أتعامل مع عميل جديد لأول مرة؟'
          : 'How do I approach a new client for the first time?',
      AdviceType.handleObjection: isArabic
          ? 'العميل بيقول السعر غالي، أعمل إيه؟'
          : 'The client says the price is too high, what should I do?',
      AdviceType.closeDeal: isArabic
          ? 'إزاي أقفل الصفقة مع عميل متردد؟'
          : 'How do I close the deal with a hesitant client?',
      AdviceType.investment: isArabic
          ? 'عميل عايز يستثمر، إيه النصيحة؟'
          : 'A client wants to invest, what advice should I give?',
      AdviceType.negotiation: isArabic
          ? 'إزاي أتفاوض على السعر صح؟'
          : 'How do I negotiate the price correctly?',
      AdviceType.followUp: isArabic
          ? 'إزاي أتابع مع عميل بعد الزيارة؟'
          : 'How do I follow up with a client after a visit?',
    };

    final question = adviceQuestions[event.adviceType] ?? '';
    
    if (question.isNotEmpty) {
      add(SendMessageEvent(message: question));
    }
  }

  /// Clear chat history
  Future<void> _onClearChatHistory(
    ClearChatHistoryEvent event,
    Emitter<UnifiedChatState> emit,
  ) async {
    try {
      await _historyService.clearUnifiedChatHistory();
      _dataSource.resetChat();
      emit(const ChatLoaded(messages: []));
      print('[UnifiedChatBloc] ✅ History cleared');
    } catch (e) {
      emit(ChatError(
        message: _getLocalizedError('clear_history', e),
        previousMessages: const [],
      ));
    }
  }

  // ============ HELPER METHODS ============

  List<UnifiedChatMessage> _getCurrentMessages() {
    final currentState = state;
    if (currentState is ChatLoaded) return currentState.messages;
    if (currentState is ChatError) return currentState.previousMessages;
    return [];
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  String _buildComparisonSummary(List<ComparisonItem> items, String lang) {
    final isArabic = lang == 'ar';
    final itemNames = items.map((i) => i.name).join(isArabic ? ' و ' : ' and ');
    
    return isArabic
        ? '🔍 أريد مقارنة بين: $itemNames'
        : '🔍 I want to compare: $itemNames';
  }

  String _getDefaultResponse(AIResponseType type) {
    final isArabic = LanguageService.currentLanguage == 'ar';
    switch (type) {
      case AIResponseType.properties:
        return isArabic ? 'لقيت عدة عقارات مناسبة:' : 'Found suitable properties:';
      case AIResponseType.salesAdvice:
        return isArabic ? 'إليك نصيحتي:' : 'Here\'s my advice:';
    }
  }

  String _getComparisonDefault(String lang) {
    return lang == 'ar' 
        ? 'خليني أحللك المقارنة دي...'
        : 'Let me analyze this comparison...';
  }

  void _handleError(
    dynamic error,
    List<UnifiedChatMessage> currentMessages,
    Emitter<UnifiedChatState> emit,
  ) {
    final errorMessage = UnifiedChatMessage(
      id: _generateId(),
      content: _getLocalizedError('general', error),
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );

    emit(ChatLoaded(
      messages: [...currentMessages, errorMessage],
      isLoading: false,
    ));
  }

  String _getLocalizedError(String type, dynamic error) {
    final isArabic = LanguageService.currentLanguage == 'ar';
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('api key') || errorStr.contains('invalid_api_key')) {
      return isArabic 
          ? '⚠️ مشكلة في الـ API Key. تواصل مع الدعم.'
          : '⚠️ API Key issue. Contact support.';
    }
    
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return isArabic
          ? '📶 مشكلة في الاتصال. تأكد من الإنترنت.'
          : '📶 Connection issue. Check your internet.';
    }
    
    if (errorStr.contains('quota') || errorStr.contains('rate limit')) {
      return isArabic
          ? '⏳ حاول بعد شوية. الخدمة مشغولة.'
          : '⏳ Try again later. Service is busy.';
    }

    switch (type) {
      case 'load_history':
        return isArabic 
            ? '❌ مشكلة في تحميل المحادثات السابقة.'
            : '❌ Failed to load chat history.';
      case 'clear_history':
        return isArabic
            ? '❌ مشكلة في مسح المحادثات.'
            : '❌ Failed to clear history.';
      default:
        return isArabic
            ? '❌ حدث خطأ. حاول مرة أخرى.'
            : '❌ An error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}

/// Advice types for quick access
enum AdviceType {
  newClient,
  handleObjection,
  closeDeal,
  investment,
  negotiation,
  followUp,
}
